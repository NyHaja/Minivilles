class_name EffectVolTous
extends Effect

var montant : int


func _init(p_id: int):
	# Description de l'effet Vol à Tous
	super._init(p_id, "Stade : chaque adversaire paie 2 pièces - Paiement dans l'ordre antihoraire")
	montant = 2



func appliquer(game: Game, owner: Player, roller: Player):
	# Logique : chaque adversaire (sauf owner) paie 2 pièces
	# Paiement dans l'ordre antihoraire
	
	# Trouver index owner dans liste joueurs
	var index_owner = -1
	for i in range(game.joueurs.size()):
		if game.joueurs[i] == owner:
			index_owner = i
			break
	
	if index_owner == -1:
		push_error("Owner non trouvé dans la liste des joueurs")
		return
	
	# Parcourir adversaires dans l'ordre antihoraire
	var nb_joueurs = game.joueurs.size()
	
	for i in range(1, nb_joueurs):
		var index = (index_owner - i + nb_joueurs) % nb_joueurs
		var adversaire = game.joueurs[index]
		
		# Calculer montant que l'adversaire peut payer
		var montant_paye = min(montant, adversaire.argent)
		
		# Transfert d'argent
		adversaire.argent -= montant_paye
		owner.argent += montant_paye
		
		print(adversaire.nom, " paie ", montant_paye, " pièce(s) à ", owner.nom)


func peutActiver(game: Game, owner: Player, roller: Player) -> bool:

	return true
	
