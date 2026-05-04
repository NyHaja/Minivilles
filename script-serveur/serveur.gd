extends Node

# ─────────────────────────────────────────
# VARIABLES GLOBALES
# ─────────────────────────────────────────
var server := TCPServer.new()
var port = 10000

# [SÉCURITÉ] Variables pour gérer le TLS
var tls_options: TLSOptions
var clients : Array[StreamPeerTLS] = [] # Changé de StreamPeerTCP à StreamPeerTLS

var request_queue : Array = []
const MAX_REQUESTS_PER_FRAME = 1000

var active_sessions : Dictionary = {}
var active_tokens : Dictionary = {}
var lobbies : Dictionary = {}

# ─────────────────────────────────────────
# INITIALISATION
# ─────────────────────────────────────────
func _ready():
	print("--- INITIALISATION DU SERVEUR ---")
	
	# 1. Chargement des certificats TLS
	var key = CryptoKey.new()
	var cert = X509Certificate.new()
	
	# Assure-toi que ces fichiers sont dans le même dossier que l'exécutable sur la VM
	var err_key = key.load("res://server.key")
	var err_cert = cert.load("res://server.crt")
	
	if err_key != OK or err_cert != OK:
		print("[ERREUR CRITIQUE] Impossible de charger les certificats TLS (server.key ou server.crt).")
		print("Vérifiez que les fichiers sont bien présents à la racine du projet ou de l'exécutable.")
		return # On bloque le démarrage pour éviter de tourner sans sécurité
		
	tls_options = TLSOptions.server(key, cert)
	print("[SÉCURITÉ] Certificats TLS chargés avec succès.")

	# 2. Démarrage du serveur TCP
	var err = server.listen(port)
	if err == OK:
		print("Serveur SÉCURISÉ en écoute sur le port ", port, " ! En attente de connexions...")
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
		print("Nouvelle connexion TCP brute depuis l'IP : ", tcp_client.get_connected_host())
		
		# ... on l'enveloppe immédiatement dans un tunnel TLS
		var tls_client = StreamPeerTLS.new()
		tls_client.accept_stream(tcp_client, tls_options)
		clients.append(tls_client)

	for i in range(clients.size() - 1, -1, -1):
		var client = clients[i]
		
		
		client.poll()
		
		var status = client.get_status()

		if status == StreamPeerTLS.STATUS_CONNECTED:
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

		elif status == StreamPeerTLS.STATUS_DISCONNECTED or status == StreamPeerTLS.STATUS_ERROR:
			print("Un client s'est déconnecté ou erreur TLS détectée.")
			clients.remove_at(i)
			# Nettoyage optionnel des sessions en cas de déconnexion brutale
			active_sessions.erase(client)
			active_tokens.erase(client)

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
func route_request(client: StreamPeerTLS, data: Dictionary): # Type changé ici
	if not data.has("action"):
		send_to_client(client, {"status": "error", "message": "Action manquante."})
		return

	var action = data["action"]
	match action:
		# Auth
		"register", "authentification", "guest_player", "historic", "forgot_password", "get_stats", "logout":
			$AuthHandler.handle(client, data)
		# Lobby
		"create_lobby", "join_lobby", "leave_lobby", "create_game":
			$LobbyHandler.handle(client, data)
		_:
			send_to_client(client, {"status": "error", "message": "Action non reconnue."})

# ─────────────────────────────────────────
# ENVOI AU CLIENT
# ─────────────────────────────────────────
func send_to_client(client: StreamPeerTLS, data: Dictionary): # Type changé ici
	if client.get_status() == StreamPeerTLS.STATUS_CONNECTED:
		var json_string = JSON.stringify(data) + "\n"
		client.put_data(json_string.to_utf8_buffer())
		print("-> Réponse envoyée au client pour : ", data.get("action_reply", "inconnu"))

# ─────────────────────────────────────────
# UTILITAIRES
# ─────────────────────────────────────────
func on_client_login_success(client_socket: StreamPeerTLS, player_id, token: String = ""):
	active_sessions[client_socket] = int(player_id)
	active_tokens[client_socket]   = token
	print("Joueur ", int(player_id), " connecté avec token.")

func get_token(client: StreamPeerTLS) -> String:
	return active_tokens.get(client, "")

func get_player_id(client: StreamPeerTLS):
	return active_sessions.get(client, null)

func broadcast_lobby(lobby_id: String, data: Dictionary):
	var lobby = lobbies[lobby_id]
	for joueur in lobby["joueurs"]:
		send_to_client(joueur, data)
