extends Node
class_name Player

@export var username: String = ""

var id: int
var balance: int
var monumentCount: int
var establishmentCount: int
var turnOrder: int
var diceResult: Array = [] # POURQUOI ARRAY?
var diceCount: bool
var hasConstructedThisTurn: bool

var establishments: Array = []
var monuments: Array = [] # PAS SUR UML MAIS SEMBLE UTILE


func throwDice(numberDice: int) -> int: # A FAIRE
	return 1

func account(diceResult: int) -> void: # A FAIRE
	return

func refreshAccount(card: Card, option: int) -> void: # A FAIRE
	return

func getBalance() -> int:
	return balance

func recieveGold(amount: int) -> void:
	balance += amount

func payGold(amount: int, destination: Player) -> bool:
	var paidExactGold: bool
	var amountToPay = min(amount, balance)
	
	paidExactGold = (amount == amountToPay)
	
	if destination != null:
		balance -= amountToPay
		destination.balance += amountToPay
	
	return paidExactGold

func payerBanque(amount: int) -> void:
	var amountToPay = min(amount, balance)
	balance -= amountToPay
	
func buyCard(establishment: Establishment) -> void:
	
	if balance < establishment.cost:
		return
	balance -= establishment.cost
	establishments.append(establishment)
	hasConstructedThisTurn = true


func constructMonument(monument: Monument) -> void:
	if balance < monument.cost:
		return
	
	balance -= monument.cost
	monumentCount += 1
	monuments.append(monument)
	hasConstructedThisTurn = true

func demolishMonument(monumentToDemolish: Monument) -> void:
	for monument in monuments:
		if monument.monumentName == monumentToDemolish.name:
			monuments.erase(monumentToDemolish)
			monumentCount -= 1

func giveEstablishment(establishment: Establishment, destination: Player) -> void:
	establishments.erase(establishment)
	destination.establishments.append(establishment)
	
func getCardsPerIconCount(icon: Icon) -> int: # A FAIRE
	return 1
	
func getCardPerIconsCount(icons: Icon) -> int: # A FAIRE
	return 1

func getMonumentCount() -> int:
	return monumentCount

func hasActifMonument(searchedName: String) -> bool:
	for monument in monuments:
		if monument.monumentName == searchedName:
			return true
	return false

func getEstablishments() -> Array:
	return establishments

func getNonPurpleEstablishments() -> Array:
	var nonPurpleEstablishments: Array = establishments
	for establishment in nonPurpleEstablishments:
		if establishment.color == GameEnums.color.PURPLE:
			nonPurpleEstablishments.erase(establishment)
	return nonPurpleEstablishments

func getMonuments() -> Array:
	return monuments

func getActifMonuments() -> Array: # PAREIL QUE getMonuments()??
	return monuments

func aGagne() -> bool:
	if monumentCount == 6:
		return true
	return false

func resetTurn() -> void:
	hasConstructedThisTurn = false
