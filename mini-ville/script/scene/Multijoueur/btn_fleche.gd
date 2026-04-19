extends TextureButton


func _ready():
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)


func _on_button_down():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.85, 0.85), 0.07)
	tween.tween_property(self, "modulate", Color(0.7, 0.7, 0.7), 0.07)


func _on_button_up():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.1)
