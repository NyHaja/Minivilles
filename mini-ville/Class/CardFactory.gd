extends Node
class_name CardFactory

static func get_card_texture_path(card_id: int) -> String:
	match card_id:
		1:
			return "res://assets/cards/champs_ble.png"
		7:
			return "res://assets/cards/boulangerie.png"
		_:
			return "res://assets/cards/placeholder.png"
 
static func creerChampsBlé() -> Establishment:
	var card = Establishment.new()
	card.name = "Champs de Blé"
	card.id = 1
	card.cost = 1
	card.color = Establishment.COLOR.BLUE
	card.activation = [1, 1]
	card.icon = "WHEAT"

	card.effect = func(owner: Player, roller: Player):
		owner.recieveGold(1)
		print(owner.username, " harvested 1 gold from Champs de Blé!")

	return card


static func creerBoulangerie() -> Establishment:
	var card = Establishment.new()
	card.name = "Boulangerie"
	card.id = 7
	card.cost = 1
	card.color = Establishment.COLOR.GREEN
	card.activation = [2, 3]
	card.icon = "BREAD"

	card.effect = func(owner: Player, roller: Player):
		owner.recieveGold(1)
		print(owner.username, " baked 1 gold from Boulangerie!")

	return card


static func creerFerme():
	return null

static func creerForet():
	return null

static func creerVignoble():
	return null

static func creerMine():
	return null

static func creerVerger():
	return null

static func creerPetitBateauPeche():
	return null

static func creerEpicerie():
	return null

static func creerSuperette():
	return null

static func creerFromagerie():
	return null

static func creerFabriqueMeubles():
	return null

static func creerMoonsterSoda():
	return null

static func creerHalleMarche():
	return null

static func creerMarcheFL():
	return null

static func creerStade():
	return null

static func creerChaineTele():
	return null

static func creerMaisonEdition():
	return null

static func creerCentreImpots():
	return null

static func creerCafe():
	return null

static func creerMoonsterBurger():
	return null

static func creerRestaurantFamilial():
	return null


static func get_card_by_id(card_id: int) -> Establishment:
	match card_id:
		1:
			return creerChampsBlé()
		7:
			return creerBoulangerie()
		_:
			return null
