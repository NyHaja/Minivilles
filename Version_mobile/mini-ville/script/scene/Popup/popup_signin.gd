extends Control

signal on_back

# ------------------------------------
#	INITIALISATION
# ------------------------------------
var popup_login_scene = preload("res://scene/popup/popup_login.tscn")
var popup_login
func _ready() -> void:
	# 1. Connexion des boutons de navigation
	$Panel/VBoxContainer/backbtn.pressed.connect(_on_back_pressed)
	popup_login = popup_login_scene.instantiate()

	$Panel/Panelsignin/MarginContainer/Boxconnexion/VBoxContainer2/Button2.pressed.connect(_on_back_pressed)
	
	# 2. Connexion du bouton d'inscription (Vérifie le nom dans ton arbre)
	var btn_insc = %inscrire 
	if btn_insc:
		btn_insc.pressed.connect(_on_inscrire_pressed)
	
	# 3. ÉCOUTER LES SIGNAUX FACTORISÉS (Depuis l'Autoload Network)
	NetworkManager.register_finished.connect(_on_registration_result)

func _on_back_pressed() -> void:
	on_back.emit()
	queue_free()

# ------------------------------------
#	ACTIONS D'ENVOI
# ------------------------------------
func _on_inscrire_pressed() -> void:
	var pseudo = %pseudo.text.strip_edges()
	var mail = %mail.text.strip_edges()
	var mdp = %mdp.text
	var mdp_confirm = %mdp_conf.text
	
	%errorMessage.hide()

	# Vérifications locales de sécurité (traduites)
	if pseudo == "" or mail == "" or mdp == "":
		show_error(tr("Veuillez remplir tous les champs."))
		return
	if not is_valid_email(mail):
		show_error(tr("Le format de l'email est invalide."))
		return
	if mdp.length() < 6:
		show_error(tr("Le mot de passe doit faire au moins 6 caractères."))
		return
	if mdp != mdp_confirm:
		show_error(tr("Les mots de passe ne correspondent pas !"))
		return
		
	show_info(tr("Inscription en cours"))
	# On utilise l'Autoload Client pour envoyer la requête
	Client.send_register_request(pseudo, mdp, mail, "")

# ------------------------------------
#	TRAITEMENT DES RÉSULTATS (Factorisé)
# ------------------------------------

# Appelé quand le NetworkManager a fini de traiter une inscription
func _on_registration_result(success: bool, message: String) -> void:
	if success:
		show_success(tr("Compte créé !\nVeuillez vous connecter"))
		await get_tree().create_timer(1.5).timeout
		# Retour à l'écran de login principal
		popup_login.show()

	else:
		# On traduit le message d'erreur venu du serveur (ex: "Ce pseudo est déjà utilisé.")
		show_error(tr(message))



# ------------------------------------
#	MESSAGES UI (Couleurs)
# ------------------------------------
func show_error(msg: String):
	%errorMessage.text = msg
	%errorMessage.add_theme_color_override("font_color", Color.RED)
	%errorMessage.show()

func show_info(msg: String):
	%errorMessage.text = msg
	%errorMessage.add_theme_color_override("font_color", Color.WHITE)
	%errorMessage.show()

func show_success(msg: String):
	%errorMessage.text = msg
	%errorMessage.add_theme_color_override("font_color", Color.GREEN)
	%errorMessage.show()

# ------------------------------------
#	VALIDATIONS
# ------------------------------------
func is_valid_email(email: String) -> bool:
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")
	return regex.search(email) != null
