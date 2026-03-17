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


# Petit bateau de peche - Dé: 8 - Coût: 2
# Icon: BOAT
# Effect: Recevoir 3 pièces de la banque (Nécessite le Port)
static func creerPetitBateauPeche() -> Establishment:
	var effet = EffectGainBanquePortRequis.new(1, 3)  # id_effet=1, montant=3
	
	# Créer la carte
	var carte = Establishment.new()
	carte.NewCard(
		effet,
		10,                             # id card
		"Petit bateau de pêche",
		Icon.Type.BOAT,
		CardColor.Type.BLUE,
		2,                              # coût
		"Recevez 3 pièces. (Nécessite le Port)",
		[8, 8]                          # activation sur 8
	)
	
	return carte

	
# === 🟢 VERTS ===
 
# Boulangerie - Dé: 2-3 - Coût: 1
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
 
# Epicerie - Dé: 2 - Coût: 0
# Icon: BREAD
# Effect: Recevoir 2 pièces si le joeuru possède - de 2 monuments
static func creerEpicerie() -> Establishment:
	var effet = EffectGainBanqueMonumentsInferieur.new(7, 2, 2)  # id_effet=7, montant=2, seuil_monuments
	
	var carte = Establishment.new()
	carte.NewCard(
		effet,
		21,                              # id card
		"Épicerie",
		Icon.Type.BREAD,
		CardColor.Type.GREEN,
		0,                              # coût
		"Recevez 2 pièces si vous possedez moins de 2 monuments",
		[2, 2]                          # activation sur 2
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


# Fromagerie - Dé: 7 - Coût: 5
# Icon: FACTORY
# Effect: Recevoir 3 pièces par carte BÉTAIL possédée
static func creerFromagerie() -> Establishment:
	var effet = EffectGainBanqueParIcone.new(
		2,              # id_effet
		3,              # montant_par_carte
		[Icon.Type.COW]      # icones_cibles
	)
	
	# Créer la carte
	var carte = Establishment.new()
	carte.NewCard(
		effet,
		9,                              # id card
		"Fromagerie",
		Icon.Type.FACTORY,
		CardColor.Type.GREEN,
		5,                              # coût
		"Recevez 3 pièces par carte Bétail possédée.",
		[7, 7]                          # activation sur 7
	)
	
	return carte
 
 
# Fabrique de meubles - Dé: 8 - Coût: 3
# Icon: FACTORY
# Effect: Recevoir 3 pièces par carte ENGRENAGE possédée
static func creerFabriqueMeubles() -> Establishment:

	var effet = EffectGainBanqueParIcone.new(
		2,              # id_effet
		3,              # montant_par_carte
		[Icon.Type.GEAR]     # icones_cibles
	)
	
	# Créer la carte
	var carte = Establishment.new()
	carte.NewCard(
		effet,
		11,                             # id card
		"Fabrique de meubles",
		Icon.Type.FACTORY,
		CardColor.Type.GREEN,
		3,                              # coût
		"Recevez 3 pièces par carte Engrenage possédée.",
		[8, 8]                          # activation sur 8
	)
	
	return carte
 
 
# Moonster Soda - Dé: 11 - Coût: 5
# Icon: FACTORY
# Effect: Recevoir 1 pièce par carte TASSE possédée
static func creerMoonsterSoda() -> Establishment:
	var effet = EffectGainBanqueParIcone.new(
		2,              # id_effet
		1,              # montant_par_carte
		[Icon.Type.CUP]      # icones_cibles
	)
	
	# Créer la carte
	var carte = Establishment.new()
	carte.NewCard(
		effet,
		12,                             # id card
		"Moonster Soda",
		Icon.Type.FACTORY,
		CardColor.Type.GREEN,
		5,                              # coût
		"Recevez 1 pièce par carte Tasse possédée.",
		[11, 11]                        # activation sur 11
	)
	
	return carte
 
 
# Halle du marché -Dé: 11-12 - Coût: 2
# Icon: FRUIT
# Effect: Recevoir 2 pièces par carte BLÉ possédée
static func creerHalleMarche() -> Establishment:
	var effet = EffectGainBanqueParIcone.new(
		2,              # id_effet
		2,              # montant_par_carte
		[Icon.Type.WHEAT]    # icones_cibles
	)
	
	# Créer la carte
	var carte = Establishment.new()
	carte.NewCard(
		effet,
		13,                             # id card
		"Halle du marché",
		Icon.Type.FRUIT,
		CardColor.Type.GREEN,
		2,                              # coût
		"Recevez 2 pièces par carte Blé possédée.",
		[11, 12]                        # activation 11-12
	)
	
	return carte
 
 
# Marché fruits/légumes - Dé: 11-12 - Coût: 2
# Icon: FRUIT
# Effect: Recevoir 2 pièces par carte BLÉ possédée
static func creerMarcheFL() -> Establishment:
	var effet = EffectGainBanqueParIcone.new(
		2,              # id_effet
		2,              # montant_par_carte
		[Icon.Type.WHEAT]    # icones_cibles
	)
	
	# créer la carte
	var carte = Establishment.new()
	carte.NewCard(
		effet,
		14,                             # id card
		"Marché fruits/légumes",
		Icon.Type.FRUIT,
		CardColor.Type.GREEN,
		2,                              # coût
		"Recevez 2 pièces par carte Blé possédée.",
		[11, 12]                        # activation 11-12
	)
	
	return carte



# === 🟣 VIOLETS ===

# Satde - Activation: 6 - Coût: 6
# Effect: Vol a tous les joueurs 2 pièces
static func creerStade() -> Establishment:
	var effet = EffectVolTous.new(3, 2)  # ID effect, montant
	
	# Créer Establishment
	var carte = Establishment.new()
	carte.NewCard(
		effet,
		15,                                        # id card
		"Stade",
		Icon.Type.MAJOR,
		CardColor.Type.PURPLE,
		6,                                        # cost
		"Chaque autre joueur vous donne 2 pièces",
		[6, 6]                                    # activationNum [min, max]
	)
	
	return carte


# Chaîne de Télévision - Activation: 6 - Coût: 7
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


# Maison d'édition - Activation: 7 - Coût: 5
# Effect: Vol a tous les joueurs 1 pièce / carte Tasse ou Pain
static func creerMaisonEdition() -> Establishment:
	var effet = EffectVolTousParIconeAdverse.new(4, 1, [Icon.Type.CUP, Icon.Type.BREAD] )  # ID effect, montant/carte, icones cibles
	
	# Créer Establishment
	var carte = Establishment.new()
	carte.NewCard(
		effet,
		16,                                        # id card
		"Maison d'édition",
		Icon.Type.MAJOR,
		CardColor.Type.PURPLE,
		5,                                        # cost
		"Chaque autre joueur vous donne 1 pièce par carte Tasse ou Pain qu'il possède",
		[7, 7]                                    # activationNum [min, max]
	)
	
	return carte


# Centre des Impôts - Activation: 8-9 - Coût: 4
# Effect: Chaque joueur avec 10+ pièces vous donne la moitié (arrondi inférieur)
static func creerCentreImpots() -> Establishment:
	var effet = EffectImpot.new(6, 10)  # id_effet=6, seuil=10
	
	var carte = Establishment.new()
	carte.NewCard(
		effet,
		20,                             # id card
		"Centre des Impôts",
		Icon.Type.MAJOR,
		CardColor.Type.PURPLE,
		4,                              # coût
		"Chaque joueur avec 10+ pièces vous donne la moitié (arrondi inférieur).",
		[8, 9]                          # activation sur 8-9
	)
	
	return carte

# === 🔴 ROUGES  ===

# Café - vActivation: 3 - Coût: 2
# Icon: CUP
# Effect: Le lanceur vous donne 1 pièce
static func creerCafe() -> Establishment:
	var effet = EffectVolLanceur.new(5, 1)  # id_effet=5, montant=1
	

	var carte = Establishment.new()
	carte.NewCard(
		effet,
		17,                             # id card
		"Café",
		Icon.Type.CUP,
		CardColor.Type.RED,
		2,                              # coût
		"Le lanceur vous donne 1 pièce.",
		[3, 3]                          # activation sur 3
	)
	
	return carte


# Moonster Burger - Activation: 8 - Coût: 1
# Icon: CUP
# Effect: Le lanceur vous donne 1 pièce
static func creerMoonsterBurger() -> Establishment:
	var effet = EffectVolLanceur.new(5, 1)  # id_effet=5, montant=1
	
	# Créer carte
	var carte = Establishment.new()
	carte.NewCard(
		effet,
		18,                             # id card
		"Moonster Burger",
		Icon.Type.CUP,
		CardColor.Type.RED,
		1,                              # coût
		"Le lanceur vous donne 1 pièce.",
		[8, 8]                          # activation sur 8
	)
	
	return carte
 
 
# Restaurant familial - Activation: 9-10 - Coût: 3
# Icon: CUP
# Effect: Le lanceur vous donne 2 pièces
static func creerRestaurantFamilial() -> Establishment:
	var effet = EffectVolLanceur.new(5, 2)  # id_effet=5, montant=2
	
	# Créer carte
	var carte = Establishment.new()
	carte.NewCard(
		effet,
		19,                             # id card
		"Restaurant familial",
		Icon.Type.CUP,
		CardColor.Type.RED,
		3,                              # coût
		"Le lanceur vous donne 2 pièces.",
		[9, 10]                         # activation sur 9-10
	)
	
	return carte
