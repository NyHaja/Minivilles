class_name EffectGainBanquePortRequis
extends EffectGainBanque

# hérite EffectGainBanque (montant, appliquer, etc.)

# Surcharge peutActiver
func peutActiver(game: GameServer, owner: Player, roller: Player) -> bool:
	# Vverif owner possède Port
	return owner.monumentIsActive(26)
