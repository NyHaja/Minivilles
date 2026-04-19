class_name EffectTourRadio
extends Effect

# Effet PASSID Tour Radio : 1x/tour, relancez vos dés (même nombre, seul le 2e résultat compte)



func _init(p_id: int):
	super._init(p_id, "Une fois par tour, relancez vos dés (même nombre, seul le 2e résultat compte).")


func appliquer(game: Game, owner: Player, roller: Player):
	# Game doit gérer cette relance et ne garder que le 2e résultat
	print(owner.username, " utilise la Tour Radio pour relancer les dés")


func peutActiver(game: Game, owner: Player, roller: Player) -> bool:
	return true
