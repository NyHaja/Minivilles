extends Control


func _ready():
	$BtnRetour/Fleche.pressed.connect(_on_retour)

func update_stats(data: Dictionary) -> void:
	if not is_inside_tree(): return
	
	# Récupération des données depuis le JSON
	var pseudo = data.get("nickname", "Joueur Inconnu")
	var parties = data.get("games_played_count", 0)
	var victoires = data.get("wins_count", 0)
	
	# Calcul des défaites (Parties jouées - Victoires)

	# Mise à jour des Labels (Grâce aux Noms Uniques '%')
	if get_node_or_null("%LabelPseudo"):
		%LabelPseudo.text = str(pseudo).to_upper() 
		
	if get_node_or_null("%LabelPartiesVal"):
		%LabelPartiesVal.text = str(parties)

	if get_node_or_null("%LabelVictoiresVal"):
		%LabelVictoiresVal.text = str(victoires)


func _on_retour():
	hide()
