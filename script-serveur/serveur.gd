extends Node

# --- VARIABLES GLOBALES DU SERVEUR ---
var server := TCPServer.new()
var port = 10000
var clients : Array[StreamPeerTCP] = []

# TA FILE D'ATTENTE EST ICI
var request_queue : Array = [] 
const MAX_REQUESTS_PER_FRAME = 10 

# ---------------------------------------------------------
# VARIABLES GLOBALES
# ---------------------------------------------------------
var active_sessions : Dictionary = {}
var lobbies : Dictionary = {}

func on_client_login_success(client_socket, player_id):
	active_sessions[client_socket] = player_id
	print("Joueur ", player_id, " est maintenant lié à cette connexion.")

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
	
# ------------------- Authentification -------------------
	match action:
		"register":
			handler_register(client, data)
			
		"historic": 
			handler_historic(client, data)
		"authentification" : 
			handler_authentification(client,data)
		"guest_player":
			handler_guest_player(client,data)
# ------------------- Lobby -----------------------------
		"create_lobby":
			handler_create_lobby(client, data)
		"join_lobby":
			handler_join_lobby(client, data)
		"leave_lobby":
			handler_leave_lobby(client, data)
		"start_game":
			handler_start_game(client, data)
			
		_:	# default
			send_to_client(client, {"status": "error", "message": "Action non reconnue."})


## ====================================================
## 1. LES HANDLERS_AUTHENTIFICATION (Préparation des données)
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
	send_to_flask_api("historic", "/history/insert", payload, client)


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
func send_to_flask_api(action_name: String, endpoint: String, payload: Dictionary, client: StreamPeerTCP, extra: Dictionary={}):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	http_request.request_completed.connect(_on_flask_response.bind(client, http_request, action_name, extra))
	
	var url = "http://192.168.100.125:5000" + endpoint		# <- IP du serveur 1
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(payload)
	
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)


# Fonction unique pour recevoir TOUTES les réponses de Flask
func _on_flask_response(result, response_code, headers, body, client: StreamPeerTCP, http_node: HTTPRequest, action_name: String, extra: Dictionary={}):
	http_node.queue_free() # Nettoyage
	
	if response_code == 0 or response_code >= 500:
		send_to_client(client, {"action_reply": action_name, "status": "error", "message": "Erreur serveur BDD."})
		return
		
	var flask_response = JSON.parse_string(body.get_string_from_utf8())
	
	# --- NOUVEAU : INTERCEPTION DU LOGIN ---
	# Si l'action était l'authentification et que Flask renvoie un succès
	if action_name == "authentification" and flask_response.get("status") == "success":
		var player_id = flask_response.get("player_id")
		if player_id != null:
			# On lie le socket au player_id dans le dictionnaire active_sessions
			on_client_login_success(client, player_id)
	# ---------------------------------------
	if action_name == "start_game" and flask_response.get("status") == "success":
		var game_id = flask_response.get("game_id")
		var lobby_id = extra.get("lobby_id", "")
		if lobbies.has(lobby_id):
			lobbies[lobby_id]["game_id"] = game_id
			lobbies[lobby_id]['etat'] = "EN_JEU"
			
			var ordre_joueurs = []
			for joueur in lobbies[lobby_id]["joueurs"]:
				ordre_joueurs.append(active_sessions.get(joueur, "inconnu"))
				
			broadcast_lobby(lobby_id, {
				"action_reply": "start_game",
				"type": "game_demarre",
				"status": "success",
				"data": {
					"game_id": lobby_id,
					"ordre_joueurs": ordre_joueurs
				}
			})
		return
	# -----------------------------------------------------------------------
	# On construit la réponse à renvoyer au jeu (client Godot)
	var reponse_client = {
		"action_reply": action_name, 
		"status": flask_response.get("status", "error"),
		"message": flask_response.get("message", "Erreur inconnue.")
	}
	
	# S'il y a des données additionnelles (ex: le player_id), on les transmet au client
	if flask_response.has("data"):
		reponse_client["data"] = flask_response["data"]
		
	if flask_response.has("player_id"):
		reponse_client["player_id"] = flask_response["player_id"]
	
	send_to_client(client, reponse_client)
	



