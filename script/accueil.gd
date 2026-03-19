extends Control

# Popup login
var popup_login_scene = preload("res://scenes/popup_login.tscn")
var popup_login

#Mode as Guest
var asGuest = preload("res://scenes/guest_screen.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	popup_login = popup_login_scene.instantiate()
	add_child(popup_login)
	popup_login.hide()
	
	popup_login.on_back.connect(_on_popup_back)
	
	$gameMode/loginbtn.pressed.connect(affiche_popup_login)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
# bouton login pour s'authentifier
func affiche_popup_login() -> void:
	$gameMode.hide()
	popup_login.show()

func guest_mode() -> void:
	get_tree().change_scene_to_packed(asGuest)
	
func _on_popup_back():
	$gameMode.show()
