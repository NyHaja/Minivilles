class_name EffectDemolition
extends Effect

var montant_recu : int  # Montant recu en échange de demolition


func _init(p_id: int, p_montant_recu: int):
	var desc = "Démolissez 1 de vos monuments. Recevez " + str(p_montant_recu) + " pièces."
	super._init(p_id, desc)
	montant_recu = p_montant_recu


func appliquer(game: GameServer, owner: Player, roller: Player):
	if game.monument_choisi_pour_demolition == -1:
		return
	# Le owner doit choisir un de ses monuments construits à démolir
	var monument_id = game.monument_choisi_pour_demolition
	
	if monument_id == -1:
		push_error("Aucun monument choisi pour la démolition")
		return
	
	# verif que monument est construit
	if not owner.monumentIsActive(monument_id):
		push_error("Le monument ", monument_id, " n'est pas construit")
		return
	
	# Démolir monument
	var _m = Monument.new()
	_m.id = monument_id
	owner.demolishMonument(_m)
	
	# Recevoir argent banque
	owner.receiveGold(montant_recu)
	
	print(owner.username, " démolît son monument ", monument_id, " et reçoit ", montant_recu, " pièces")


func peutActiver(game: GameServer, owner: Player, roller: Player) -> bool:
	# joueur doit avoir >= 1 monument construit
	return owner.monumentCount > 0
