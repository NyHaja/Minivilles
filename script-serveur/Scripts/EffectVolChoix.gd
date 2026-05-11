class_name EffectVolChoix
extends Effect

var montant : int
var joueur_choisi : Player  # Stockage temporaire du choix


func _init(p_id: int):
	# Desc effet Chaîne de TV
	super._init(p_id, "Chaîne de TV : choisir 1 joueur → 5 pièces")
	montant = 5
	joueur_choisi = null


# Méthode pour choisir joueur cible (appelée par l'UI)
func choisir_cible(cible: Player):
	joueur_choisi = cible


# Récupérer la liste des adversaires possibles
func get_adversaires_disponibles(game: GameServer, owner: Player) -> Array[Player]:
	var adversaires : Array[Player] = []
	for joueur in game.players:
		if joueur != owner:
			adversaires.append(joueur)
	return adversaires


func appliquer(game: GameServer, owner: Player, roller: Player):
	# Logique : owner choisit 1 adversaire qui doit lui payer 5 pièces
	
	# Verif qu'un joueur a été choisi
	if joueur_choisi == null:
		push_error("Aucun joueur choisi pour l'effet Chaîne de TV")
		return
	
	# Verif joueur choisi n'est pas l'owner
	if joueur_choisi == owner:
		push_error("Le joueur ne peut pas se choisir lui-même")
		joueur_choisi = null
		return
	
	# Verif joueur choisi est dans la partie
	if not game.player.has(joueur_choisi):
		push_error("Le joueur choisi n'est pas dans la partie")
		joueur_choisi = null
		return
	
	# calc le montant max que joueur choisi peut payer
	var montant_paye = min(montant, joueur_choisi.balance)
	
	# Transfert d'argent
	joueur_choisi.loseGold(montant_paye)
	owner.receiveGold(montant_paye)
	
	print(owner.username, " a choisi ", joueur_choisi.username, " qui paie ", montant_paye, " pièce(s)")
	
	# Réinit le choix pour la prochaine utilisation
	joueur_choisi = null



func peutActiver(game: GameServer, owner: Player, roller: Player) -> bool:
	var nb_adversaires = 0
	for joueur in game.players:
		if joueur != owner:
			nb_adversaires += 1
	
	return nb_adversaires > 0
