extends Node

# ─────────────────────────────────────────
# POINT D'ENTRÉE
# ─────────────────────────────────────────
func handle(client: WebSocketPeer, data: Dictionary):
	match data.get("action", ""):
		"create_lobby": _handle_create(client, data)
		"join_lobby":   _handle_join(client, data)
		"leave_lobby":  _handle_leave(client, data)
		"create_game":  _handle_start(client, data)

# ─────────────────────────────────────────
# UTILITAIRES LOCAUX
# ─────────────────────────────────────────
func generer_lobby_id() -> String:
	var alphabet = "ABCDEFGHIJKLMNPQRSTUVWXYZ123456789"
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
func _handle_create(client: WebSocketPeer, data: Dictionary):
	var serveur = get_parent()
	var player_id = serveur.get_player_id(client)
	var nom         = data.get("nom", "Partie sans nom")
	var max_joueurs = data.get("max_joueurs", 4)
	var prive       = data.get("prive", false)
	var dur_index = data.get("dur_index", 1)
	var dur_seconds = [60, 120, 180, 300][dur_index]
	var lobby_id    = generer_code_unique()

	if player_id == null:
		serveur.send_to_client(client, {
			"action_reply": "create_lobby",
			"status": "error",
			"message": "Vous devez être connecté pour créer un lobby."
		})
		return


	serveur.lobbies[lobby_id] = {
		"nom":         nom,
		"host":        client,
		"joueurs":     [client],
		"max_joueurs": max_joueurs,
		"prive":       prive,
		"etat":        "EN_ATTENTE",
		"timer" : dur_seconds,
		"timer_actif": true
	}

	print("[LOBBY] Lobby créé : ", lobby_id, " par joueur ", player_id)

	serveur.lobbies[lobby_id]["timer"] = dur_seconds
	serveur.lobbies[lobby_id]["timer_actif"] = true
	
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
	
func tick_lobbies():
	var serveur = get_parent()
	var lobby_ids = serveur.lobbies.keys().duplicate()
	for lobby_id in lobby_ids:
		if not serveur.lobbies.has(lobby_id):
			continue
			
		var lobby = serveur.lobbies[lobby_id]
		if not lobby.get("timer_actif", false):
			continue
		
		lobby["timer"] -= 1
		
		serveur.broadcast_lobby(lobby_id, {
			"action_reply": "lobby_tick",
			"type": "timer_sync",
			"remaining": lobby["timer"]
		})
		
		if lobby["timer"]%10 == 0 or lobby["timer"] <=5:
			print("[LOBBY] Timer ", lobby_id, " : ", lobby["timer"], "s restantes")
		
		# TImer expiré
		if lobby["timer"] <= 0:
			lobby["timer_actif"] = false
			if lobby["joueurs"].size() < 2:
				# Host seul -> dissous le lobby
				for joueur in lobby["joueurs"]:
					serveur.send_to_client(joueur,{
						"action_reply": "leave_lobby",
						"type": "lobby_dissous",
						"message": "Temps écoulé, lobby dissous."
				})
				serveur.lobbies.erase(lobby_id)
			else:
				lobby["etat"] = "EN_JEU"
				var host = lobby["host"]
				$"../FlaskManager".send("create_game", "/game/create", {
					"player_id" : serveur.active_sessions.get(host, null),
					"player_type": "registered"
				}, host, {"lobby_id": lobby_id})

# ─────────────────────────────────────────
# JOIN LOBBY
# ─────────────────────────────────────────
func _handle_join(client: WebSocketPeer, data: Dictionary):
	var serveur   = get_parent()
	var identifiant = get_identifiant(client)
	var lobby_id  = data.get("lobby_id", "").strip_edges().to_upper()

	if identifiant == "":
		serveur.send_to_client(client, {
			"action_reply": "join_lobby",
			"type": "joueur_non_connectee",
			"status": "error",
			"message": "Vous devez être connecté pour rejoindre un lobby."
		})
		return
		
	if lobby_id.length() != 6:
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
	print("[LOBBY] Joueur ", identifiant, " a rejoint le lobby ", lobby_id)

	var liste_joueurs = _get_liste_joueurs(lobby)

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
func _handle_leave(client: WebSocketPeer, data: Dictionary):
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

	# Si c'est le host qui guitte -> dissout le lobby
	if lobby["host"] == client:
		# Notifie tousl les autres joueurs
		for joueur in lobby["joueurs"]:
			if joueur != client:
				serveur.send_to_client(joueur,{
					"action_reply": "leave_lobby",
					"type": "lobby_dissous",
					"status": "success",
					"message": "Le host a quitté le lobby."
				})
		serveur.lobbies.erase(lobby_id)
		print("[LOBBY] lobby ",lobby_id," dissous - host parti")
		return
	if lobby["joueurs"].size() == 0:
		serveur.lobbies.erase(lobby_id)
		print("[LOBBY] Lobby ", lobby_id, " dissous (vide)")
		return


	lobby["joueurs"].erase(client)
	var liste_joueurs = _get_liste_joueurs(lobby)

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
func _handle_start(client: WebSocketPeer, data: Dictionary):
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

	# Guard: prevent starting a game that already started (double create_game protection)
	if lobby.get("etat", "EN_ATTENTE") == "EN_JEU":
		print("[LOBBY] IGNORE create_game: lobby ", lobby_id, " is already EN_JEU")
		return

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

	# Mark as in-game immediately to block any concurrent second call
	lobby["etat"] = "EN_JEU"
	print("[LOBBY] Partie lancée dans le lobby ", lobby_id)

	$"../FlaskManager".send("create_game", "/game/create", {
		"player_id": player_id,
		"player_type": "registered"
	}, client, {"lobby_id": lobby_id})
	
func get_identifiant(client) -> String:
	var serveur = get_parent()
	var player_id = serveur.active_sessions.get(client, null)
	if player_id != null:
		return str(player_id)
	
	var guest_id = serveur.guest_sessions.get(client, null)
	if guest_id != null:
		return str(guest_id)
	return ""
	
func _get_liste_joueurs(lobby: Dictionary) -> Array:
	var serveur = get_parent()
	var liste = []
	
	for joueur in lobby["joueurs"]:
		var player_id = serveur.active_sessions.get(joueur, null)
		var guest_id = serveur.guest_sessions.get(joueur, null)
		var found_guest = serveur.guest_sessions.get(joueur, null)

		if player_id != null:
			var nickname = serveur.active_nicknames.get(joueur, "Joueur " + str(player_id))
			liste.append({
				"id": player_id,
				"type": "registered",
				"nickname": nickname
			})
		elif guest_id != null:
			var nickname = serveur.guest_nicknames.get(joueur, "Invité" + str(guest_id))
			liste.append({
				"id": guest_id,
				"type": "guest",
				"nickname": nickname
			})
		else:
			liste.append({
				"id": -1,
				"type": "inconnu",
				"nickname": "Inconnu"
			})
	return liste
	
	
func get_lobby_id_of(client: WebSocketPeer) -> String:
	var serveur = get_parent()
	for lobby_id in serveur.lobbies.keys():
		if client in serveur.lobbies[lobby_id]["joueurs"]:
			return lobby_id
	return ""
