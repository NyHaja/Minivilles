extends Button


func _ready():
	pressed.connect(_on_pressed)


func _on_pressed():
	var lobby = get_tree().current_scene
	get_tree().set_meta("tour_duration_index", lobby.dur_index)
	get_tree().set_meta("nb_joueurs", lobby.nb_joueurs)
	var code = _generate_code()
	get_tree().set_meta("lobby_code", code)
	LobbyManager.add_lobby(code, lobby.is_private)
	get_tree().change_scene_to_file("res://scene/Multijoueur/attente_lobby.tscn")


func _generate_code() -> String:
	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var code = ""
	for i in 6:
		code += chars[randi() % chars.length()]
	return code
