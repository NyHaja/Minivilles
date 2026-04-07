extends Control

# Popup login
var popup_login_scene = preload("res://scenes/popup_login.tscn")
var popup_login

var pop_rule_scene = preload("res://scenes/rules_panel.tscn")
var popup_rule

#Mode as Guest
var asGuest = preload("res://scenes/Ecran principale/guest_screen.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	popup_login = popup_login_scene.instantiate()
	add_child(popup_login)
	popup_login.hide()
	
	popup_login.on_back.connect(_on_popup_back)
	
	$gameMode/loginbtn.pressed.connect(affiche_popup_login)
	
	popup_rule = pop_rule_scene.instantiate()
	add_child(popup_rule)
	popup_rule.hide()
	
	popup_rule.on_back.connect(_on_popup_back)
	
	$Header/header/rulebtn/TextureButton.pressed.connect(affiche_popup_rule)

# Musique de fond du jeu
	SoundManager.music_player
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#------------- HEADER --------------

# bouton pour afficher les règles
func affiche_popup_rule():
	SoundManager.play_click()
	$gameMode.hide()
	popup_rule.show()
	
func affiche_parametre() -> void:
	SoundManager.play_click()
	
	
#------------ BODY ----------------

# bouton login pour s'authentifier
func affiche_popup_login() -> void:
	SoundManager.play_click()
	$gameMode.hide()
	popup_login.show()
	
	
#bouton pour jouer en mode invité
func guest_mode() -> void:
	SoundManager.play_click()
	get_tree().change_scene_to_packed(asGuest)
	
func _on_popup_back():
	$gameMode.show()
