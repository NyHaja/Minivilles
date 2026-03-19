extends Control

signal on_back

func _ready() -> void:
	$Panel/VBoxContainer/backbtn.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	on_back.emit()
	hide()
