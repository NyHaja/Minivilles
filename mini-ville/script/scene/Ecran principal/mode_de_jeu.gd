extends Control

func _ready():
	$BtnRetour/Fleche.pressed.connect(func():
		if NetworkManager.est_connecte():
			get_tree().change_scene_to_file("res://scene/Ecran principale/connected_screen.tscn")
		else:
			get_tree().change_scene_to_file("res://scene/Ecran principale/guest_screen.tscn"))
