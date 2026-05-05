class_name EffectChalutier
extends Effect

# Effet Chalutier : Lancez 2 dés supplémentaires, recevez la somme en pièces
# Necessite Port

func _init(p_id: int):
	super._init(p_id, "Lancez 2 dés, recevez la somme. (Nécessite le Port)")


func appliquer(game: GameServer, owner: Player, roller: Player):
	# Lancer 2 dés supplémentaires
	var de1 = randi() % 6 + 1  # Dé 1 : 1-6
	var de2 = randi() % 6 + 1  # Dé 2 : 1-6
	var somme = await game.gameplayScreen.ask_chalutier_roll(owner.username)
	
	owner.receiveGold(somme) 
	
	print(owner.username, " finishes Chalutier harvest for ", somme, " gold.")


func peutActiver(game: GameServer, owner: Player, roller: Player) -> bool:
	# verif owner possède monument Port
	return owner.monumentIsActive(26)  # ID Port
