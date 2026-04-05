extends Node

# --- VARIABLES GLOBALES DU SERVEUR ---
var server := TCPServer.new()
var port = 10000
var clients : Array[StreamPeerTCP] = []

# TA FILE D'ATTENTE EST ICI
var request_queue : Array = [] 
const MAX_REQUESTS_PER_FRAME = 10 

var active_sessions : Dictionary = {}

func _ready():
	print("Démarrage du Game Server sur le port ", port, "...")
	var err = server.listen(port)
	if err == OK:
		print("Serveur en écoute ! En attente de connexions du client Godot...")
	else:
		print("Erreur lors du démarrage du serveur : ", err)

func _process(_delta):
	receive_and_queue_requests()
	process_queue()

func receive_and_queue_requests():
	if server.is_connection_available():
		var new_client = server.take_connection()
		clients.append(new_client)
		print("Nouveau client connecté depuis l'IP : ", new_client.get_connected_host())

	for i in range(clients.size() - 1, -1, -1):
		var client = clients[i]
		client.poll()
		
		if client.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			var bytes = client.get_available_bytes()
			if bytes > 0:
				var data_array = client.get_data(bytes)
				if data_array[0] == OK:
					var request_str = data_array[1].get_string_from_utf8()
					var messages = request_str.split("\n", false) 
					
					for msg in messages:
						var parsed_data = JSON.parse_string(msg)
						if typeof(parsed_data) == TYPE_DICTIONARY and parsed_data.has("action"):
							request_queue.append({
								"client": client,
								"data": parsed_data
							})
							print("[FILE] -> Requête '", parsed_data["action"], "' ajoutée. (En attente : ", request_queue.size(), ")")
							
		elif client.get_status() == StreamPeerTCP.STATUS_NONE or client.get_status() == StreamPeerTCP.STATUS_ERROR:
			print("Un client s'est déconnecté.")
			clients.remove_at(i)
			
func process_queue():
	var count = 0
	while request_queue.size() > 0 and count < MAX_REQUESTS_PER_FRAME:
		var task = request_queue.pop_front()
		var client = task["client"]
		var data = task["data"]
		
		print("<- [TRAITEMENT] Dépilage de l'action : ", data["action"])
		route_request(client, data)
		count += 1

func route_request(client: StreamPeerTCP, data: Dictionary):
	if not data.has("action"):
		send_to_client(client, {"status": "error", "message": "Requête invalide, action manquante."})
		return
		
	var action = data["action"]
	
	# Le routeur est maintenant propre et sans doublons
	match action:
		"register":
			handler_register(client, data)
		"historic": # J'ai utilisé 'historic' selon ton code précédent
			handler_historic(client, data)
		_:
			send_to_client(client, {"status": "error", "message": "Action non reconnue."})


## ====================================================
## 1. LES HANDLERS (Préparation des données)
## ====================================================

func handler_register(client: StreamPeerTCP, data: Dictionary):
	var payload = {
		"nickname": data.get("nickname", ""),
		"password": data.get("password", ""),
		"email": data.get("email", ""),
		"avatar_url": data.get("avatar_url", "")
	}
	# Appel de notre fonction factorisée !
	send_to_flask_api("register", "/register", payload, client)

func handler_historic(client: StreamPeerTCP, data: Dictionary):
	var payload = {
		"game_id": data.get("game_id", ""),
		"turn_number": data.get("turn_number", ""),
		"action_type": data.get("action_type", ""),
		"dice_result": data.get("dice_result", ""),
		"amount_exchanged": data.get("amount_exchanged", ""),
		"player_id": data.get("player_id", ""),
		"guest_id": data.get("guest_id", ""),
		"card_id": data.get("card_id", ""),
		"monument_id": data.get("monument_id", "")
	}
	# Appel de notre fonction factorisée !
	send_to_flask_api("historic", "/history/insert", payload, client)


## ====================================================
## 2. L'API FLASK FACTORISÉE (Le "Moteur" HTTP)
## ====================================================

# Fonction unique pour envoyer des requêtes à Flask
func send_to_flask_api(action_name: String, endpoint: String, payload: Dictionary, client: StreamPeerTCP):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	# On passe "action_name" à la fonction de réponse pour qu'elle sache à quelle action elle répond !
	http_request.request_completed.connect(_on_flask_response.bind(client, http_request, action_name))
	
	var url = "http://192.168.100.125:5000" + endpoint
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(payload)
	
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)


# Fonction unique pour recevoir TOUTES les réponses de Flask
func _on_flask_response(result, response_code, headers, body, client: StreamPeerTCP, http_node: HTTPRequest, action_name: String):
	http_node.queue_free() # Nettoyage
	
	if response_code == 0 or response_code >= 500:
		send_to_client(client, {"action_reply": action_name, "status": "error", "message": "Erreur serveur BDD."})
		return
		
	var flask_response = JSON.parse_string(body.get_string_from_utf8())
	
	# On construit la réponse de manière générique en utilisant "action_name"
	var reponse_client = {
		"action_reply": action_name, 
		"status": flask_response.get("status", "error"),
		"message": flask_response.get("message", "Erreur inconnue.")
	}
	
	# S'il y a des données additionnelles renvoyées par Flask, on les transmet au client
	if flask_response.has("data"):
		reponse_client["data"] = flask_response["data"]
	
	send_to_client(client, reponse_client)


## ====================================================
## 3. ENVOI AU CLIENT GODOT
## ====================================================

func send_to_client(client: StreamPeerTCP, data: Dictionary):
	if client.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		var json_string = JSON.stringify(data) + "\n"
		client.put_data(json_string.to_utf8_buffer())
		print("-> Réponse envoyée au client pour : ", data.get("action_reply", "inconnu"))
