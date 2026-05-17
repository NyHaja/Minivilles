extends Node

signal joueur_mis_a_jour(joueurs: Array)
signal lobby_creer_signal(lobby_id: String)

# ----------------------------------------------------------------
# VARIABLES
# ----------------------------------------------------------------

var lobby_id := ""		# déclare une variable de type String
var est_host := false	# déclare une variable de type boolean initalement false
var joueurs := []		# déclare un tableau vide
var _game_starting := false  # garde contre les double-envois de create_game

# ----------------------------------------------------------------
# INITIALISATION
# ----------------------------------------------------------------
func _ready():
	NetworkManager.message_recu.connect(_on_message)
	
func _on_message(data : Dictionary):
	match data.get("type", ""):
		"lobby_cree":			_on_lobby_cree(data)
		"lobby_mis_a_jour":		_on_lobby_mis_a_jour(data)
		"game_demarre":			_on_game_demarre(data)
		"lobby_erreur":			_on_lobby_erreur(data)
		
# ----------------------------------------------------------------
# ACTIONS JOUEUR -> SERVEUR
# ----------------------------------------------------------------
func creer_lobby(nom: String, max_joueurs: int, dur_index: int = 1):
	# Bloque si mode guest
	if NetworkManager.est_guest():
		print("[lobbyHandler] Un guest ne peut pas créer un lobby")
		return 
		
	NetworkManager.envoyer({
		"action": "create_lobby",
		"token":NetworkManager.get_token(),
		"nom": nom,
		"max_joueurs": max_joueurs,
		"dur_index":   dur_index
	})

func rejoindre_lobby(code: String):
	NetworkManager.envoyer({
		"action": "join_lobby",
		"token": NetworkManager.get_token(),
		"lobby_id": code
	})
	
func quitter_lobby():
	if lobby_id == "":
		return
	NetworkManager.envoyer({
		"action": "leave_lobby",
		"token": NetworkManager.get_token(),
		"lobby_id": lobby_id
	})
	reset()
	
func lancer_partie():
	if _game_starting:
		print("[LobbyHandler] Partie déjà en cours de lancement, ignoré.")
		return
	if not est_host:
		print("[LobbyHandler] Seul le host peut lancer la partie")
		return

	if joueurs.size() < 2:
		print("[LobbyHandler] Il faut au moins 2 joueurs")
		return

	_game_starting = true
	NetworkManager.envoyer({
		"action":"create_game",
		"token": NetworkManager.get_token(),
		"lobby_id": lobby_id
	})
	
	
# ----------------------------------------------------------------
# RÉPONSES SERVEUR -> CLIENT
# ----------------------------------------------------------------
func _on_lobby_cree(data: Dictionary):
	var d = data.get("data", {})
	lobby_id = d.get("lobby_id", "")
	est_host = true
	joueurs = d.get("joueurs", [])
	print("[Lobbyhandler] Lobby créé : ", lobby_id)
	lobby_creer_signal.emit(lobby_id)
	# TODO : afficher le code loby dans l'UI
	
func _on_lobby_mis_a_jour(data: Dictionary):
	var d = data.get("data", {})
	joueurs = d.get("joueurs", [])
	lobby_id = d.get("lobby_id", lobby_id)
	print("[LobbyHandler] Joueur : ", joueurs)
	joueur_mis_a_jour.emit(joueurs)
	# TODO : rafraîchir la liste des joueurs dans l'UI
	
func _on_game_demarre(data: Dictionary):
	var d = data.get("data", {})
	var game_id = d.get("game_id", 0)
	var ordre_joueurs = d.get("ordre_joueurs", [])
	
	get_tree().set_meta("game_id", game_id)
	get_tree().set_meta("ordre_joueurs", ordre_joueurs)
	print("[LobbyHandler] Partie lancer : ", game_id)
	get_tree().change_scene_to_file("res://scene/Prototype/V3/jeu_multi.tscn") # A MODIFIER =============================
	
func _on_lobby_erreur(data: Dictionary):
	var message = data.get("message", "Erreur inconnue")
	print("[LobbyHandler] Erreur : ", message)
	# TODO : afficher l'erreur dans l'UI
	
# ----------------------------------------------------------------
# UTILITAIRES
# ----------------------------------------------------------------	
func reset():
	lobby_id = ""
	est_host = false
	joueurs = []
	_game_starting = false
	
	
func get_lobby_id() -> String:
	return lobby_id
	
func  get_joueurs() -> Array:
	return joueurs
	
func is_host() -> bool:
	return est_host
