extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Panel.hide()
	$guest_screen.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
# bouton login pour s'authentifier
func _on_loginbtn_button_down() -> void:
	$gameMode.hide()
	$Panel.show()
	$Panel/Panellogin.show()


func _on_guestbtn_button_down() -> void:
	$gameMode.hide()
	$guest_screen.show()
