class_name EffectParcAttractions
extends Effect

# Effet PASSIF Parc d'Attractions : Si vous obtenez un double avec 2 dés, rejouez un tour supplémentaire (max 1 bonus)



func _init(p_id: int):
	super._init(p_id, "Si vous obtenez un double avec 2 dés, rejouez un tour supplémentaire (max 1 bonus).")


func appliquer(game: GameServer, owner: Player, roller: Player):
	# Il faut verif dans Game si joueur possède Parc Attraction et relancer apres un double !!!
	print(owner.username, " possède le Parc d'Attractions et peut rejouer en cas de double")


func peutActiver(game: GameServer, owner: Player, roller: Player) -> bool:
	return true
