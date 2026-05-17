extends Control

# Popup rules and settings
var pop_rule_scene = preload("res://scene/popup/rules_panel.tscn")
var popup_rule

var pop_setting_scene = preload("res://scene/popup/popup_parametres.tscn")
var popup_setting


func _ready() -> void:
	popup_rule = pop_rule_scene.instantiate()
	popup_setting = pop_setting_scene.instantiate()
	
	add_child(popup_rule)
	add_child(popup_setting)
	
	popup_setting.hide()
	popup_rule.hide()
	
	$Header/header/rulebtn/TextureButton.pressed.connect(affiche_popup_rule)
	$Header/header/settingbtn/TextureButton.pressed.connect(affiche_parametre)
	
	$gameMode/starttbtn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scene/Ecran principale/mode_de_jeu.tscn"))
		
	$gameMode/loginbtn.pressed.connect(func():
		var popup_login = load("res://scene/popup/popup_login.tscn").instantiate()
		get_tree().root.add_child(popup_login)
		popup_login.on_back.connect(func(): popup_login.queue_free()))

	
func affiche_popup_rule():
	SoundManager.play_click()
	$gameMode.hide()
	popup_rule.show()
	
func affiche_parametre():
	SoundManager.play_click()
	$gameMode.hide()
	popup_setting.show()
