class_name EffectDemenagement
extends Effect

var montant_recu : int  # Montant reçu en échange du don


func _init(p_id: int, p_montant_recu: int):
	var desc = "Donnez 1 établissement non-violet à un adversaire. Recevez " + str(p_montant_recu) + " pièces."
	super._init(p_id, desc)
	montant_recu = p_montant_recu


func appliquer(game: Game, owner: Player, roller: Player):
	# owner choisit :
	# 1. etablissement non-violet à donner
	# 2. adversaire à qui le donner
	
	
	# Les choix sont stockés ici
	var carte_a_donner = game.carte_choisie_pour_don
	var adversaire_cible = game.adversaire_choisi_pour_don
	
	if carte_a_donner == null:
		push_error("Aucune carte choisie pour le don")
		return
	
	if adversaire_cible == null:
		push_error("Aucun adversaire choisi")
		return
	
	# verif que carte est non-violette
	if carte_a_donner is Establishment:
		var etab = carte_a_donner as Establishment
		if etab.get_color() == CardColor.Type.PURPLE:
			push_error("Impossible de donner une carte violette")
			return
	
	# verif que owner possède bien cette carte
	if not owner.deck.has(carte_a_donner):
		push_error("Le owner ne possède pas cette carte")
		return
	
	# transferer carte
	owner.deck.erase(carte_a_donner)
	adversaire_cible.deck.append(carte_a_donner)
	owner.establishmentCount -= 1
	adversaire_cible.establishmentCount += 1
	
	# Recevoir argent banque
	owner.argent += montant_recu
	
	print(owner.username, " donne ", carte_a_donner.get_name(), " à ", adversaire_cible.username)
	print(owner.username, " reçoit ", montant_recu, " pièces de la banque")


func peutActiver(game: Game, owner: Player, roller: Player) -> bool:
	# joueur doit avoir >= 1 établissement non-violet
	if owner.deck == null:
		return false
	
	for carte in owner.deck:
		if carte is Establishment:
			var etab = carte as Establishment
			if etab.get_color() != CardColor.Type.PURPLE:
				return true  # > 0 carte non-violette
	
	return false
