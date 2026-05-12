extends Node

# ─────────────────────────────────────────
# VARIABLES GLOBALES
# ─────────────────────────────────────────
var server := TCPServer.new()
var port = 80 # <-- IMPORTANT : Port 80 pour le reverse proxy de la fac !

# [SÉCURITÉ] Plus besoin de TLS, le reverse proxy s'en charge.
var clients : Array[WebSocketPeer] = [] # Changé en WebSocketPeer

var request_queue : Array = []
const MAX_REQUESTS_PER_FRAME = 1000

var active_sessions : Dictionary = {}
var active_tokens : Dictionary = {}
var lobbies : Dictionary = {}

<<<<<<< Updated upstream
var active_nicknames: Dictionary = {}
var guest_sessions: Dictionary = {}

=======
>>>>>>> Stashed changes
# ─────────────────────────────────────────
# INITIALISATION
# ─────────────────────────────────────────
func _ready():
	print("--- INITIALISATION DU SERVEUR WEBSOCKET ---")
	
	# Démarrage du serveur TCP (qui servira de base pour les WebSockets)
	var err = server.listen(port)
	if err == OK:
		print("Serveur WEBSOCKET en écoute sur le port ", port, " ! En attente de connexions...")
	else:
		print("Erreur lors du démarrage du serveur : ", err)

# ─────────────────────────────────────────
# BOUCLE PRINCIPALE
# ─────────────────────────────────────────
func _process(_delta):
	receive_and_queue_requests()
	process_queue()

func receive_and_queue_requests():
	# Si un client TCP frappe à la porte...
	if server.is_connection_available():
		var tcp_client = server.take_connection()
		print("Nouvelle connexion depuis l'IP : ", tcp_client.get_connected_host())
		
		# ... on l'enveloppe immédiatement en WebSocket
		var ws_client = WebSocketPeer.new()
		ws_client.accept_stream(tcp_client)
		clients.append(ws_client)

	for i in range(clients.size() - 1, -1, -1):
		var client = clients[i]
		
		client.poll()
		
		var state = client.get_ready_state()

		if state == WebSocketPeer.STATE_OPEN:
			# WebSocket lit par paquets, plus besoin de couper avec "\n" !
			while client.get_available_packet_count() > 0:
				var request_str = client.get_packet().get_string_from_utf8()
				var parsed_data = JSON.parse_string(request_str)
				
				if typeof(parsed_data) == TYPE_DICTIONARY and parsed_data.has("action"):
					request_queue.append({"client": client, "data": parsed_data})
					print("[FILE] -> Requête '", parsed_data["action"], "' ajoutée. (En attente : ", request_queue.size(), ")")

		elif state == WebSocketPeer.STATE_CLOSED:
			print("Un client s'est déconnecté (Fermeture WebSocket).")
			clients.remove_at(i)
			# Nettoyage optionnel des sessions en cas de déconnexion brutale
			active_sessions.erase(client)
			active_tokens.erase(client)
			active_nicknames.erase(client) 

func process_queue():
	var count = 0
	while request_queue.size() > 0 and count < MAX_REQUESTS_PER_FRAME:
		var task = request_queue.pop_front()
		print("<- [TRAITEMENT] Dépilage de l'action : ", task["data"]["action"])
		route_request(task["client"], task["data"])
		count += 1

# ─────────────────────────────────────────
# DISPATCH DES REQUÊTES
# ─────────────────────────────────────────
func route_request(client: WebSocketPeer, data: Dictionary): # Type changé ici
	if not data.has("action"):
		send_to_client(client, {"status": "error", "message": "Action manquante."})
		return

	var action = data["action"]
	match action:
		# Auth
		"register", "authentification", "guest_player", "historic", "forgot_password", "verify_reset_code", "get_stats", "logout":
			$AuthHandler.handle(client, data)
		# Lobby
		"create_lobby", "join_lobby", "leave_lobby", "create_game":
			# Je suppose que tu as un LobbyHandler, n'oublie pas de changer StreamPeerTLS en WebSocketPeer dedans aussi !
			$LobbyHandler.handle(client, data) 
		# Game
		"game_action":
			$GameHandler.handle(client, data)
		_:
			send_to_client(client, {"status": "error", "message": "Action non reconnue."})

# ─────────────────────────────────────────
# ENVOI AU CLIENT
# ─────────────────────────────────────────
func send_to_client(client: WebSocketPeer, data: Dictionary): # Type changé ici
	if client.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var json_string = JSON.stringify(data)
		# Plus besoin d'ajouter + "\n" à la fin !
		client.put_packet(json_string.to_utf8_buffer())
		print("-> Réponse envoyée au client pour : ", data.get("action_reply", "inconnu"))

# ─────────────────────────────────────────
# UTILITAIRES
# ─────────────────────────────────────────
<<<<<<< Updated upstream
func on_client_login_success(client_socket: StreamPeerTLS, player_id, token: String = "", nickname: String = ""):
=======
func on_client_login_success(client_socket: WebSocketPeer, player_id, token: String = ""):
>>>>>>> Stashed changes
	active_sessions[client_socket] = int(player_id)
	active_tokens[client_socket] = token
	active_nicknames[client_socket] = nickname if nickname != "" else str(int(player_id))
	print("Joueur ", int(player_id), " (", nickname, ") connecté avec token.")

func get_token(client: WebSocketPeer) -> String:
	return active_tokens.get(client, "")

func get_player_id(client: WebSocketPeer):
	return active_sessions.get(client, null)

func broadcast_lobby(lobby_id: String, data: Dictionary):
	var lobby = lobbies[lobby_id]
	for joueur in lobby["joueurs"]:
		send_to_client(joueur, data)
		
func send_to_player(player_id: int, data: Dictionary):
	for client in active_sessions.keys():
		if active_sessions[client] == player_id:
			send_to_client(client, data)
			return
