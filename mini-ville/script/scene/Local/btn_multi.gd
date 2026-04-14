extends Button


func _ready():
	mouse_entered.connect(_on_hover_start)
	mouse_exited.connect(_on_hover_end)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	pressed.connect(_on_pressed)


func _on_hover_start():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.3, 1.3, 1.3), 0.1)


func _on_hover_end():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.1)


func _on_button_down():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0.7, 0.7, 0.7), 0.05)


func _on_button_up():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.1)


func _on_pressed():
	get_tree().change_scene_to_file("res://scene/Multijoueur/choix_lobby.tscn")