## ====================================================
## 3. ENVOI AU CLIENT GODOT
## ====================================================

func send_to_client(client: StreamPeerTCP, data: Dictionary):
	if client.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		var json_string = JSON.stringify(data) + "\n"
		client.put_data(json_string.to_utf8_buffer())
		print("-> Réponse envoyée au client pour : ", data.get("action_reply", "inconnu"))
		
## ====================================================
## 4. HANDLERS LOBBY
## ====================================================

# Génère un ID unique pour le lobby
# ID = CODE[6]
func generer_lobby_id() -> String:
	var alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var code = ""
	for i in range(6):
		code +=alphabet[randi() % alphabet.length()]
	return code
	
func generer_code_unique() -> String:
	var code = generer_lobby_id()
	while lobbies.has(code):
		code = generer_lobby_id()
	return code

# Récupère le player_id lié à un client
func get_player_id(client: StreamPeerTCP):
	return active_sessions.get(client, null)

# Notifie tous les joueurs d'un lobby que la partie va commencer
func broadcast_lobby(lobby_id: String, data: Dictionary):
	var lobby = lobbies[lobby_id]
	for joueur in lobby["joueurs"]:
		send_to_client(joueur, data)


## ── CREATE LOBBY ─────────────────────────────────────
func handler_create_lobby(client: StreamPeerTCP, data: Dictionary):
	
	# Vérifier que le joueur est connecté
	var player_id = get_player_id(client)
	if player_id == null:
		send_to_client(client, {
			"action_reply": "create_lobby",
			"status": "error",
			"message": "Vous devez être connecté pour créer un lobby."
		})
		return

	# Récupérer les paramètres
	var nom = data.get("nom", "Partie sans nom")
	var max_joueurs = data.get("max_joueurs", 4)
	var prive = data.get("prive", false)

	# Générer un ID unique
	var lobby_id = generer_code_unique()

	# Créer le lobby en mémoire
	lobbies[lobby_id] = {
		"nom": nom,
		"host": client,
		"joueurs": [client],
		"max_joueurs": max_joueurs,
		"prive": prive,
		"etat": "EN_ATTENTE"
	}

	print("[LOBBY] Lobby créé : ", lobby_id, " par joueur ", player_id)

	# Répondre au créateur
	send_to_client(client, {
		"action_reply": "create_lobby",
		"type": "lobby_cree",
		"status": "success",
		"data": {
			"lobby_id": lobby_id,
			"nom": nom,
			"max_joueurs": max_joueurs,
			"prive": prive,
			"joueurs": [player_id]
		}
	})


## ── JOIN LOBBY ───────────────────────────────────────
func handler_join_lobby(client: StreamPeerTCP, data: Dictionary):

	var player_id = get_player_id(client)
	if player_id == null:
		send_to_client(client, {
			"action_reply": "join_lobby",
			"status": "error",
			"message": "Vous devez être connecté pour rejoindre un lobby."
		})
		return

	var lobby_id = data.get("lobby_id", "")

	# Vérifier que le lobby existe
	if not lobbies.has(lobby_id):
		send_to_client(client, {
			"action_reply": "join_lobby",
			"status": "error",
			"message": "Lobby introuvable."
		})
		return

	var lobby = lobbies[lobby_id]

	# Vérifier que la partie n'a pas déjà commencé
	if lobby["etat"] != "EN_ATTENTE":
		send_to_client(client, {
			"action_reply": "join_lobby",
			"status": "error",
			"message": "La partie a déjà commencé."
		})
		return

	# Vérifier que le lobby n'est pas plein
	if lobby["joueurs"].size() >= lobby["max_joueurs"]:
		send_to_client(client, {
			"action_reply": "join_lobby",
			"status": "error",
			"message": "Le lobby est plein."
		})
		return

	# Vérifier que le joueur n'est pas déjà dans le lobby
	if client in lobby["joueurs"]:
		send_to_client(client, {
			"action_reply": "join_lobby",
			"status": "error",
			"message": "Vous êtes déjà dans ce lobby."
		})
		return

	# Ajouter le joueur
	lobby["joueurs"].append(client)
	print("[LOBBY] Joueur ", player_id, " a rejoint le lobby ", lobby_id)

	# Construire la liste des joueurs
	var liste_joueurs = []
	for joueur in lobby["joueurs"]:
		liste_joueurs.append(active_sessions.get(joueur, "inconnu"))

	# Notifier tous les joueurs du lobby
	broadcast_lobby(lobby_id, {
		"action_reply": "join_lobby",
		"type": "lobby_mis_a_jour",
		"status": "success",
		"data": {
			"lobby_id": lobby_id,
			"joueurs": liste_joueurs
		}
	})


