class_name EffectAeroport
extends Effect

# Effet PASSIF Aéroport : Si vous ne construisez rien ce tour, recevez 10 pièces de la banque


func _init(p_id: int):
	super._init(p_id, "Si vous ne construisez rien ce tour, recevez 10 pièces de la banque.")


func appliquer(game: GameServer, owner: Player, roller: Player):
	# Le joueur reçoit 10 pièces de la banque
	owner.receiveGold(10)
	print(owner.username, " n'a rien construit et reçoit 10 pièces grâce à l'Aéroport")


func peutActiver(game: GameServer, owner: Player, roller: Player) -> bool:
	# Game doit verif que joueur a rien construit
	# La logique de vérification se fera dans le Game
	return true
