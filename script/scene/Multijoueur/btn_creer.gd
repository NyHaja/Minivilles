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
	var lobby = get_tree().current_scene
	get_tree().set_meta("tour_duration_index", lobby.dur_index)
	get_tree().set_meta("nb_joueurs", lobby.nb_joueurs)
	var code = _generate_code()
	get_tree().set_meta("lobby_code", code)
	LobbyManager.add_lobby(code, lobby.is_private)
	get_tree().change_scene_to_file("res://scenes/ui/attente_lobby.tscn")


func _generate_code() -> String:
	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var code = ""
	for i in 6:
		code += chars[randi() % chars.length()]
	return code
