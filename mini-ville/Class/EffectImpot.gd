class_name EffectImpot
extends Effect

var seuil : int # nb d'argent à partir duquel l'impot s'applique

func _init(p_id: int, p_seuil: int):
	# Générer la description dynamiquement selon le seuil
	var desc = "Chaque joueur avec " + str(p_seuil) + "+ pièces vous donne la moitié (arrondi inférieur)"
	super._init(p_id, desc)
	seuil = p_seuil

func appliquer(game: Game, owner: Player, roller: Player):
	# chaque joueur avec >= seuil pièces donne la moitié à owner
	# moitié arrondie à l'inférieur
	
	# parcourir joueurs
	for joueur in game.playerArray:
		# ignorer le owner 
		if joueur == owner:
			continue
		
		# verif >= seuil pièces
		if joueur.balance >= seuil:
			# moitié (arrondi inférieur)
			var montant_impot = int(joueur.balance / 2)
			
			# transfert
			joueur.loseGold(montant_impot)
			owner.receiveGold(montant_impot)
			
			print(joueur.username, " avait ", joueur.balance + montant_impot, " pièces → paie ", montant_impot, " pièces d'impôt")
		else:
			print(joueur.username, " a seulement ", joueur.balance, " pièces → pas d'impôt")
			

func peutActiver(game: Game, owner: Player, roller: Player) -> bool:
	return true
