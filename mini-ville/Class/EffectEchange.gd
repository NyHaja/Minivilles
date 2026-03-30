class_name EffectEchange
extends Effect


func _init(p_id: int):
	var desc = "Échangez un de vos établissements (non-violet) avec celui d'un adversaire."
	super._init(p_id, desc)


func appliquer(game: Game, owner: Player, roller: Player):
	# owner choisit :
	# 1. 1 établissements non-violets à échanger
	# 2. 1 adversaire
	# 3. 1 établissement non-violet de cet adversaire
	
	
	# choix stockés temporairement
	var carte_owner = game.carte_owner_pour_echange
	var adversaire_cible = game.adversaire_choisi_pour_echange
	var carte_adversaire = game.carte_adversaire_pour_echange
	
	if carte_owner == null or adversaire_cible == null or carte_adversaire == null:
		push_error("Choix incomplets pour l'échange")
		return
	
	# verif que deux cartes sont non-violettes
	if carte_owner is Establishment:
		var etab_owner = carte_owner as Establishment
		if etab_owner.get_color() == CardColor.Type.PURPLE:
			push_error("Impossible d'échanger une carte violette (owner)")
			return
	
	if carte_adversaire is Establishment:
		var etab_adv = carte_adversaire as Establishment
		if etab_adv.get_color() == CardColor.Type.PURPLE:
			push_error("Impossible d'échanger une carte violette (adversaire)")
			return
	
	# verif possession des cartes
	if not owner.deck.has(carte_owner):
		push_error("Le owner ne possède pas cette carte")
		return
	
	if not adversaire_cible.deck.has(carte_adversaire):
		push_error("L'adversaire ne possède pas cette carte")
		return
	
	# transfert cartes
	owner.deck.erase(carte_owner)
	adversaire_cible.deck.erase(carte_adversaire)
	
	owner.deck.append(carte_adversaire)
	adversaire_cible.deck.append(carte_owner)
	
	print(owner.nom, " échange ", carte_owner.get_name(), " contre ", carte_adversaire.get_name(), " de ", adversaire_cible.nom)


func peutActiver(game: Game, owner: Player, roller: Player) -> bool:
	# joueur doit avoir >= 1 etablissement non-violet
	if owner.deck == null:
		return false
	
	for carte in owner.deck:
		if carte is Establishment:
			var etab = carte as Establishment
			if etab.get_color() != CardColor.Type.PURPLE:
				return true  # >= 1 une carte non-violette
	
	return false
