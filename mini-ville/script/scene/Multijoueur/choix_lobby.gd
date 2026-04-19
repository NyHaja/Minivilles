extends Control

signal on_back

func _ready():
	$Content/BtnCreerWrap/BtnCreer.pressed.connect(func(): get_tree().change_scene_to_file("res://scene/Multijoueur/creation_lobby.tscn"))
	$Content/BtnRejoindreWrap/BtnRejoindre.pressed.connect(func(): get_tree().change_scene_to_file("res://scene/Multijoueur/rejoindre_lobby.tscn"))
	$Content/HBoxContainer2/BtnRetour/BtnBack.pressed.connect(func():
		get_tree().change_scene_to_file("res://scene/Ecran principale/mode_de_jeu.tscn"))
