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
	
func affiche_popup_rule():
	SoundManager.play_click()
	$gameMode.hide()
	popup_rule.show()
	
func affiche_parametre():
	SoundManager.play_click()
	$gameMode.hide()
	popup_setting.show()
