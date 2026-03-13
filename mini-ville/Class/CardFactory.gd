class_name CardFactory

# === 🟣 VIOLETS ===

# Chaîne de Télévision - Violet - Activation: 6
# Effet: Choisir 1 joueur → 5 pièces
static func creerChaineTele() -> Establishment:
	# Créer EffectVolChoix
	var effet = EffectVolChoix.new(1)  # ID effect
	
	# Créer Establishment
	var carte = Establishment.new()
	carte.NewCard(
		effet,
		5,                                        # id card
		"Chaîne de Télévision",
		Icon.Type.MAJOR,
		CardColor.Type.PURPLE,
		7,                                        # cost
		"Choisir 1 joueur → 5 pièces",
		[6, 6]                                    # activationNum [min, max]
	)
	
	return carte
