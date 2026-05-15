extends Control

signal on_back

var _traitement_en_cours := false  # garde-fou anti-double appel
const popup_forgot = preload("res://scene/popup/forgot_password.tscn")

func _ready() -> void:
	if not $Panel/VBoxContainer/backbtn.pressed.is_connected(_on_back_pressed):
		$Panel/VBoxContainer/backbtn.pressed.connect(_on_back_pressed)

	var btn_con = get_node_or_null("%connexionbtn")
	if btn_con:
		btn_con.pressed.connect(_on_connexionbtn_pressed)

	var btn_insc = get_node_or_null("%inscriptionbtn")
	if btn_insc:
		btn_insc.pressed.connect(bouton_inscription)

	# Un seul signal suffit — _on_network_message_received gère tout
	if not NetworkManager.message_recu.is_connected(_on_network_message_received):
		NetworkManager.message_recu.connect(_on_network_message_received)

	# 4. ÉCOUTER LE NETWORK MANAGER
	if NetworkManager.has_signal("auth_finished"):
		if not NetworkManager.auth_finished.is_connected(_on_auth_result):
			NetworkManager.auth_finished.connect(_on_auth_result)


func _on_back_pressed() -> void:
	SoundManager.play_click()
	on_back.emit()
	hide()


func bouton_inscription():
	SoundManager.play_click()
	var popup_path = "res://scene/popup/popup_signin.tscn"
	if ResourceLoader.exists(popup_path):
		var popup_signin = load(popup_path).instantiate()
		get_tree().root.add_child(popup_signin)
		popup_signin.on_back.connect(func(): show())
		hide()
	else:
		show_error(tr("Erreur : Scène popup introuvable."))


func _on_connexionbtn_pressed() -> void:
	var mail_node = get_node_or_null("%mail_con")
	var mdp_node  = get_node_or_null("%mdp_con")

	get_node_or_null("%errorMessageLogin").hide()

	if not mail_node or not mdp_node:
		return

	var mail = mail_node.text.strip_edges()
	var mdp  = mdp_node.text

	if mail == "" or mdp == "":
		show_error(tr("Veuillez remplir tous les champs."))
		return

	SoundManager.play_click()
	_traitement_en_cours = false  # reset avant envoi
	Client.authentication(mail, mdp)


func _on_network_message_received(data: Dictionary):
	if data.get("action_reply") != "authentification":
		return
	if _traitement_en_cours:  # ignore le double appel
		return
	_traitement_en_cours = true
	_on_auth_result(data.get("status", "error") == "success")


func _on_auth_result(success: bool) -> void:
	if not is_inside_tree():
		return

	if success:
		show_success(tr("Connexion réussie !"))

		# On attend 1 seconde avant de changer de scène
		await get_tree().create_timer(1.0).timeout

		if not is_inside_tree():
			return

		hide()
		queue_free()  # supprime le popup de root avant de changer de scène
		get_tree().change_scene_to_file("res://scene/Ecran principale/connected_screen.tscn")
	else:
		_traitement_en_cours = false  # permet de réessayer
		show_error(tr("Identifiants incorrects."))


func show_error(msg: String):
	var node = get_node_or_null("%errorMessageLogin")
	if node:
		node.text = msg
		node.add_theme_color_override("font_color", Color.RED)
		node.show()

func show_success(msg: String):
	var node = get_node_or_null("%errorMessageLogin")
	if node:
		node.text = msg
		node.add_theme_color_override("font_color", Color.GREEN)
		node.show()


func _on_forgot_password_pressed() -> void:
	var instance_popup = popup_forgot.instantiate()
	add_child(instance_popup)
