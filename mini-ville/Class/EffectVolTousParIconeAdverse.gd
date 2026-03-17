class_name EffectVolTousParIconeAdverse
extends Effect

var montant_par_icone : int
var icones_cibles : Array

func _init(p_id: int, p_montant_par_icone: int, p_icones_cibles:Array):
	# Description de l'effet Vol à Tous par Icone Adverse
	var icones_str = _generer_description_icones(p_icones_cibles)
	var desc = "Chaque adversaire vous donne " + str(p_montant_par_icone) + " pièces par carte " + icones_str + " qu'il possède"
	super._init(p_id, desc)
	montant_par_icone = p_montant_par_icone
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

func appliquer(game: Game, owner: Player, roller: Player):
	# Trouver l'index du owner
	var index_owner = -1
	for i in range(game.joueurs.size()):
		if game.joueurs[i] == owner:
			index_owner = i
			break
	
	if index_owner == -1:
		push_error("Owner non trouvé dans la liste des joueurs")
		return
	
	# parcourir  adversaires ordre antihoraire
	var nb_joueurs = game.joueurs.size()
	
	for i in range(1, nb_joueurs):
		var index = (index_owner - i + nb_joueurs) % nb_joueurs
		var adversaire = game.joueurs[index]
		
		
		var nombre_cartes = _compter_cartes_avec_icones(adversaire)
		
		# Calculer le montant que l'adversaire doit payer
		var montant_du = nombre_cartes * montant_par_icone
		
		# Calculer ce que l'adversaire peut réellement payer
		var montant_paye = min(montant_du, adversaire.argent)
		
		# Transfert d'argent
		adversaire.argent -= montant_paye
		owner.argent += montant_paye
		
		print(adversaire.nom, " possède ", nombre_cartes, " carte(s) avec icône(s) cible(s)")
		print(adversaire.nom, " paie ", montant_paye, " pièce(s) à ", owner.nom, " (", nombre_cartes, " × ", montant_par_icone, ")")
 
 

func _compter_cartes_avec_icones(adversaire: Player) -> int:
	var count = 0
	
	# parcourir deck adversaire
	if adversaire.deck != null:
		for carte in adversaire.deck:
			if carte is Establishment:
				var etablissement = carte as Establishment
				# si icone dans la liste cibles
				if icones_cibles.has(etablissement.get_icon()):
					count += 1
	
	return count
