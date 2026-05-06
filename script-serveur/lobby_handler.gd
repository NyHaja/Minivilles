extends Node

# ─────────────────────────────────────────
# POINT D'ENTRÉE
# ─────────────────────────────────────────
func handle(client: StreamPeerTLS, data: Dictionary):
	match data.get("action", ""):
		"create_lobby": _handle_create(client, data)
		"join_lobby":   _handle_join(client, data)
		"leave_lobby":  _handle_leave(client, data)
		"create_game":  _handle_start(client, data)

# ─────────────────────────────────────────
# UTILITAIRES LOCAUX
# ─────────────────────────────────────────
func generer_lobby_id() -> String:
	var alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var code = ""
	for i in range(6):
		code += alphabet[randi() % alphabet.length()]
	return code

func generer_code_unique() -> String:
	var code = generer_lobby_id()
	while get_parent().lobbies.has(code):
		code = generer_lobby_id()
	return code

# ─────────────────────────────────────────
# CREATE LOBBY
# ─────────────────────────────────────────
func _handle_create(client: StreamPeerTLS, data: Dictionary):
	var serveur = get_parent()
	var player_id = serveur.get_player_id(client)

	if player_id == null:
		serveur.send_to_client(client, {
			"action_reply": "create_lobby",
			"status": "error",
			"message": "Vous devez être connecté pour créer un lobby."
		})
		return

	var nom         = data.get("nom", "Partie sans nom")
	var max_joueurs = data.get("max_joueurs", 4)
	var prive       = data.get("prive", false)
	var lobby_id    = generer_code_unique()

	serveur.lobbies[lobby_id] = {
		"nom":         nom,
		"host":        client,
		"joueurs":     [client],
		"max_joueurs": max_joueurs,
		"prive":       prive,
		"etat":        "EN_ATTENTE"
	}

	print("[LOBBY] Lobby créé : ", lobby_id, " par joueur ", player_id)

	serveur.send_to_client(client, {
		"action_reply": "create_lobby",
		"type":         "lobby_cree",
		"status":       "success",
		"data": {
			"lobby_id":    lobby_id,
			"nom":         nom,
			"max_joueurs": max_joueurs,
			"prive":       prive,
			"joueurs":     [player_id]
		}
	})
	
	

# ─────────────────────────────────────────
# JOIN LOBBY
# ─────────────────────────────────────────
func _handle_join(client: StreamPeerTLS, data: Dictionary):
	var serveur   = get_parent()
	var player_id = serveur.get_player_id(client)
	var lobby_id  = data.get("lobby_id", "").strip_edges().to_upper()

	if player_id == null:
		serveur.send_to_client(client, {
			"action_reply": "join_lobby",
			"type": "joueur_non_connectee",
			"status": "error",
			"message": "Vous devez être connecté pour rejoindre un lobby."
		})
		return
		
	if lobby_id.length() !=6:
		serveur.send_to_client(client, {
			"action_reply": "join_lobby",
			"type":"code_incomplet",
			"status": "error",
			"message": "Code invalide."
		})
		return

	if not serveur.lobbies.has(lobby_id):
		serveur.send_to_client(client, {
			"action_reply": "join_lobby",
			"type": "lobby_erreur",
			"status": "error",
			"message": "Lobby introuvable."
		})
		return

	var lobby = serveur.lobbies[lobby_id]

	if lobby["etat"] != "EN_ATTENTE":
		serveur.send_to_client(client, {
			"action_reply": "join_lobby",
			"type": "partie_commencee",
			"status": "error",
			"message": "La partie a déjà commencé."
		})
		return

	if lobby["joueurs"].size() >= lobby["max_joueurs"]:
		serveur.send_to_client(client, {
			"action_reply": "join_lobby",
			"type": "lobby_plein",
			"status": "error",
			"message": "Le lobby est plein."
		})
		return

	if client in lobby["joueurs"]:
		serveur.send_to_client(client, {
			"action_reply": "join_lobby",
			"type": "joueur_deja_connecte",
			"status": "error",
			"message": "Vous êtes déjà dans ce lobby."
		})
		return

	lobby["joueurs"].append(client)
	print("[LOBBY] Joueur ", player_id, " a rejoint le lobby ", lobby_id)

	var liste_joueurs = []
	for joueur in lobby["joueurs"]:
		liste_joueurs.append(serveur.active_sessions.get(joueur, "inconnu"))

	serveur.broadcast_lobby(lobby_id, {
		"action_reply": "join_lobby",
		"type":         "lobby_mis_a_jour",
		"status":       "success",
		"data": {
			"lobby_id": lobby_id,
			"joueurs":  liste_joueurs
		}
	})

# ─────────────────────────────────────────
# LEAVE LOBBY
# ─────────────────────────────────────────
func _handle_leave(client: StreamPeerTLS, data: Dictionary):
	var serveur   = get_parent()
	var player_id = serveur.get_player_id(client)
	var lobby_id  = data.get("lobby_id", "")

	if not serveur.lobbies.has(lobby_id):
		serveur.send_to_client(client, {
			"action_reply": "leave_lobby",
			"status": "error",
			"message": "Lobby introuvable."
		})
		return

	var lobby = serveur.lobbies[lobby_id]
	lobby["joueurs"].erase(client)
	print("[LOBBY] Joueur ", player_id, " a quitté le lobby ", lobby_id)

	if lobby["joueurs"].size() == 0:
		serveur.lobbies.erase(lobby_id)
		print("[LOBBY] Lobby ", lobby_id, " dissous (vide)")
		return

	if lobby["host"] == client:
		lobby["host"] = lobby["joueurs"][0]
		print("[LOBBY] Nouveau host : ", serveur.active_sessions.get(lobby["host"], "inconnu"))

	var liste_joueurs = []
	for joueur in lobby["joueurs"]:
		liste_joueurs.append(serveur.active_sessions.get(joueur, "inconnu"))

	serveur.broadcast_lobby(lobby_id, {
		"action_reply": "leave_lobby",
		"type":         "lobby_mis_a_jour",
		"status":       "success",
		"data": {
			"lobby_id": lobby_id,
			"joueurs":  liste_joueurs
		}
	})

# ─────────────────────────────────────────
# START GAME
# ─────────────────────────────────────────
func _handle_start(client: StreamPeerTLS, data: Dictionary):
	var serveur   = get_parent()
	var player_id = serveur.get_player_id(client)
	var lobby_id  = data.get("lobby_id", "")

	if not serveur.lobbies.has(lobby_id):
		serveur.send_to_client(client, {
			"action_reply": "create_game",
			"status": "error",
			"message": "Lobby introuvable."
		})
		return

	var lobby = serveur.lobbies[lobby_id]

	if lobby["host"] != client:
		serveur.send_to_client(client, {
			"action_reply": "create_game",
			"status": "error",
			"message": "Seul le host peut lancer la partie."
		})
		return

	if lobby["joueurs"].size() < 2:
		serveur.send_to_client(client, {
			"action_reply": "create_game",
			"status": "error",
			"message": "Il faut au moins 2 joueurs pour lancer la partie."
		})
		return

	print("[LOBBY] Partie lancée dans le lobby ", lobby_id)

	$"../FlaskManager".send("create_game", "/game/create", {
		"player_id":   player_id,
		"player_type": "registered"
	}, client, {"lobby_id": lobby_id})
