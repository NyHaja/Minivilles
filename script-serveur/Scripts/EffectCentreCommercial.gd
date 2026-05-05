class_name EffectCentreCommercial
extends Effect

# Effet Centre Commercial : Vos établissements Tasse et Pain rapportent +1 pièce chacun


func _init(p_id: int):
	super._init(p_id, "Vos établissements Tasse (rouge) et Pain (vert) rapportent +1 pièce chacun.")


func appliquer(game: GameServer, owner: Player, roller: Player):
	# Il faut verif dans Game si joueur possède Centre Commercial et add +1 aux cartes concernés !!!
	print(owner.username, " possède le Centre Commercial (+1 pièce aux cartes Tasse et Pain)")


func peutActiver(game: GameServer, owner: Player, roller: Player) -> bool:
	return true
