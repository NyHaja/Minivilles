class_name CardFactory


# === 🔵 BLEUS  ===
# Cartes bleues : s'activent sur n'importe quel tour (quand le dé tombe sur leur numéro)

# Champs de Blé - Bleu - Dé: 1 - Coût: 1
# Icon: WHEAT
# Effect: Recevoir 1 pièce de la banque
static func creerChampsBlé() -> Establishment:
	var effet = EffectGainBanque.new(1, 1)  # id_effet=1, montant=1
	
	# Créer la carte
	var carte = Establishment.new()
	carte.NewCard(
		effet,
		1,                              # id card
		"Champs de blé",
		Icon.Type.WHEAT,
		CardColor.Type.BLUE,
		1,                              # coût
		"Recevez 1 pièce de la banque.",
		[1, 1]                          # activation
	)
	
	return carte
 
 
# Ferme - Bleu - Dé: 2 - Coût: 1
# Icon: COW
# Effect: Recevoir 1 pièce de la banque
static func creerFerme() -> Establishment:
	var effet = EffectGainBanque.new(1, 1)  # id_effet=1, montant=1
	
	# Créer la carte
	var carte = Establishment.new()
	carte.NewCard(
		effet,
		2,                              # id card
		"Ferme",
		Icon.Type.COW,
		CardColor.Type.BLUE,
		1,                              # coût
		"Recevez 1 pièce de la banque.",
		[2, 2]                          # activation
	)
	
	return carte
 
 
# Forêt - Bleu - Dé: 5 - Coût: 3
# Icon: GEAR
# Effect: Recevoir 1 pièce de la banque
static func creerForet() -> Establishment:
	var effet = EffectGainBanque.new(1, 1)  # id_effet=1, montant=1
	
	# Créer la carte
	var carte = Establishment.new()
	carte.NewCard(
		effet,
		3,                              # id Card
		"Forêt",
		Icon.Type.GEAR,
		CardColor.Type.BLUE,
		3,                              # coût
		"Recevez 1 pièce de la banque.",
		[5, 5]                          # activation
	)
	
	return carte

# Vignoble - Bleu - Dé: 7 - Coût: 3
# Icon: WHEAT
# Effect: Recevoir 3 pièces de la banque
static func creerVignoble() -> Establishment:
	var effet = EffectGainBanque.new(1, 3)  # id_effet=1, montant=3
	
	# Créer la carte
	var carte = Establishment.new()
	carte.NewCard(
		effet,
		4,                              # id card
		"Vignoble",
		Icon.Type.WHEAT,
		CardColor.Type.BLUE,
		3,                              # coût
		"Recevez 3 pièces de la banque.",
		[7, 7]                          # activation
	)
	
	return carte

# Mine - Bleu - Dé: 9 - Coût: 6
# Icon: GEAR
# Effect: Recevoir 5 pièces de la banque
static func creerMine() -> Establishment:
	var effet = EffectGainBanque.new(1, 5)  # id_effet=1, montant=5
	
	# Créer la carte
	var carte = Establishment.new()
	carte.NewCard(
		effet,
		5,                              # id card
		"Mine",
		Icon.Type.GEAR,
		CardColor.Type.BLUE,
		6,                              # coût
		"Recevez 5 pièces de la banque.",
		[9, 9]                          # activation
	)
	
	return carte
 
 
# Verger - Bleu - Dé: 10 - Coût: 3
# Icon: WHEAT
# Effect: Recevoir 3 pièces de la banque
static func creerVerger() -> Establishment:
	var effet = EffectGainBanque.new(1, 3)  # id_effet=1, montant=3
	
	# Créer la carte
	var carte = Establishment.new()
	carte.NewCard(
		effet,
		6,                              # id card
		"Verger",
		Icon.Type.WHEAT,
		CardColor.Type.BLUE,
		3,                              # coût
		"Recevez 3 pièces de la banque.",
		[10, 10]                        # activation
	)
	
	return carte


# === 🟢 VERTS ===
 
# Boulangerie - Vert - Dé: 2-3 - Coût: 1
# Icon: BREAD
# Effect: Recevoir 1 pièce de la banque
static func creerBoulangerie() -> Establishment:
	var effet = EffectGainBanque.new(1, 1)  # id_effet=1, montant=1
	
	# Créer la carte
	var carte = Establishment.new()
	carte.NewCard(
		effet,
		7,                              # id card
		"Boulangerie",
		Icon.Type.BREAD,
		CardColor.Type.GREEN,
		1,                              # coût
		"Recevez 1 pièce de la banque.",
		[2, 3]                          # activation sur 2 ou 3
	)
	
	return carte
 
 
# Superette - Vert - Dé: 4 - Coût: 2
# Icon: BREAD
# Effect: Recevoir 3 pièces de la banque
static func creerSuperette() -> Establishment:
	var effet = EffectGainBanque.new(1, 3)  # id_effet=1, montant=3
	
	# Créer la carte
	var carte = Establishment.new()
	carte.NewCard(
		effet,
		8,                              # id card
		"Superette",
		Icon.Type.BREAD,
		CardColor.Type.GREEN,
		2,                              # coût
		"Recevez 3 pièces de la banque.",
		[4, 4]                          # activation
	)
	
	return carte


# === 🟣 VIOLETS ===

# Chaîne de Télévision - Violet - Activation: 6
# Effect: Choisir 1 joueur → 5 pièces
static func creerChaineTele() -> Establishment:
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
