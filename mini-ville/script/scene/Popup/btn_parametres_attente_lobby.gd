extends TextureButton


func _ready():
	pressed.connect(_on_pressed)


func _on_pressed():
	var popup = load("res://scene/popup/popup_parametres.tscn").instantiate()
	get_tree().root.add_child(popup)
