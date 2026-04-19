class_name EffectGainBanquePortRequis
extends EffectGainBanque

# hérite EffectGainBanque (montant, appliquer, etc.)

# Surcharge peutActiver
func peutActiver(game: Game, owner: Player, roller: Player) -> bool:
	# Vverif owner possède Port
	return owner.monumentIsActive(26)
