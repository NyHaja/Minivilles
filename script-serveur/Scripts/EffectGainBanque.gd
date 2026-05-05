class_name EffectGainBanque
extends Effect

var montant : int


func _init(p_id: int, p_montant: int):
	var desc = "Gagner " + str(p_montant) + " pièce(s) de la banque"
	super._init(p_id, desc)
	montant = p_montant


func appliquer(game: GameServer, owner: Player, roller: Player):
	owner.receiveGold(montant)
	print(owner.username, " gagne ", montant, " pièce(s)")


func peutActiver(game: GameServer, owner: Player, roller: Player) -> bool:
	return true
