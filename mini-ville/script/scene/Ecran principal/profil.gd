extends Control

const CONTENT = "CenterContainer/Card/VBoxCard/MarginContent/VBoxContent"

func _ready() -> void:
	var btn_deconnexion = $CenterContainer/Card/VBoxCard/MarginContent/VBoxContent/BtnDeconnexion
	$BtnRetour/Fleche.pressed.connect(_on_fermer)


# ------------------------------------
#  MISE À JOUR DE L'INTERFACE
# ------------------------------------
func update_stats(data: Dictionary) -> void:
	if not is_inside_tree(): return
	
	# Récupération des données depuis le JSON
	var pseudo = data.get("nickname", "Joueur Inconnu")
	var parties = data.get("games_played_count", 0)
	var victoires = data.get("wins_count", 0)
	var winrate = data.get("winrate", 0)
	var mail = data.get("email","")
	var created_at = data.get("created_at",)
	
	# Calcul des défaites (Parties jouées - Victoires)
	var defaites = parties - victoires
	if defaites < 0: defaites = 0 

	# Mise à jour des Labels (Grâce aux Noms Uniques '%')
	if get_node_or_null("%LabelPseudo"):
		%LabelPseudo.text = str(pseudo).to_upper() 
		
	if get_node_or_null("%LabelEmail"):
		%LabelEmail.text = str(mail)
		
	if get_node_or_null("%LabelMembre"):
		%LabelMembre.text = str(created_at)

	if get_node_or_null("%LabelPartiesVal"):
		%LabelPartiesVal.text = str(parties)

	if get_node_or_null("%LabelVictoiresVal"):
		%LabelVictoiresVal.text = str(victoires)

	if get_node_or_null("%LabelDefaitesVal"):
		%LabelDefaitesVal.text = str(defaites)

	if get_node_or_null("%LabelWinRateVal"):
		%LabelWinRateVal.text = str(winrate) + "%"

# ------------------------------------
#  BOUTONS & NAVIGATION EXISTANTS
# ------------------------------------
func _on_fermer() -> void:
	if typeof(SoundManager) != TYPE_NIL: SoundManager.play_click()
	get_tree().change_scene_to_file("res://scene/Ecran principale/connected_screen.tscn")



func _on_btn_deconnexion_pressed() -> void:
	Client.logout()
	if typeof(SoundManager) != TYPE_NIL: SoundManager.play_click()
	get_tree().change_scene_to_file("res://scene/Ecran principale/accueil.tscn")
