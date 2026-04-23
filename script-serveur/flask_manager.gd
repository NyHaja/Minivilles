extends Node

# ─────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────
const FLASK_URL = "http://192.168.100.125:5000"

# ─────────────────────────────────────────
# ENVOI VERS FLASK
# ─────────────────────────────────────────
func send(action_name: String, endpoint: String, payload: Dictionary, client: StreamPeerTCP, extra: Dictionary = {}):
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(
		_on_response.bind(client, http, action_name, extra)
	)
	http.request(
		FLASK_URL + endpoint,
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify(payload)
	)
	print("[FLASK] -> Envoi vers ", endpoint, " | action : ", action_name)

# ─────────────────────────────────────────
# RÉCEPTION DES RÉPONSES FLASK
# ─────────────────────────────────────────
func _on_response(result, response_code, headers, body, client: StreamPeerTCP, http: HTTPRequest, action_name: String, extra: Dictionary = {}):
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

	if action_name == "get_auth_data" and flask_response.get("status") == "success":
		var stored_hash = flask_response.get("password_hash")
		var player_id = flask_response.get("player_id")
		var password_saisi = extra.get("password")

		# Appel C# : on remonte au parent (Main) puis on descend vers Hasher
		var is_valid = $"../Hasher".VerifyLogin(password_saisi, stored_hash)
		
		if is_valid:
			print("Connexion réussie pour le joueur : ", player_id)
			serveur.on_client_login_success(client, player_id)
			serveur.send_to_client(client, {
				"action_reply": "authentification",
				"status": "reussie",
				"message": "Go."
			})
		else:
			print("Échec : Mot de passe incorrect")
			# Envoi du message d'erreur au client
			serveur.send_to_client(client, {
				"action_reply": "authentification",
				"status": "error",
				"message": "Mot de passe incorrect."
			})
		return
		
		
	elif action_name == "create_game" and flask_response.get("status") == "success":
		var game_id  = flask_response.get("game_id")
		var lobby_id = extra.get("lobby_id", "")

		if serveur.lobbies.has(lobby_id):
			serveur.lobbies[lobby_id]["game_id"] = game_id
			serveur.lobbies[lobby_id]["etat"]    = "EN_JEU"

			var ordre_joueurs = []
			var game_players: Array = []
			
			for joueur in serveur.lobbies[lobby_id]["joueurs"]:
				var p_id = serveur.active_sessions.get(joueur, "inconnu")
				ordre_joueurs.append(p_id)
				
				var new_player = Player.new(str(p_id), p_id, 3)
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
