extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	NetworkManager.message_recu.connect(_on_message)
	NetworkManager.connecte.connect(_on_connecte)
	
func _on_connecte():
	NetworkManager.envoyer({
		"action": "authentification",
		"email": "jaja@test.com",
		"password": "jaja123"
	})

func _on_btn_rejoindre_pressed():
	var code = $LineEdit.text.strip_edges().to_upper()
	
	if code.length() != 6:
		print("[JoinLobby] Code invalide - doit faire 6 caractères")
		return
	$HBoxContainer/rejoindre.disabled = true
	LobbyHandler.rejoindre_lobby(code)
	
func _on_btn_retour_pressed():
	get_tree().change_scene_to_file("res://main_client.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_message(data: Dictionary):
	match  data.get("type", ""):
		"lobby_mis_a_jour":
			_on_lobby_rejoint(data)
		"game_demarre":
			get_tree().change_scene_to_file("res://main_client.tscn")
	
	# Erreur
	if data.get("action_reply") == "join_lobby" and data.get("status") == "error":
		$LabelErreur.text = data.get("message", "Erreur inconnue")
		#print("[JoinLobby] Erreur : ", message)
		$HBoxContainer/rejoindre.disabled = false

func _on_lobby_rejoint(data: Dictionary):
	#var d = data.get("data", {})
	#var joueur = d.get("joueur", [])
	#print("[JoinLobby] Lobby rejoint ! Joueurs : ", joueur)
	# TODO : affiche la liste des joueurs dans l'UI
	# TODO  : change de scène vers la salle d'attente
	get_tree().change_scene_to_file("res://Lobby/Lobby.tscn")
