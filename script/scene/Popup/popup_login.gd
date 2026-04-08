extends Control

signal on_back

var player_mode = preload("res://scene/Ecran principale/player_screen.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Panel/VBoxContainer/backbtn.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	SoundManager.play_click()
	on_back.emit()
	hide()

# bouton de connexion
func bouton_connexion() -> void:
	SoundManager.play_click()
	get_tree().change_scene_to_packed(player_mode)
	
# bouton d'inscription
func bouton_inscription():
	SoundManager.play_click()
	var popup_signin = load("res://scene/popup/popup_signin.tscn").instantiate()
	get_tree().root.add_child(popup_signin)
	popup_signin.on_back.connect(func(): show())
	hide()
