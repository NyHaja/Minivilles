extends Node

const popup_code = preload("res://scene/popup/retrieve_password.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_send_button_pressed() -> void:
	# strip_edges() nettoie les espaces avant et après le texte
	var mail = %mail_forgot_pass.text.strip_edges()
	
	if mail == "":
		
		
		# On utilise tr() pour la traduction
		%LabelErreur.text = tr("Veuillez entrer votre adresse email.")
		%LabelErreur.add_theme_color_override("font_color", Color.RED) # Pour être cohérent avec tes autres popups
		%LabelErreur.show()
		
		return
	
	# Si on arrive ici, c'est que le mail n'est pas vide
	Client.forgot_password(mail)
	var instance_popup = popup_code.instantiate()
	add_child(instance_popup)


func _on_return_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/Ecran principale/accueil.tscn")
