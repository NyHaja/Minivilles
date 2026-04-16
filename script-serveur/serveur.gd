extends Node

# ─────────────────────────────────────────
# VARIABLES GLOBALES
# ─────────────────────────────────────────
var server := TCPServer.new()
var port = 10000
var clients : Array[StreamPeerTCP] = []
var request_queue : Array = []
const MAX_REQUESTS_PER_FRAME = 10

var active_sessions : Dictionary = {}
var lobbies : Dictionary = {}

# ─────────────────────────────────────────
# INITIALISATION
# ─────────────────────────────────────────
func _ready():
	print("Démarrage du Game Server sur le port ", port, "...")
	var err = server.listen(port)
	if err == OK:
		print("Serveur en écoute ! En attente de connexions du client Godot...")
	else:
		print("Erreur lors du démarrage du serveur : ", err)

# ─────────────────────────────────────────
# BOUCLE PRINCIPALE
# ─────────────────────────────────────────
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
							request_queue.append({"client": client, "data": parsed_data})
							print("[FILE] -> Requête '", parsed_data["action"], "' ajoutée. (En attente : ", request_queue.size(), ")")

		elif client.get_status() == StreamPeerTCP.STATUS_NONE or client.get_status() == StreamPeerTCP.STATUS_ERROR:
			print("Un client s'est déconnecté.")
			clients.remove_at(i)

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
func route_request(client: StreamPeerTCP, data: Dictionary):
	if not data.has("action"):
		send_to_client(client, {"status": "error", "message": "Action manquante."})
		return

	var action = data["action"]
	match action:
		# Auth
		"register", "authentification", "guest_player", "historic":
			$AuthHandler.handle(client, data)
		# Lobby
		"create_lobby", "join_lobby", "leave_lobby", "create_game":
			$LobbyHandler.handle(client, data)
		_:
			send_to_client(client, {"status": "error", "message": "Action non reconnue."})

# ─────────────────────────────────────────
# ENVOI AU CLIENT
# ─────────────────────────────────────────
func send_to_client(client: StreamPeerTCP, data: Dictionary):
	if client.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		var json_string = JSON.stringify(data) + "\n"
		client.put_data(json_string.to_utf8_buffer())
		print("-> Réponse envoyée au client pour : ", data.get("action_reply", "inconnu"))

# ─────────────────────────────────────────
# UTILITAIRES
# ─────────────────────────────────────────
func on_client_login_success(client_socket, player_id):
	active_sessions[client_socket] = int(player_id)
	print("Joueur ", int(player_id), " est maintenant lié à cette connexion.")

func get_player_id(client: StreamPeerTCP):
	return active_sessions.get(client, null)

func broadcast_lobby(lobby_id: String, data: Dictionary):
	var lobby = lobbies[lobby_id]
	for joueur in lobby["joueurs"]:
		send_to_client(joueur, data)
