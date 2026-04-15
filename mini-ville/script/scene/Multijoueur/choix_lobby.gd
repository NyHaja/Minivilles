extends Control

signal on_back

func _ready():
	_setup_btn($Content/BtnCreerWrap/BtnCreer, func(): get_tree().change_scene_to_file("res://scene/Multijoueur/creation_lobby.tscn"))
	_setup_btn($Content/BtnRejoindreWrap/BtnRejoindre, func(): get_tree().change_scene_to_file("res://scene/Multijoueur/rejoindre_lobby.tscn"))
	$Content/HBoxContainer2/BtnRetour/BtnBack.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			get_tree().change_scene_to_file("res://scene/Ecran principale/mode_de_jeu.tscn"))


func _setup_btn(btn: Button, on_press: Callable):
	btn.pressed.connect(on_press)
	btn.mouse_entered.connect(func():
		var t = btn.create_tween()
		t.tween_property(btn, "modulate", Color(1.3, 1.3, 1.3), 0.1))
	btn.mouse_exited.connect(func():
		var t = btn.create_tween()
		t.tween_property(btn, "modulate", Color(1, 1, 1), 0.1))
	btn.button_down.connect(func():
		var t = btn.create_tween()
		t.tween_property(btn, "modulate", Color(0.7, 0.7, 0.7), 0.05))
	btn.button_up.connect(func():
		var t = btn.create_tween()
		t.tween_property(btn, "modulate", Color(1, 1, 1), 0.1))
