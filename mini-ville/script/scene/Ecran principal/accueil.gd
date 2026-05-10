extends Control

# Popup login
var popup_login_scene = preload("res://scene/popup/popup_login.tscn")
var popup_login

# Popup rules and settings
var pop_rule_scene = preload("res://scene/popup/rules_panel.tscn")
var popup_rule

var pop_setting_scene = preload("res://scene/popup/popup_parametres.tscn")
var popup_setting

#Mode as Guest
var asGuest = preload("res://scene/Ecran principale/guest_screen.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	NetworkManager.lancer_connexion_reseau()
	popup_login = popup_login_scene.instantiate()
	popup_rule = pop_rule_scene.instantiate()
	popup_setting = pop_setting_scene.instantiate()
	
	add_child(popup_login)
	add_child(popup_rule)
	add_child(popup_setting)
	
	popup_setting.hide()
	popup_rule.hide()
	popup_login.hide()
	
	popup_login.on_back.connect(_on_popup_back)
	popup_rule.on_back.connect(_on_popup_back)
	popup_setting.on_back.connect(_on_popup_back)
	
	$Header/header/rulebtn/TextureButton.pressed.connect(affiche_popup_rule)
	$gameMode/loginbtn.pressed.connect(affiche_popup_login)
	$Header/header/settingbtn/TextureButton.pressed.connect(affiche_parametre)
# Musique de fond du jeu
	#SoundManager.music_player

#------------- HEADER --------------

# bouton pour afficher les règles
func affiche_popup_rule():
	SoundManager.play_click()
	$gameMode.hide()
	popup_rule.show()
	
func affiche_parametre():
	SoundManager.play_click()
	$gameMode.hide()
	popup_setting.show()
	
	
#------------ BODY ----------------

# bouton login pour s'authentifier
func affiche_popup_login() -> void:
	SoundManager.play_click()
	$gameMode.hide()
	popup_login.show()
	
	
#bouton pour jouer en mode invité
func guest_mode() -> void:
	SoundManager.play_click()
	#get_tree().change_scene_to_packed(asGuest)
	_afficher_popup_nickname()
	
func _afficher_popup_nickname():
# Popup simple avec un champ texte pour le pseudo
	var dialog = AcceptDialog.new()
	dialog.title = "Mode invité"

	var vbox = VBoxContainer.new()
	var label = Label.new()
	label.text = "Entrez votre pseudo :"
	var input = LineEdit.new()
	input.placeholder_text = "Pseudo"
	input.max_length = 20

	vbox.add_child(label)
	vbox.add_child(input)
	dialog.add_child(vbox)

	add_child(dialog)
	dialog.popup_centered()

	dialog.confirmed.connect(func():
		var nickname = input.text.strip_edges()
		if nickname == "":
			return
		$gameMode.hide()
		GuestHandler.creer_guest(nickname)
		dialog.queue_free()
	)
	dialog.canceled.connect(func(): dialog.queue_free())
	
func _on_popup_back():
	$gameMode.show()
	
