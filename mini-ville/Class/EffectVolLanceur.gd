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
	# montant que le roller peut payer
	if(owner.monumentIsActive(23)):
		montant += 1
	var montant_paye = min(montant, roller.argent)
	
	# transfert argent 
	roller.argent -= montant_paye
	owner.argent += montant_paye
	
	print(roller.nom, " (lanceur) paie ", montant_paye, " pièce(s) à ", owner.nom)


func peutActiver(game: Game, owner: Player, roller: Player) -> bool:
	return true
