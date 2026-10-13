extends Node

# --- VARIABLES GLOBALES DU SERVEUR ---
var server := TCPServer.new()
var port = 10000
var clients : Array[StreamPeerTCP] = []

# TA FILE D'ATTENTE EST ICI
var request_queue : Array = [] 
const MAX_REQUESTS_PER_FRAME = 10 

var active_sessions : Dictionary = {}

func on_client_login_success(client_socket, player_id, access_token := "", refresh_token := "", expires_in := 0):
	active_sessions[client_socket] = {
		"player_id": player_id,
		"access_token": access_token,
		"refresh_token": refresh_token,
		"expires_at": Time.get_unix_time_from_system() + expires_in
	}
	print("Joueur ", player_id, " lié à cette connexion avec session.")
	
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
			active_sessions.erase(client)
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
	
	match action:
		"register":
			handler_register(client, data)
			
		"historic": 
			handler_historic(client, data)
		"authentification" : 
			handler_authentification(client,data)
		"guest_player":
			handler_guest_player(client,data)
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
	var raw_player_id = data.get("player_id", -1)
	var raw_guest_id = data.get("guest_id", -1)
	
	var final_player_id = null if raw_player_id == -1 else raw_player_id
	var final_guest_id = null if raw_guest_id == -1 else raw_guest_id
		
	var payload = {
		"game_id": data.get("game_id", ""),
		"turn_number": data.get("turn_number", ""),
		"action_type": data.get("action_type", ""),
		"dice_result": data.get("dice_result", ""),
		"amount_exchanged": data.get("amount_exchanged", ""),
		"player_id": final_player_id,
		"guest_id": final_guest_id,
		"card_id": data.get("card_id", ""),
		"monument_id": data.get("monument_id", "")
		
		
			
	}
	# Appel de notre fonction factorisée !
	send_to_flask_api("historic", "/history/insert", payload, client, true)


func handler_authentification(client :StreamPeerTCP, data : Dictionary) : 
	var payload = {
		"email" : data.get("identifiant",""),
		"password" : data.get("mot_de_passe")
	}

	send_to_flask_api("authentification","/login",payload,client)
	
func handler_guest_player(client : StreamPeerTCP,data : Dictionary) : 
	
	var payload = {
		"nickname" : data.get("nickname",""),
	}

	send_to_flask_api("guest_player","/guest/register",payload,client)
## ====================================================
## 2. L'API FLASK FACTORISÉE (Le "Moteur" HTTP)
## ====================================================

# Fonction unique pour envoyer des requêtes à Flask
func send_to_flask_api(action_name: String, endpoint: String, payload: Dictionary, client: StreamPeerTCP, requires_auth := false):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	http_request.request_completed.connect(_on_flask_response.bind(client, http_request, action_name))
	
	var url = "http://127.0.0.1:5000" + endpoint
	var headers = ["Content-Type: application/json"]
	
	if requires_auth:
		var token = get_client_token(client)
		if token == "":
			http_request.queue_free()
			send_to_client(client, {
				"action_reply": action_name,
				"status": "error",
				"message": "Authentification requise ou session expirée."
			})
			return
		
		headers.append("Authorization: Bearer " + token)
		print("TOKEN UTILISE -> ", token)
		print("HEADERS -> ", headers)
	
	var body = JSON.stringify(payload)
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	print("APPEL FLASK -> ", url)
	print("BODY -> ", body)
	

# Fonction unique pour recevoir TOUTES les réponses de Flask
func _on_flask_response(result, response_code, headers, body, client: StreamPeerTCP, http_node: HTTPRequest, action_name: String):
	http_node.queue_free()
	print("DEBUG FLASK result = ", result)
	print("DEBUG FLASK response_code = ", response_code)
	print("DEBUG FLASK body = ", body.get_string_from_utf8())
	if response_code == 0 or response_code >= 500:
		send_to_client(client, {"action_reply": action_name, "status": "error", "message": "Erreur serveur BDD."})
		return
		
	var flask_response = JSON.parse_string(body.get_string_from_utf8())
	if typeof(flask_response) != TYPE_DICTIONARY:
		send_to_client(client, {"action_reply": action_name, "status": "error", "message": "Réponse Flask invalide."})
		return
	
	var data_block = flask_response.get("data", {})
	
	if action_name == "authentification" and flask_response.get("status") == "success":
		var player_id = flask_response.get("player_id", data_block.get("player_id", null))
		var access_token = flask_response.get("access_token", data_block.get("access_token", ""))
		var refresh_token = flask_response.get("refresh_token", data_block.get("refresh_token", ""))
		var expires_in = int(flask_response.get("expires_in", data_block.get("expires_in", 0)))

		if player_id != null:
			on_client_login_success(client, player_id, access_token, refresh_token, expires_in)
	
	var reponse_client = {
		"action_reply": action_name,
		"status": flask_response.get("status", "error"),
		"message": flask_response.get("message", "Erreur inconnue.")
	}
	
	if flask_response.has("data"):
		reponse_client["data"] = flask_response["data"]
		
	if flask_response.has("player_id"):
		reponse_client["player_id"] = flask_response["player_id"]
	elif typeof(data_block) == TYPE_DICTIONARY and data_block.has("player_id"):
		reponse_client["player_id"] = data_block["player_id"]

	if flask_response.has("access_token"):
		reponse_client["access_token"] = flask_response["access_token"]
	elif typeof(data_block) == TYPE_DICTIONARY and data_block.has("access_token"):
		reponse_client["access_token"] = data_block["access_token"]

	if flask_response.has("refresh_token"):
		reponse_client["refresh_token"] = flask_response["refresh_token"]
	elif typeof(data_block) == TYPE_DICTIONARY and data_block.has("refresh_token"):
		reponse_client["refresh_token"] = data_block["refresh_token"]

	if flask_response.has("expires_in"):
		reponse_client["expires_in"] = flask_response["expires_in"]
	elif typeof(data_block) == TYPE_DICTIONARY and data_block.has("expires_in"):
		reponse_client["expires_in"] = data_block["expires_in"]
	print("SESSION STOCKEE : ", active_sessions.get(client, {}))
	send_to_client(client, reponse_client)

func is_client_authenticated(client: StreamPeerTCP) -> bool:
	if not active_sessions.has(client):
		return false
	
	var session = active_sessions[client]
	var token = session.get("access_token", "")
	var expires_at = int(session.get("expires_at", 0))
	
	if token == "":
		return false
	
	if expires_at > 0 and Time.get_unix_time_from_system() >= expires_at:
		active_sessions.erase(client)
		return false
	
	return true
	
func get_client_token(client: StreamPeerTCP) -> String:
	if not is_client_authenticated(client):
		return ""
	return active_sessions[client].get("access_token", "")
## ====================================================
## 3. ENVOI AU CLIENT GODOT
## ====================================================

func send_to_client(client: StreamPeerTCP, data: Dictionary):
	if client.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		var json_string = JSON.stringify(data) + "\n"
		client.put_data(json_string.to_utf8_buffer())
		print("-> Réponse envoyée au client pour : ", data.get("action_reply", "inconnu"))
