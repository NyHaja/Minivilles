extends Control

func _ready():
	$Content/HBoxContainer2/BtnRetour.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if PlayerData.is_logged_in():
				get_tree().change_scene_to_file("res://scene/Ecran principale/connected_screen.tscn")
			else:
				get_tree().change_scene_to_file("res://scene/Ecran principale/guest_screen.tscn"))
