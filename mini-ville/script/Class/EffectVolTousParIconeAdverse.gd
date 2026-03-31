class_name EffectVolTousParIconeAdverse
extends Effect

var montant_par_icone : int
var icones_cibles : Array

func _init(p_id: int, p_montant_par_icone: int, p_icones_cibles: Array):
	var icones_str = _generer_description_icones(p_icones_cibles)
	var desc = "Chaque adversaire vous donne " + str(p_montant_par_icone) + " pièces par carte " + icones_str + " qu'il possède"
	super._init(p_id, desc)
	montant_par_icone = p_montant_par_icone
	icones_cibles = p_icones_cibles


func _generer_description_icones(icones: Array) -> String:
	if icones.size() == 0:
		return ""
	elif icones.size() == 1:
		return _nom_icone(icones[0])
	else:
		var noms = []
		for icone in icones:
			noms.append(_nom_icone(icone))
		return " / ".join(noms)


func _nom_icone(icone: int) -> String:
	match icone:
		Icon.Type.WHEAT: return "Blé"
		Icon.Type.COW: return "Bétail"
		Icon.Type.GEAR: return "Engrenage"
		Icon.Type.BOAT: return "Bateau"
		Icon.Type.BREAD: return "Pain"
		Icon.Type.SUITCASE: return "Valise"
		Icon.Type.FACTORY: return "Usine"
		Icon.Type.FRUIT: return "Fruit"
		Icon.Type.CUP: return "Tasse"
		Icon.Type.MAJOR: return "Majeur"
		_: return "Inconnu"


func appliquer(game: Game, owner: Player, roller: Player):
	var index_owner = -1
	for i in range(game.playerArray.size()):
		if game.playerArray[i] == owner:
			index_owner = i
			break

	if index_owner == -1:
		push_error("Owner non trouvé dans la liste des joueurs")
		return

	var nb_joueurs = game.playerArray.size()

	for i in range(1, nb_joueurs):
		var index = (index_owner - i + nb_joueurs) % nb_joueurs
		var adversaire = game.playerArray[index]

		var nombre_cartes = _compter_cartes_avec_icones(adversaire, game)
		var montant_du = nombre_cartes * montant_par_icone
		var montant_paye = min(montant_du, adversaire.balance)

		adversaire.loseGold(montant_paye)
		owner.receiveGold(montant_paye)

		print(adversaire.username, " possède ", nombre_cartes, " carte(s) avec icône(s) cible(s)")
		print(adversaire.username, " paie ", montant_paye, " pièce(s) à ", owner.username, " (", nombre_cartes, " × ", montant_par_icone, ")")


# Deck = Array de [card_id, quantity] — utilise game.get_card_from_factory et compte les quantités
func _compter_cartes_avec_icones(adversaire: Player, game: Game) -> int:
	var count = 0
	for instance in adversaire.deck:
		if typeof(instance) != TYPE_ARRAY:
			continue
		var card_id = instance[0]
		var quantity = instance[1]
		var card = game.get_card_from_factory(card_id)
		if card != null and icones_cibles.has(card.icon):
			count += quantity
	return count


func peutActiver(game: Game, owner: Player, roller: Player) -> bool:
	return true
