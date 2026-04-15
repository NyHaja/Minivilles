extends Control

func _ready():
	$BtnRetour/Fleche.pressed.connect(func():
		if PlayerData.is_logged_in():
			get_tree().change_scene_to_file("res://scene/Ecran principale/connected_screen.tscn")
		else:
			get_tree().change_scene_to_file("res://scene/Ecran principale/guest_screen.tscn"))
