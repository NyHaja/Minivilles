extends Control

# Popup login
var popup_login_scene = preload("res://scene/popup/popup_login.tscn")
var popup_login

# Popup rules and settings
var pop_rule_scene = preload("res://scene/popup/rules_panel.tscn")
var popup_rule

var pop_setting_scene = preload("res://scene/popup/popup_parametres.tscn")
var popup_setting


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	popup_login = popup_login_scene.instantiate()
	popup_rule = pop_rule_scene.instantiate()
	popup_setting = pop_setting_scene.instantiate()
	
	add_child(popup_login)
	add_child(popup_rule)
	add_child(popup_setting)
	
	popup_setting.hide()
	popup_rule.hide()

	popup_rule.on_back.connect(_on_popup_back)
	popup_setting.on_back.connect(_on_popup_back)
	
	$Header/header/rulebtn/TextureButton.pressed.connect(affiche_popup_rule)
	$Header/header/settingbtn/TextureButton.pressed.connect(affiche_parametre)

	$gameMode/playbtn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scene/Multijoueur/choix_lobby.tscn"))


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
	
func _on_popup_back():
	$gameMode.show()
	
#------------ BODY ----------------
	
	

	
	
