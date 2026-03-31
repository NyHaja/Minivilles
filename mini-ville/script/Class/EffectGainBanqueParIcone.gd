class_name EffectGainBanqueParIcone
extends Effect

var montant_par_carte : int
var icones_cibles : Array    # list des icons à compter ex: [Icon.Type.WHEAT, Icon.Type.COW]


func _init(p_id: int, p_montant_par_carte: int, p_icones_cibles: Array):
	# creation description
	var icones_str = _generer_description_icones(p_icones_cibles)
	var desc = "Gagner " + str(p_montant_par_carte) + " pièce(s) par carte " + icones_str + " possédée"
	super._init(p_id, desc)
	
	montant_par_carte = p_montant_par_carte
	icones_cibles = p_icones_cibles


# générer une description lisible des icônes 
# input : [Icon.Type.WHEAT, Icon.Type.COW, Icon.Type.GEAR]
#output : "Blé / Bétail / Engrenage"
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


# Convertir l'enum Icon en nom lisible
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


# méthode abstraite
func appliquer(game: Game, owner: Player, roller: Player):
	# nbr de cartes avec les icones cibles
	var nombre_cartes = owner.cardsWithIcon(icones_cibles)
	
	# gain total
	var gain_total = nombre_cartes * montant_par_carte
	
	# incrémenter argent
	owner.receiveGold(gain_total)
	
	print(owner.username, " possède ", nombre_cartes, " carte(s) avec icône(s) cible(s)")
	print(owner.username, " gagne ", gain_total, " pièce(s) (", nombre_cartes, " × ", montant_par_carte, ")")


# Pas de condition
func peutActiver(game: Game, owner: Player, roller: Player) -> bool:
	return true
