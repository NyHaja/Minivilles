class_name EffectVolTous
extends Effect

var montant : int


func _init(p_id: int, p_montant: int):
	# Description de l'effet Vol à Tous
	var desc ="Chaque adversaire vous donne "+ str(p_montant) +" pièces"
	super._init(p_id, desc)
	montant = p_montant



func appliquer(game: GameServer, owner: Player, roller: Player):
	# Logique : chaque adversaire (sauf owner) paie x pièces
	# Paiement dans l'ordre antihoraire
	
	# Trouver index owner dans liste joueurs
	var index_owner = -1
	for i in range(game.playerArray.size()):
		if game.playerArray[i] == owner:
			index_owner = i
			break
	
	if index_owner == -1:
		push_error("Owner non trouvé dans la liste des joueurs")
		return
	
	# Parcourir adversaires dans l'ordre antihoraire
	var nb_joueurs = game.playerArray.size()
	
	for i in range(1, nb_joueurs):
		var index = (index_owner - i + nb_joueurs) % nb_joueurs
		var adversaire = game.playerArray[index]
		
		# Calculer montant que l'adversaire peut payer
		var montant_paye = min(montant, adversaire.balance)
		
		# Transfert d'argent
		adversaire.loseGold(montant_paye)
		owner.receiveGold(montant_paye)
		
		print(adversaire.username, " paie ", montant_paye, " pièce(s) à ", owner.username)


func peutActiver(game: GameServer, owner: Player, roller: Player) -> bool:

	return true
