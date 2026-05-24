class_name CardFactory

static var _database: Dictionary = {}

static func get_card(card_id: int) -> Card:
	if _database.is_empty():
		_initialize_database()
	return _database.get(card_id)
	
static func _initialize_database() -> void:
	_database[1] = creerChampBlé()
	_database[2] = creerFerme()
	_database[3] = creerForet()
	_database[4] = creerVignoble()
	_database[5] = creerMine()
	_database[6] = creerVerger()
	_database[7] = creerBoulangerie()
	_database[8] = creerSuperette()
	_database[9] = creerPetitBateauPeche()
	_database[10] = creerFabriqueMeubles()
	_database[11] = creerMoonsterSoda()
	_database[12] = creerHalleMarche()
	_database[13] = creerMarcheFL()
	_database[14] = creerStade()
	_database[15] = creerMaisonEdition()
	_database[16] = creerCafe()
	_database[17] = creerMoonsterBurger()
	_database[18] = creerRestaurantFamilial()
	_database[19] = creerCentreImpots()
	_database[20] = creerEpicerie()
	_database[21] = creerGare()
	_database[22] = creerCentreCommercial()
	_database[23] = creerParcAttractions()
	_database[24] = creerTourRadio()
	_database[25] = creerPort()
	_database[26] = creerAeroport()
	_database[27] = creerClubPrive()
	_database[28] = creerChalutier()
	_database[29] = creerEntrepriseTravauxPublics()
	_database[30] = creerEntrepriseDemenagement()
	_database[31] = creerCentreAffaires()
	_database[32] = creerChaineTele()

static func creerTousMonuments() -> Array[Monument]:
	var monuments : Array[Monument] = []
	
	monuments.append(creerGare())
	monuments.append(creerCentreCommercial())
	monuments.append(creerParcAttractions())
	monuments.append(creerTourRadio())
	monuments.append(creerPort())
	monuments.append(creerAeroport())
	
	return monuments


# === MONUMENTS  ===
 
# Gare - Coût: 4
# Effet: Vous pouvez choisir de lancer 2 dés au lieu d'1
static func creerGare() -> Monument:
	var effet = EffectGare.new(8)  # id_effet=8
	
	var monument = Monument.new()
	monument.NewMonument(
		effet,
		21,                             # id monument
		"Gare",
		4,                              # coût
		"Vous pouvez choisir de lancer 2 dés au lieu d'1."
	)
	
	return monument
 
 
# Centre Commercial - Coût: 10
# Effet: Vos établissements Tasse et Pain rapportent +1 pièce chacun
static func creerCentreCommercial() -> Monument:
	var effet = EffectCentreCommercial.new(9)  # id_effet=9
	
	var monument = Monument.new()
	monument.NewMonument(
		effet,
		22,                             # id monument
		"Centre Commercial",
		10,                             # coût
		"Vos établissements Tasse (rouge) et Pain (vert) rapportent +1 pièce chacun."
	)
	
	return monument
 
 
# Parc d'Attractions - Coût: 16
# Effet: Si vous obtenez un double avec 2 dés, rejouez un tour supplémentaire (max 1 bonus)
static func creerParcAttractions() -> Monument:
	var effet = EffectParcAttractions.new(10)  # id_effet=10
	
	var monument = Monument.new()
	monument.NewMonument(
		effet,
		23,                             # id monument
		"Parc d'Attractions",
		16,                             # coût
		"Si vous obtenez un double avec 2 dés, rejouez un tour supplémentaire (max 1 bonus)."
	)
	
	return monument
 
 
# Tour Radio - Coût: 22
# Effet: Une fois par tour, relancez vos dés (même nombre, seul le 2e résultat compte)
static func creerTourRadio() -> Monument:
	var effet = EffectTourRadio.new(11)  # id_effet=11
	
	var monument = Monument.new()
	monument.NewMonument(
		effet,
		24,                             # id monument
		"Tour Radio",
		22,                             # cout
		"Une fois par tour, relancez vos dés (même nombre, seul le 2e résultat compte)."
	)
	
	return monument
 
 
# Port - Coût: 2
# Effet: Si résultat des dés >= 10, ajoutez +2. Active aussi Petit bateau et Chalutier
static func creerPort() -> Monument:
	var effet = EffectPort.new(12)  # id_effet=12
	
	var monument = Monument.new()
	monument.NewMonument(
		effet,
		25,                             # id monument
		"Port",
		2,                              # coût
		"Si résultat des dés >= 10, ajoutez +2. Active aussi Petit bateau et Chalutier."
	)
	
	return monument
 
 
# Aéroport - Coût: 30
# Effet: Si vous ne construisez rien ce tour, recevez 10 pièces de la banque
static func creerAeroport() -> Monument:
	var effet = EffectAeroport.new(13)  # id_effet=13
	
	var monument = Monument.new()
	monument.NewMonument(
		effet,
		26,                             # id monument
		"Aéroport",
		30,                             # coût
		"Si vous ne construisez rien ce tour, recevez 10 pièces de la banque."
	)
	
	return monument
 
 


# === 🔵 BLEUS  ===
# Cartes bleues : s'activent sur n'importe quel tour (quand le dé tombe sur leur numéro)

