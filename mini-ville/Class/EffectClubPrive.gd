class_name EffectClubPrive
extends Effect

# Effet Club Privé : Le lanceur donne ses pièces au owner
# Condition : Le lanceur doit avoir >= X monuments construits

var seuil_monuments : int  # Nombre min de monuments que le lanceur doit avoir


func _init(p_id: int, p_seuil_monuments: int):
	var desc = "Le lanceur vous donne toutes ses pièces (s'il a " + str(p_seuil_monuments) + "+ monuments construits)"
	super._init(p_id, desc)
	seuil_monuments = p_seuil_monuments


func appliquer(game: Game, owner: Player, roller: Player):
	# lanceur donne TOUTES ses pièces au OWNER
	var montant_total = roller.balance
	
	# Transfert TOUTES les pièces
	roller.loseGold(montant_total)
	owner.receiveGold(montant_total)
	
	print(roller.username, " (lanceur) donne TOUTES ses pièces (", montant_total, ") à ", owner.username)


func peutActiver(game: Game, owner: Player, roller: Player) -> bool:
	# Verif que lanceur a >= seuil_monuments construits
	var nb_monuments_roller = roller.monumentCount
	return nb_monuments_roller >= seuil_monuments
