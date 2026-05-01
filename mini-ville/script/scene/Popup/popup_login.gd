extends Control

signal on_back

# ------------------------------------
#	INITIALISATION
# ------------------------------------
func _ready() -> void:
	# 1. Connexion du bouton de retour
	if has_node("Panel/VBoxContainer/backbtn"):
		$Panel/VBoxContainer/backbtn.pressed.connect(_on_back_pressed)
	
	# 2. Connexion du bouton de connexion (Login)
	var btn_con = get_node_or_null("%connexionbtn")
	if btn_con:
		btn_con.pressed.connect(_on_connexionbtn_pressed)
	
	# 3. Connexion du bouton qui ouvre l'inscription
	var btn_insc = get_node_or_null("%inscriptionbtn")
	if btn_insc:
		btn_insc.pressed.connect(bouton_inscription)

	# 4. ÉCOUTER LE NETWORK MANAGER
	# On s'assure d'écouter les signaux du NetworkManager (Singleton)
	if NetworkManager.has_signal("auth_finished"):
		if not NetworkManager.auth_finished.is_connected(_on_auth_result):
			NetworkManager.auth_finished.connect(_on_auth_result)

# ------------------------------------
#	NAVIGATION & UI
# ------------------------------------
func _on_back_pressed() -> void:
	if typeof(SoundManager) != TYPE_NIL:
		SoundManager.play_click()
	on_back.emit()
	hide()

func bouton_inscription():
	if typeof(SoundManager) != TYPE_NIL:
		SoundManager.play_click()
	
	var popup_path = "res://scene/popup/popup_signin.tscn"
	if ResourceLoader.exists(popup_path):
		var popup_signin = load(popup_path).instantiate()
		get_tree().root.add_child(popup_signin)
		popup_signin.on_back.connect(func(): show())
		hide()
	else:
		show_error("Erreur : Scène popup introuvable.")

# ------------------------------------
#	LOGIQUE DE CONNEXION
# ------------------------------------
func _on_connexionbtn_pressed() -> void:
	var mail_node = get_node_or_null("%mail_con")
	var mdp_node = get_node_or_null("%mdp_con")
	var err_node = get_node_or_null("%errorMessageLogin")
	
	if err_node:
		err_node.hide()

	if not mail_node or not mdp_node:
		return

	var mail = mail_node.text.strip_edges()
	var mdp = mdp_node.text
	
	# GESTION DES CASES VIDES
	if mail == "" or mdp == "":
		show_error("Veuillez remplir tous les champs.")
		return
	
	if typeof(SoundManager) != TYPE_NIL:
		SoundManager.play_click()
		
	# Envoi de la requête au serveur (sans message de chargement)
	Client.authentication(mail, mdp)

# ------------------------------------
#	TRAITEMENT DES RÉSULTATS
# ------------------------------------

func _on_auth_result(success: bool, _message: String) -> void:
	# SECURITÉ : On vérifie si le nœud est toujours dans l'arbre avant d'agir
	if not is_inside_tree():
		return

	if success:
		show_success("Connexion réussie !")
		# On attend 1 seconde avant de changer de scène
		
		await get_tree().create_timer(1.0).timeout
		
		if not is_inside_tree():
			return
		
		# Cache Et supprime le popup avant de changer de scene
		hide()
		queue_free()
		# Vérification après l'attente (le nœud peut avoir été quitté durant l'attente)	
		get_tree().change_scene_to_file("res://scene/Ecran principale/connected_screen.tscn")
	else:
		# GESTION DES IDENTIFIANTS INCORRECTS
		# On affiche systématiquement le message d'erreur générique
		show_error("Identifiants incorrects.")



# ------------------------------------
#	UTILITAIRES DE MESSAGES SÉCURISÉS
# ------------------------------------
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
