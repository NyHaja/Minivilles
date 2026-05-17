class_name EffectGare
extends Effect

# Effet PASSIF Gare : Vous pouvez choisir de lancer 1 ou 2 dés



func _init(p_id: int):
	super._init(p_id, "Vous pouvez choisir de lancer 2 dés au lieu d'1.")


func appliquer(game: Game, owner: Player, roller: Player):
	# Il faut verif dans Game si joueur possède Gare !!!
	print(owner.username, " possède la Gare et peut lancer 2 dés")


func peutActiver(game: Game, owner: Player, roller: Player) -> bool:
	return true
