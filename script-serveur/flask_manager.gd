extends Node

# ─────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────
const FLASK_URL = "http://192.168.100.125:5000"

# ─────────────────────────────────────────
# ENVOI VERS FLASK (Méthode POST)
# ─────────────────────────────────────────
func send(action_name: String, endpoint: String, payload: Dictionary, client: WebSocketPeer, extra: Dictionary = {}, token: String = ""):
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(
		_on_response.bind(client, http, action_name, extra)
	)

	var headers = ["Content-Type: application/json"]
	if token != "":
		headers.append("Authorization: Bearer " + token)

	http.request(
		FLASK_URL + endpoint,
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(payload)
	)
	print("[FLASK] -> Envoi vers ", endpoint, " | action : ", action_name)

# ─────────────────────────────────────────
# ENVOI VERS FLASK (Méthode GET)
# ─────────────────────────────────────────
func send_get(action_name: String, endpoint: String, client: WebSocketPeer):
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(
		_on_response.bind(client, http, action_name, {})
	)
	http.request(
		FLASK_URL + endpoint,
		["Content-Type: application/json"],
		HTTPClient.METHOD_GET,
		""
	)
	print("[FLASK] -> GET vers ", endpoint, " | action : ", action_name)

# ─────────────────────────────────────────
# RÉCEPTION DES RÉPONSES FLASK
# ─────────────────────────────────────────
func _on_response(result, response_code, headers, body, client: WebSocketPeer, http: HTTPRequest, action_name: String, extra: Dictionary = {}):
	http.queue_free()

	var serveur = get_parent()
	print("[FLASK] action : ", action_name, " | code : ", response_code)

	# Erreur HTTP critique
	if response_code == 0 or response_code >= 500:
		serveur.send_to_client(client, {
			"action_reply": action_name,
			"status": "error",
			"message": "Erreur serveur BDD (code " + str(response_code) + ")."
		})
		return

	# Parse JSON
	var raw_body = body.get_string_from_utf8()
	var flask_response = JSON.parse_string(raw_body)

	if flask_response == null:
		print("[FLASK] JSON invalide : ", raw_body)
		serveur.send_to_client(client, {
			"action_reply": action_name,
			"status": "error",
			"message": "Réponse Flask invalide."
		})
		return

	# --- GESTION DE L'EXPIRATION DU TOKEN ---
	if response_code == 401:
		serveur.send_to_client(client, {
		"action_reply": action_name,
		"status": "error",
		"type": "token_expire",
		"message": "Session expirée, veuillez vous reconnecter."})
		# Nettoyer la session du joueur
		serveur.active_sessions.erase(client)
		serveur.active_tokens.erase(client)
		return
	# ----------------------------------------

	# --- GESTION DU LOGIN ---
	if action_name == "login":
		if flask_response.get("status") == "success":
			var player_id = flask_response.get("player_id")
			var access_token = flask_response.get("access_token")
			serveur.on_client_login_success(client, player_id, access_token)

			serveur.send_to_client(client, {
				"action_reply": "authentification",
				"status": "success",
				"access_token": access_token,
				"player_id": player_id
			})

			var http_nick = HTTPRequest.new()
			add_child(http_nick)
			http_nick.request_completed.connect(_on_nickname_fetched.bind(client, http_nick))
			http_nick.request(FLASK_URL + "/player/" + str(int(float(player_id))) + "/stats",
				["Content-Type: application/json"], HTTPClient.METHOD_GET, "")
		return
	
	# ------ MODE GUEST MANAGER
	elif action_name == "guest_player":
		if flask_response.get("status") == "success":
			var guest_id = flask_response.get("guest_id")
			var nickname = flask_response.get("nickname", "")
			
			serveur.guest_sessions[client] = guest_id
			serveur.guest_nicknames[client] = nickname
			print("[FlaslManager] Guest enregistré : ", nickname, " (id : ", guest_id, ")")
			
			serveur.send_to_client(client, {
				"action_reply": "guest_player",
				"status": "success",
				"guest_id": guest_id,
				"nickname": nickname
			})
		else:
			serveur.send_to_client(client, {
				"action_reply": "guest_player",
				"status": "error",
				"message": flask_response.get("message", "Erreur création guest.")
			})
		return
			
	# --- GESTION DES STATISTIQUES (GET_STATS) ---
	elif action_name == "get_stats":
		if flask_response.get("status") == "success":
			# On prépare le dictionnaire avec toutes les stats reçues de l'API Flask
			serveur.send_to_client(client, {
				"action_reply":          "get_stats",
				"status":                "success",
				"player_id":             flask_response.get("player_id"),
				"nickname":              flask_response.get("nickname"),
				"email":                 flask_response.get("email"),
				"created_at":            flask_response.get("created_at"),
				"avatar_url":            flask_response.get("avatar_url"),
				"wins_count":            flask_response.get("wins_count"),
				"games_played_count":    flask_response.get("games_played_count"),
				"total_monuments_built": flask_response.get("total_monuments_built"),
				"winrate":               flask_response.get("winrate")
			})
		else:
			# Gestion de l'erreur si le joueur n'existe pas en BDD
			serveur.send_to_client(client, {
				"action_reply": "get_stats",
				"status": "error",
				"message": flask_response.get("message", "Impossible de récupérer les stats.")
			})
		return

	# --- GESTION DU LOGOUT ---
	elif action_name == "logout":
		if flask_response.get("status") == "success":
			print("Déconnexion confirmée par Flask pour un client.")
			
			# Nettoyer la session du joueur de la mémoire du Game Server
			serveur.active_sessions.erase(client)
			serveur.active_tokens.erase(client)
			
			serveur.send_to_client(client, {
				"action_reply": "logout",
				"status": "success",
				"message": "Déconnexion réussie."
			})
		else:
			serveur.send_to_client(client, {
				"action_reply": "logout",
				"status": "error",
				"message": flask_response.get("message", "Erreur lors de la déconnexion.")
			})
		return

	# --- GESTION CREATE_GAME ---
	elif action_name == "create_game" and flask_response.get("status") == "success":
		var game_id  = flask_response.get("game_id")
		var lobby_id = extra.get("lobby_id", "")
		
		if not serveur.lobbies.has(lobby_id):
			print("[FLASK] Lobby", lobby_id, "n'existe plus, annulation" )
			return

		if serveur.lobbies.has(lobby_id):
			serveur.lobbies[lobby_id]["game_id"] = game_id
			serveur.lobbies[lobby_id]["etat"]    = "EN_JEU"

			var ordre_joueurs = []
			var game_players: Array = []
			
			for joueur in serveur.lobbies[lobby_id]["joueurs"]:
				var p_id = serveur.active_sessions.get(joueur, null)
				var g_id = serveur.guest_sessions.get(joueur, null)
				var id = p_id if p_id != null else g_id
				var nickname = serveur.active_nicknames.get(joueur, str(p_id))
				ordre_joueurs.append(str(id))

				var new_player = Player.new(nickname, int(float(str(id))), 3)
				game_players.append(new_player)

			serveur.broadcast_lobby(lobby_id, {
				"action_reply": "create_game",
				"type":         "game_demarre",
				"status":       "success",
				"data": {
					"game_id":       game_id,
					"ordre_joueurs": ordre_joueurs
				}
			})
			
			serveur.get_node("GameHandler").start_new_game(lobby_id, game_players)
			#serveur.lobbies.erase(lobby_id)
		return

	# ── Réponse générique pour les autres actions ──
	var reponse = {
		"action_reply": action_name,
		"status":       flask_response.get("status", "error"),
		"message":      flask_response.get("message", "Erreur inconnue.")
	}

	if flask_response.has("data"):
		reponse["data"] = flask_response["data"]
	if flask_response.has("player_id"):
		reponse["player_id"] = flask_response["player_id"]
	if flask_response.has("guest_id"):
		reponse["guest_id"] = flask_response["guest_id"]

	serveur.send_to_client(client, reponse)
	
func _on_nickname_fetched(result, code, _headers, body, client: WebSocketPeer, http: HTTPRequest):
	http.queue_free()
	if code != 200: return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if data == null: return
	if data.get("status") == "success":
		var nickname = data.get("nickname", "")
		var serveur = get_parent()
		if nickname != "" and serveur.active_sessions.has(client):
			serveur.active_nicknames[client] = nickname
			print("[FlaskManager] Nickname stored: ", nickname)
