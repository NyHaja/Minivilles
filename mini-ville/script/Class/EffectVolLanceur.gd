class_name EffectVolLanceur
extends Effect

var montant : int

func _init(p_id: int, p_montant: int):
	var desc = "Le lanceur vous donne " + str(p_montant) + " pièce(s)"
	super._init(p_id, desc)
	montant = p_montant

func appliquer(game: Game, owner: Player, roller: Player):
	# owner = propriétaire de la carte rouge
	# roller = celui qui a lancé les dés (adversaire)
	var montant_effectif = montant
	if owner.monumentIsActive(23):
		montant_effectif += 1
	var montant_paye = min(montant_effectif, roller.balance)
	
	# transfert argent
	roller.loseGold(montant_paye)
	owner.receiveGold(montant_paye)
	
	print(roller.username, " (lanceur) paie ", montant_paye, " pièce(s) à ", owner.username)


func peutActiver(game: Game, owner: Player, roller: Player) -> bool:
	return true
