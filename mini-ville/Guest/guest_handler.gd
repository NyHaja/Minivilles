extends Node

# ----------------------------------------------------------------
# VARIABLES
# ----------------------------------------------------------------
var guest_id = -1
var guest_nickname := ""
var est_guest := false

# ----------------------------------------------------------------
# INITIALISATION
# ----------------------------------------------------------------
func _ready() -> void:
	NetworkManager.message_recu.connect(_on_message)

# ----------------------------------------------------------------
# DISPATCH DES MESSGES RÉÇUS
# ----------------------------------------------------------------
func _on_message(data: Dictionary):
	match data.get("action_reply", ""):
		"guest_player": _on_guest_cree(data)
		"authentification":
			if data.get("status") == "success":
				reset() # remet est_guest à false  quand login réussi
		
# ----------------------------------------------------------------
# ACTIONS JOUEUR -> SERVEUR
# ----------------------------------------------------------------
func creer_guest(nickname: String):
	if nickname.strip_edges() == "":
		print("[GuestHandler] Nickname vide")
		return
		
	NetworkManager.envoyer({
		"action": "guest_player",
		"nickname": nickname
	})
	
func rejoindre_lobby_guest(lobby_id: String):
	if not est_guest:
		print("[GuestHandler] Pas en mode guest")
		return
	NetworkManager.envoyer({
		"action": "join_lobby",
		"guest_id": guest_id,
		"lobby_id": lobby_id
	})
	
func jouer_local():
	# Pas besoin de serveur - lancer directement la scène locale
	get_tree().change_scene_to_file("res://main_client.tscn")	# A MODIFIEEEEEEEEEEEERRRRRR

# ----------------------------------------------------------------
# RÉPONSES SERVEUR -> CLIENT
# ----------------------------------------------------------------
func _on_guest_cree(data: Dictionary):
	if data.get("status") == "success":
		var raw_id = data.get("guest_id", null)
		if raw_id == null:
			print("[GuestHandler] Erreur : guest_id manquant dans la réponse")
			return
		guest_id = int(raw_id)  # ← conversion explicite
		# Sauvegarder dans NetworkManager
		
		guest_nickname = data.get("nickname", "")
		est_guest = true
		NetworkManager.set_guest(guest_id, guest_nickname)
		print("[GuestHandler] Guest créé :", guest_nickname, " (id : ", guest_id, ")")
		# Aller vers l'écran de rejoindre lobby
		get_tree().change_scene_to_file("res://scene/Ecran principale/guest_screen.tscn")
	else:
		var raison = data.get("message", "Erreur inconnue")
		print("[GuestHandler] Erreur création guest : ", raison)
		# TODO : afficher l'erreur dans l'UI
		
# ----------------------------------------------------------------
# UTILITAIRES
# ----------------------------------------------------------------
func est_mode_guest() -> bool:
	return est_guest
	
func get_guest_id() -> int:
	return guest_id
	
func get_guest_nickname() -> String:
	return guest_nickname
	
func reset():
	guest_id = -1
	guest_nickname = ""
	est_guest = false
