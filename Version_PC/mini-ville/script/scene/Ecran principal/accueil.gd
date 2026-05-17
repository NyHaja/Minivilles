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

@onready var popup_guest = $PanelPseudoGuest

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
	popup_guest.hide()
	
	popup_login.on_back.connect(_on_popup_back)
	popup_rule.on_back.connect(_on_popup_back)
	popup_setting.on_back.connect(_on_popup_back)
	
	# Connecte tous les boutons
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
	$PanelPseudoGuest.hide()
	popup_rule.show()
	
func affiche_parametre():
	SoundManager.play_click()
	$gameMode.hide()
	$PanelPseudoGuest.hide()
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
	$gameMode.hide()
	#popup_guest.get_node("LineEdit").text = ""  # vide le champ
	popup_guest.show()
	
func _on_guest_ok_pressed():
	var nickname = $PanelPseudoGuest/VBoxContainer/LineEdit.text.strip_edges()
	if nickname == "":
		return  # ignore si vide
	$gameMode.hide()
	GuestHandler.creer_guest(nickname)
	popup_guest.queue_free()


func _on_guest_fermer_pressed():
	popup_guest.hide()
	$gameMode.show()
	
func _on_popup_back():
	$gameMode.show()
	
