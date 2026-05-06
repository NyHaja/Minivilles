extends Control

signal on_back

var pop_setting_scene = preload("res://scene/popup/popup_parametres.tscn")
var popup_setting

func _ready():
	# print("[choix_lobby] _ready() appelé depuis : ", get_stack())
	$Content/gameMode/BtnCreerWrap/BtnCreer.pressed.connect(func(): get_tree().change_scene_to_file("res://scene/Multijoueur/creation_lobby.tscn"))
	$Content/gameMode/BtnRejoindreWrap/BtnRejoindre.pressed.connect(func(): get_tree().change_scene_to_file("res://scene/Multijoueur/rejoindre_lobby.tscn"))
	$HBoxContainer2/BtnRetour/BtnBack.pressed.connect(func():
		get_tree().change_scene_to_file("res://scene/Ecran principale/mode_de_jeu.tscn"))
		
	popup_setting = pop_setting_scene.instantiate()
	add_child(popup_setting)
	popup_setting.hide()

	if not $HBoxContainer2/VBoxContainer/BtnParametres.pressed.is_connected(affiche_parametre):
		$HBoxContainer2/VBoxContainer/BtnParametres.pressed.connect(affiche_parametre)
	
func affiche_parametre():
	SoundManager.play_click()
	#$Content/gameMode.hide()
	popup_setting.show()
