extends Control


func _ready() -> void:
	$gameMode/starttbtn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scene/Ecran principale/mode_de_jeu.tscn"))
		
	$gameMode/loginbtn.pressed.connect(func():
		var popup_login = load("res://scene/popup/popup_login.tscn").instantiate()
		get_tree().root.add_child(popup_login)
		popup_login.on_back.connect(func(): popup_login.queue_free()))
