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
		
		var card = CardFactory.get_card(cardId)
		
		if card == null:
			continue
		
		if icons.has(card.icon):
			numberOfCards += quantity
			
	return numberOfCards

func activateEffect(color: int, game: Game, roller: Player) -> void: 
	var dice_roll = game.current_roll_value
	
	for instance in deck:
		if typeof(instance) != TYPE_ARRAY:
			continue
			
		var cardId = instance[0]
		var quantity = instance[1]
		
		var card = CardFactory.get_card(cardId)
		
		if card == null:
			continue
		
		if card.color == color:
			if dice_roll >= card.activation[0] and dice_roll <= card.activation[1]:
				if card.effect.peutActiver(game, self, roller):
					for i in range(quantity):
						if card.effect is EffectVolChoix:
							var cible = await game.gameplayScreen.ask_choose_player(self, game.playerArray)
							card.effect.choisir_cible(cible)
							
						elif card.effect is EffectEchange:
							var trade_data = await game.gameplayScreen.ask_trade_cards(self, game.playerArray)
							game.carte_owner_pour_echange = trade_data[0]
							game.adversaire_choisi_pour_echange = trade_data[1]
							game.carte_adversaire_pour_echange = trade_data[2]
							
						elif card.effect is EffectDemenagement:
							var move_data = await game.gameplayScreen.ask_give_card(self, game.playerArray)
							game.carte_choisie_pour_don = move_data[0]
							game.adversaire_choisi_pour_don = move_data[1]
							
						elif card.effect is EffectDemolition:
							var monu_id = await game.gameplayScreen.ask_demolish_monument(self)
							game.monument_choisi_pour_demolition = monu_id
						
						card.effect.appliquer(game, self, roller)
						
						if card.icon == Icon.Type.BREAD and monumentIsActive(Monument.MONUMENT_ID.Centre_Commercial):
							self.recieveGold(1)
							print(username, " gagne 1 pièce bonus (Centre Commercial) !")
