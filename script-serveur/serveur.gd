extends Node

# ─────────────────────────────────────────
# VARIABLES GLOBALES
# ─────────────────────────────────────────
var server := TCPServer.new()
var port = 80 # Port 80 pour le reverse proxy de la fac [cite: 14]
var clients : Array[WebSocketPeer] = []

var request_queue : Array = []
const MAX_REQUESTS_PER_FRAME = 1000

var active_sessions : Dictionary = {}
var active_tokens : Dictionary = {}
var lobbies : Dictionary = {}
var active_nicknames: Dictionary = {}
var guest_sessions: Dictionary = {}

# ─────────────────────────────────────────
# INITIALISATION
# ─────────────────────────────────────────
func _ready():
	print("--- INITIALISATION DU SERVEUR WEBSOCKET ---")
	var err = server.listen(port)
	if err == OK:
		print("Serveur en écoute sur le port ", port)
	else:
		print("Erreur démarrage serveur : ", err)

# ─────────────────────────────────────────
# BOUCLE PRINCIPALE
# ─────────────────────────────────────────
func _process(_delta):
	receive_and_queue_requests()
	process_queue()

func receive_and_queue_requests():
	if server.is_connection_available():
		var tcp_client = server.take_connection()
		var ws_client = WebSocketPeer.new()
		ws_client.accept_stream(tcp_client)
		clients.append(ws_client)

	for i in range(clients.size() - 1, -1, -1):
		var client = clients[i]
		client.poll()
		var state = client.get_ready_state()

		if state == WebSocketPeer.STATE_OPEN:
			while client.get_available_packet_count() > 0: 
				var request_str = client.get_packet().get_string_from_utf8()
				var parsed_data = JSON.parse_string(request_str)
				
				if typeof(parsed_data) == TYPE_DICTIONARY and parsed_data.has("action"):
					request_queue.append({"client": client, "data": parsed_data})

		elif state == WebSocketPeer.STATE_CLOSED:
			clients.remove_at(i)
			active_sessions.erase(client)
			active_tokens.erase(client)

func process_queue():
	var count = 0
	while request_queue.size() > 0 and count < MAX_REQUESTS_PER_FRAME:
		var task = request_queue.pop_front()
		route_request(task["client"], task["data"])
		count += 1

# ─────────────────────────────────────────
# DISPATCH DES REQUÊTES (Version Pong incluse)
# ─────────────────────────────────────────
func route_request(client: WebSocketPeer, data: Dictionary):
	var action = data.get("action", "")
	
	match action:
		"ping":
			# Réponse immédiate pour maintenir la connexion active
			send_to_client(client, {"action_reply": "pong", "status": "success"})
		
		"register", "authentification", "guest_player", "historic", "get_stats", "logout": 
			$AuthHandler.handle(client, data)
			
		"create_lobby", "join_lobby", "leave_lobby", "create_game": 
			$LobbyHandler.handle(client, data)
			
		"game_action":
			$GameHandler.handle(client, data)
			
		_:
			send_to_client(client, {"status": "error", "message": "Action inconnue."})

# ─────────────────────────────────────────
# ENVOI AU CLIENT
# ─────────────────────────────────────────
func send_to_client(client: WebSocketPeer, data: Dictionary):
	if client.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var json_string = JSON.stringify(data)
		client.put_packet(json_string.to_utf8_buffer()) 

# ─────────────────────────────────────────
# UTILITAIRES
# ─────────────────────────────────────────
func on_client_login_success(client_socket: WebSocketPeer, player_id, token: String = "", nickname: String=""):
	active_sessions[client_socket] = int(player_id)
	active_tokens[client_socket] = token
	active_nicknames[client_socket] = nickname if nickname != "" else str(int(player_id))
