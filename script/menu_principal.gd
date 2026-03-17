extends Control

@onready var login = preload("res://login.tscn")
@onready var asGuest = preload("res://guest_screen.tscn")


# Called when the node enters the scene tree for the first time.
func _ready():
	$Panel.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# bouton de connexion
func _on_loginbtn_pressed() -> void:
	$Panel/Panelsign.show()

# bouton de retour
func _on_back_pressed():
	$Panel.hide()

# bouton mode invité
func _on_guestbtn_button_down() -> void:
	get_tree().change_scene_to_packed(asGuest)

# bouton pour quitter
func _on_quitbtn_button_down() -> void:
	get_tree().quit()

# bouton pour confirmer l'inscription
func _on_signinbtn_button_down() -> void:
	pass # Replace with function body.
