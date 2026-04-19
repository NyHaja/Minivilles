extends Control

signal on_back


func _ready() -> void:
	$Panel/VBoxContainer/backbtn.pressed.connect(_on_back_pressed)
	$Panel/Panelsignin/MarginContainer/Boxconnexion/VBoxContainer2/Button.pressed.connect(_on_signin)
	$Panel/Panelsignin/MarginContainer/Boxconnexion/VBoxContainer2/Button2.pressed.connect(_on_back_pressed)


func _on_back_pressed() -> void:
	on_back.emit()
	queue_free()


func _on_signin() -> void:
	get_tree().change_scene_to_file("res://scene/Ecran principale/connected_screen.tscn")
