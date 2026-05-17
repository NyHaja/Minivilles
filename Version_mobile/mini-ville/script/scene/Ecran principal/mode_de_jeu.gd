extends Control

# Popup rules and settings
var pop_rule_scene = preload("res://scene/popup/rules_panel.tscn")
var popup_rule

var pop_setting_scene = preload("res://scene/popup/popup_parametres.tscn")
var popup_setting


func _ready():
	$BtnRetour/Fleche.pressed.connect(func():
		if NetworkManager.est_connecte():
			get_tree().change_scene_to_file("res://scene/Ecran principale/connected_screen.tscn")
		else:
			get_tree().change_scene_to_file("res://scene/Ecran principale/guest_screen.tscn"))
			
			
	popup_setting = pop_setting_scene.instantiate()
	
	add_child(popup_setting)
	
	popup_setting.hide()
	
	$VBoxContainer/BtnParametres.pressed.connect(affiche_parametre)

	
func affiche_parametre():
	SoundManager.play_click()
	#$gameMode.hide()
	popup_setting.show()
