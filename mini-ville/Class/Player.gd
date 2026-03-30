extends Node
class_name Player

@export var username: String = ""

var id: int
var balance: int
var monumentCount: int
var establishmentCount: int
var deck: Array = []
var monumentArray: Dictionary = {}


func _init(_username: String, _id: int, _balance: int) -> void:
	self.username = _username
	self.id = _id
	self.balance = _balance
	self.monumentArray = {22: false, 23: false, 24: false, 25: false, 26: false, 27: false}

func getBalance() -> int:
	return balance

func recieveGold(amount: int) -> void:
	balance += amount
	
func loseGold(amount: int) -> void:
	var amountToPay = min(amount, balance)
	balance -= amountToPay

func buyCard(establishment: Establishment) -> bool:
	
	if balance < establishment.cost:
		return false
	balance -= establishment.cost
	
	var hasEstablishment = false
	
	for instance in deck:
		if instance[0] == establishment.id:
			instance[1] += 1
			hasEstablishment = true
			break
	if not hasEstablishment:
		deck.append([establishment.id, 1])
		
	establishmentCount += 1
	
	return true


func constructMonument(monument: Monument) -> bool:
	if balance < monument.cost:
		return false
	
	balance -= monument.cost
	
	monumentArray[monument.id] = true
	monumentCount += 1
	
	return true

func demolishMonument(monumentToDemolish: Monument) -> void:
	
	monumentArray[monumentToDemolish.id] = false
	monumentCount -= 1
	
func monumentIsActive(monumentId: int) -> bool:
	return monumentArray[monumentId]
	

func cardsWithIcon(icons: Array) -> int:
	var numberOfCards: int = 0
	for instance in deck:
		var cardId = instance[0]
		var quantity = instance[1]
		
		var card = get_card_from_factory(cardId)
		
		if card == null:
			continue
		
		if icons.has(card.icon):
			numberOfCards += quantity
			
	return numberOfCards

func activateEffect(color: int, game: Game, roller: Player) -> void: 
	var dice_roll = game.current_roll_value
	
	for instance in deck:
		# Safety check just in case the deck has flat numbers from old code!
		if typeof(instance) != TYPE_ARRAY:
			continue
			
		var cardId = instance[0]
		var quantity = instance[1]
		
		# Fetch the card using your local adapter
		var card = get_card_from_factory(cardId)
		
		# THE FAILSAFE: If the card is null (like ID 0), skip it immediately!
		if card == null:
			continue
		
		# 1. Check if the colors match
		if card.color == color:
			# 2. Check if the dice roll falls inside the teammate's [min, max] array!
			if dice_roll >= card.activation[0] and dice_roll <= card.activation[1]:
				# 3. Apply the effect for as many copies as the player owns
				for i in range(quantity):
					card.effect.appliquer(game, self, roller)
					# Check if Centre Commercial is active
					if monumentIsActive(Monument.MONUMENT_ID.Centre_Commercial):
						# Check if Icon is BREAD
						if card.icon == Icon.Type.BREAD:
							self.recieveGold(1)
							print("1 extra gold from Commercial Center!")
					


func get_card_from_factory(card_id: int) -> Establishment:
	match card_id:
		1: return CardFactory.creerChampsBlé()
		2: return CardFactory.creerFerme()
		3: return CardFactory.creerForet()
		4: return CardFactory.creerVignoble()
		5: return CardFactory.creerMine()
		6: return CardFactory.creerVerger()
		7: return CardFactory.creerBoulangerie()
		8: return CardFactory.creerSuperette()
		9: return CardFactory.creerFromagerie()
		10: return CardFactory.creerPetitBateauPeche()
		11: return CardFactory.creerFabriqueMeubles()
		12: return CardFactory.creerMoonsterSoda()
		13: return CardFactory.creerHalleMarche()
		14: return CardFactory.creerMarcheFL()
		15: return CardFactory.creerStade()
		16: return CardFactory.creerMaisonEdition()
		17: return CardFactory.creerCafe()
		18: return CardFactory.creerMoonsterBurger()
		19: return CardFactory.creerRestaurantFamilial()
		20: return CardFactory.creerCentreImpots()
		21: return CardFactory.creerEpicerie()
		_:
			return null