## ── LEAVE LOBBY ──────────────────────────────────────
func handler_leave_lobby(client: StreamPeerTCP, data: Dictionary):

	var player_id = get_player_id(client)
	var lobby_id = data.get("lobby_id", "")

	if not lobbies.has(lobby_id):
		send_to_client(client, {
			"action_reply": "leave_lobby",
			"status": "error",
			"message": "Lobby introuvable."
		})
		return

	var lobby = lobbies[lobby_id]

	# Retirer le joueur
	lobby["joueurs"].erase(client)
	print("[LOBBY] Joueur ", player_id, " a quitté le lobby ", lobby_id)

	# Si le lobby est vide, le supprimer
	if lobby["joueurs"].size() == 0:
		lobbies.erase(lobby_id)
		print("[LOBBY] Lobby ", lobby_id, " dissous (vide)")
		return

	# Si le host quitte, transférer au joueur suivant
	if lobby["host"] == client:
		lobby["host"] = lobby["joueurs"][0]
		var nouveau_host_id = active_sessions.get(lobby["host"], "inconnu")
		print("[LOBBY] Nouveau host : ", nouveau_host_id)

	# Notifier les joueurs restants
	var liste_joueurs = []
	for joueur in lobby["joueurs"]:
		liste_joueurs.append(active_sessions.get(joueur, "inconnu"))

	broadcast_lobby(lobby_id, {
		"action_reply": "leave_lobby",
		"type": "lobby_mis_a_jour",
		"status": "success",
		"data": {
			"lobby_id": lobby_id,
			"joueurs": liste_joueurs
		}
	})


## ── START GAME ───────────────────────────────────────
func handler_start_game(client: StreamPeerTCP, data: Dictionary):

	var player_id = get_player_id(client)
	var lobby_id = data.get("lobby_id", "")

	if not lobbies.has(lobby_id):
		send_to_client(client, {
			"action_reply": "start_game",
			"status": "error",
			"message": "Lobby introuvable."
		})
		return

	var lobby = lobbies[lobby_id]

	# Vérifier que c'est le host qui lance
	if lobby["host"] != client:
		send_to_client(client, {
			"action_reply": "start_game",
			"status": "error",
			"message": "Seul le host peut lancer la partie."
		})
		return

	# Vérifier le nombre minimum de joueurs
	#if lobby["joueurs"].size() < 2:
		#send_to_client(client, {
			#"action_reply": "start_game",
			#"status": "error",
			#"message": "Il faut au moins 2 joueurs pour lancer la partie."
		#})
		#return
# Envoyer à Flask pour créer la ligne dans le GAME
	var payload = {
		"player_id":player_id,
		"player_type":"registered"
	}
	send_to_flask_api("start_game", "/game/create", payload, client, {"lobby_id": lobby_id})
	

func _on_start_game_response(result, response_code, headers, body, client : StreamPeerTCP, http_node: HTTPRequest, lobby_id: String):
	http_node.queue_free()
	
	var flask_response = JSON.parse_string(body.get_string_from_utf8())
	
	if flask_response.get("status") != "success":
		send_to_client(client, {
			"action_reply": "start_game",
			"status": "error",
			"message": "Erreur création partie en BDD"
		})
		return
		
	# Stokcer le game_INT retourné par Flask
	var game_id = flask_response.get("game_id")
	lobbies[lobby_id]["game_id"] = game_id
	lobbies[lobby_id]["etat"] = "EN_JEU"
	
	
