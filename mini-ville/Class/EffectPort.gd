class_name EffectPort
extends Effect

# Effet PASSIF Port : Si résultat des dés >= 10, ajoutez +2
# Petit bateau, Chalutier gérées dans leurs effets


func _init(p_id: int):
	super._init(p_id, "Si résultat des dés >= 10, ajoutez +2. Active aussi Petit bateau et Chalutier.")


func appliquer(game: Game, owner: Player, roller: Player):
	# Game doit vérifier si joueur possède Port
	# et add +2 si resultat >= 10
	print(owner.username, " possède le Port (+2 si résultat >= 10)")


func peutActiver(game: Game, owner: Player, roller: Player) -> bool:
	return true
