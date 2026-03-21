extends Node
class_name CardFactory

# PLACEHOLDER

static func creerChampsBlé() -> Establishment:
	var card = Establishment.new()
	card.name = "Champs de Blé"
	card.id = 1
	card.cost = 1
	card.color = Establishment.COLOR.BLUE
	card.activation = [1, 1]
	return card

static func creerBoulangerie() -> Establishment:
	var card = Establishment.new()
	card.name = "Boulangerie"
	card.id = 7
	card.cost = 1
	card.color = Establishment.COLOR.GREEN
	card.activation = [2, 3]
	return card

static func creerFerme():
	return
	
static func creerForet():
	return

static func creerVignoble():
	return
	
static func creerMine():
	return

static func creerVerger():
	return
	
static func creerPetitBateauPeche():
	return
	
static func creerEpicerie():
	return

static func creerSuperette():
	return
		
static func creerFromagerie():
	return

static func creerFabriqueMeubles():
	return
		
static func creerMoonsterSoda():
	return

static func creerHalleMarche():
	return
		
static func creerMarcheFL():
	return

static func creerStade():
	return
		
static func creerChaineTele():
	return

static func creerMaisonEdition():
	return
		
static func creerCentreImpots():
	return

static func creerCafe():
	return
		
static func creerMoonsterBurger():
	return

static func creerRestaurantFamilial():
	return
