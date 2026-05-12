extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_return_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/Ecran principale/accueil.tscn")
			

# --- Fonction reliée au bouton "Valider le nouveau mot de passe" ---
func _on_send_button_pressed() -> void:
	# On cache le message précédent s'il y en a un
	var error_node = get_node_or_null("%errorMessage_f")
	if error_node:
		error_node.hide()
	
	# Récupération des nœuds des mots de passe
	var new_pwd_node = get_node_or_null("%NewPasswordInput")
	var confirm_pwd_node = get_node_or_null("%ConfirmNewPasswordInput")
	var mail = get_node_or_null("%mail").text 
	
	# Récupération des nœuds du code
	var first = get_node_or_null("%FirstChar")
	var second = get_node_or_null("%SecondChar")
	var third = get_node_or_null("%ThridChar")
	var forth = get_node_or_null("%ForthChar")
	var fifth = get_node_or_null("%FifthChar")
	var last = get_node_or_null("%LastChar")
	
	# Sécurité : on s'assure que les nœuds existent bien dans la scène
	if not new_pwd_node or not confirm_pwd_node or not first:
		return
		
	# On récupère les textes et on nettoie les espaces en trop
	var new_password = new_pwd_node.text.strip_edges()
	var confirm = confirm_pwd_node.text.strip_edges()
	
	# On concatène le code
	var full_code = first.text + second.text + third.text + forth.text + fifth.text + last.text
	
	# 1. Vérification : Code incomplet (avec tr)
	if full_code.length() < 6:
		afficher_message(tr("Veuillez entrer le code à 6 chiffres complet."), false)
		return
		
	# 2. Vérification : Mot de passe vide (avec tr)
	if new_password == "":
		afficher_message(tr("Veuillez entrer un nouveau mot de passe."), false)
		return
		
	# 3. Vérification : Les mots de passe ne correspondent pas (avec tr)
	if new_password != confirm:
		afficher_message(tr("Les mots de passe ne correspondent pas."), false)
		return
		
	SoundManager.play_click()
	
	# 4. Tout est bon, on affiche le succès et on lance la requête (avec tr)
	afficher_message(tr("Modification en cours..."), true)
	
	# Appel réseau hypothétique : on envoie le code et le nouveau mot de passe
	Client.verify_reset_code(mail, full_code, new_password)
	get_tree().change_scene_to_file("res://scene/Ecran principale/accueil.tscn")


# --- Fonction unique pour gérer Succès et Erreurs ---
func afficher_message(msg: String, is_success: bool) -> void:
	var node = get_node_or_null("%errorMessage_f")
	if node:
		node.text = msg
		# On change la couleur selon le paramètre booléen
		if is_success:
			node.add_theme_color_override("font_color", Color.GREEN)
		else:
			node.add_theme_color_override("font_color", Color.RED)
		
		node.show()


# --- Fonction pour fermer le popup (bouton retour/croix) ---
func _on_close_button_pressed() -> void:
	SoundManager.play_click()
	queue_free() # On détruit le popup puisqu'on ne l'utilise plus
