extends Control

signal on_back

func _ready() -> void:
	if not $Panel/VBoxContainer/backbtn.pressed.is_connected(_on_back_pressed):
		$Panel/VBoxContainer/backbtn.pressed.connect(_on_back_pressed)
		
func _on_back_pressed() -> void:
	SoundManager.play_click()
	on_back.emit()
	hide()
