extends Node
class_name Player

@export var username: String = ""

var id: int
var balance: int
var monumentCount: int
var establishmentCount: int
var deck: Array = []
var monumentArray: Array = []


func _init(_username: String, _id: int, _balance: int) -> void:
	self.username = _username
	self.id = _id
	self.balance = balance

func getBalance() -> int:
	return balance

func recieveGold(amount: int) -> void:
	balance += amount
	
func loseGold(amount: int) -> void:
	var amountToPay = min(amount, balance)
	balance -= amountToPay

func buyCard(establishment: Establishment) -> void:
	
	if balance < establishment.cost:
		return
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


func constructMonument(monument: Monument) -> void:
	if balance < monument.cost:
		return
	
	balance -= monument.cost
	
	monumentArray[monument.id] = true
	monumentCount += 1

func demolishMonument(monumentToDemolish: Monument) -> void:
	
	monumentArray[monumentToDemolish.id] = false
	monumentCount -= 1
	
func monumentIsActive(monumentId: int) -> bool:
	return monumentArray[monumentId]
	

func cardsWithIcon(icons: Array[String]) -> int:
	var numberOfCards:int = 0
	for instance in deck:
		var cardId = instance[0]
		var quantity = instance[1]
		
		var card = CardFactory.get_card_by_id(cardId)
		
		for iconToCount in icons:
			if card.icon == iconToCount:
				numberOfCards += quantity
				
	return numberOfCards

func activateEffect(color: String, game: Game, roller: Player) -> void: # A REVOIR
	
	var dice_roll = game.current_roll_value
	
	for instance in deck:
		var cardId = instance[0]
		var quantity = instance[1]
		
		var card = CardFactory.get_card_by_id(cardId)
		
		if card.activationNumber == dice_roll && card.color == color:
			for i in range(quantity):
				card.effect.apply(self, roller)
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