# Champ de Blé - Bleu - Dé: 1 - Coût: 1
# Icon: WHEAT
# Effect: Recevoir 1 pièce de la banque
static func creerChampBlé() -> Establishment:
	var effet = EffectGainBanque.new(1, 1)  # id_effet=1, montant=1
	
	# Créer la carte
	var carte = Establishment.new()
	carte.NewCard(
		effet,
		1,                              # id card
		"Champ de blé",
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

# Vignoble - Dé: 7 - Coût: 3
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
		9,                              # id card
		"Petit bâteau de pêche",
		Icon.Type.BOAT,
		CardColor.Type.BLUE,
		2,                              # coût
		"Recevez 3 pièces.\n(Nécessite le Port)",
		[8, 8]                          # activation sur 8
	)
	
	return carte

# Chalutier - Dé: 12-14 - Coût: 5
# Icon: BOAT
# Effect: Lancez 2 dés, recevez la somme (Port Requis)
static func creerChalutier() -> Establishment:
	var effet = EffectChalutier.new(15)  # id_effet=15
	
	var carte = Establishment.new()
	carte.NewCard(
		effet,
		28,                             # id card
		"Chalutier",
		Icon.Type.BOAT,
		CardColor.Type.BLUE,
		5,                              # coût
		"Lancez 2 dés, recevez la somme. (Nécessite le Port)",
		[12, 14]                        # activation sur 12-14
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
		20,                              # id card
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
		10,                             # id card
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
		11,                             # id card
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
		12,                             # id card
		"Halle de marché",
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
		13,                             # id card
		"Marché de fruits et légumes",
		Icon.Type.FRUIT,
		CardColor.Type.GREEN,
		2,                              # coût
		"Recevez 2 pièces par carte Blé possédée.",
		[11, 12]                        # activation 11-12
	)
	
	return carte


# Entreprise de travaux publics - Dé: 4 - Coût: 2
# Icon: SUITCASE
# Effect: Démolissez 1 de vos monuments. Recevez 8 pièces.
static func creerEntrepriseTravauxPublics() -> Establishment:
	var effet = EffectDemolition.new(16, 8)  # id_effet=16, montant=8
	
	var carte = Establishment.new()
	carte.NewCard(
		effet,
		29,                             # id card
		"Entreprise de travaux publics",
		Icon.Type.SUITCASE,
		CardColor.Type.GREEN,
		2,                              # coût
		"Démolissez 1 de vos monuments. Recevez 8 pièces.",
		[4, 4]                          # activation sur 4
	)
	
	return carte
 
 
# Entreprise de déménagement - Dé: 9-10 - Coût: 2
# Icon: SUITCASE
# Effect: Donnez 1 établissement non-violet à un adversaire. Recevez 4 pièces.
static func creerEntrepriseDemenagement() -> Establishment:
	var effet = EffectDemenagement.new(17, 4)  # id_effet=17, montant=4
	
	var carte = Establishment.new()
	carte.NewCard(
		effet,
		30,                             # id card
		"Entreprise de déménagement",
		Icon.Type.SUITCASE,
		CardColor.Type.GREEN,
		2,                              # coût
		"Donnez 1 établissement non-violet à un adversaire. Recevez 4 pièces.",
		[9, 10]                         # activation sur 9-10
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
		14,                                        # id card
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
		32,                                        # id card
		"Chaîne de Télévision",
		Icon.Type.MAJOR,
		CardColor.Type.PURPLE,
		7,                                        # cost
		"Choisir 1 joueur → 5 pièces",
		[6, 6]                                    # activationNum [min, max]
	)
	
	return carte


# Centre d'affaires - Dé: 6 - Coût: 8
# Icon: MAJOR
# Effect: Échangez un de vos établissements (non-violet) avec celui d'un adversaire.
static func creerCentreAffaires() -> Establishment:
	var effet = EffectEchange.new(18)  # id_effet=18
	
	var carte = Establishment.new()
	carte.NewCard(
		effet,
		31,                             # id card
		"Centre d'affaires",
		Icon.Type.MAJOR,
		CardColor.Type.PURPLE,
		8,                              # coût
		"Échangez un de vos établissements (non-violet) avec celui d'un adversaire.",
		[6, 6]                          # activation sur 6
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
		15,                                        # id card
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
		19,                             # id card
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
		16,                             # id card
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
		17,                             # id card
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
		18,                             # id card
		"Restaurant",
		Icon.Type.CUP,
		CardColor.Type.RED,
		3,                              # coût
		"Le lanceur vous donne 2 pièces.",
		[9, 10]                         # activation sur 9-10
	)
	
	return carte


# Club Privé - Dé: 12-14 - Coût: 4
# Icon: CUP
# Effect: lanceur vous donne TOUTES ses pièces (s'il a 3+ monuments construits)
static func creerClubPrive() -> Establishment:
	var effet = EffectClubPrive.new(
		14,     # id_effet
		3       # seuil_monuments = 3
	)
	
	# Créer la carte
	var carte = Establishment.new()
	carte.NewCard(
		effet,
		27,                             # id card
		"Club Privé",
		Icon.Type.CUP,
		CardColor.Type.RED,
		4,                              # coût
		"S'active si le lanceur a 3+ monuments.\nIl vous donne ses pièces.",
		[12, 14]                        # activation sur 12-14
	)
	
	return carte
