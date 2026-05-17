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

func receiveGold(amount: int) -> void:
	balance += amount
	
func loseGold(amount: int) -> void:
	var amountToPay = min(amount, balance)
	balance -= amountToPay

func buyCard(establishment: Establishment) -> bool:
	
	if balance < establishment.cost:
		return false
		
	if establishment.color == CardColor.Type.PURPLE:
		for instance in deck:
			if instance[0] == establishment.id:
				print(username, " tried to buy a duplicate Purple card!")
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

func activateEffect(color: int, game: GameServer, roller: Player) -> void: 
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
							var response = await game.request_player_choice("choose_player")
							var target_id = response.get("target_id", -1)
							var cible = _find_player_by_id(game.players, target_id)
							card.effect.choisir_cible(cible)
							
						elif card.effect is EffectEchange:
							var response = await game.request_player_choice("trade_cards")
							game.carte_owner_pour_echange = response.get("my_card_id", -1)
							game.adversaire_choisi_pour_echange = _find_player_by_id(game.players, response.get("target_id", -1))
							game.carte_adversaire_pour_echange = response.get("target_card_id", -1)
							
						elif card.effect is EffectDemenagement:
							var response = await game.request_player_choice("give_card")
							game.carte_choisie_pour_don = response.get("my_card_id", -1)
							game.adversaire_choisi_pour_don = _find_player_by_id(game.players, response.get("target_id", -1))
							
						elif card.effect is EffectDemolition:
							var response = await game.request_player_choice("demolish_monument")
							game.monument_choisi_pour_demolition = response.get("monument_id", -1)
						
						card.effect.appliquer(game, self, roller)
						
						if card.icon == Icon.Type.BREAD and monumentIsActive(Monument.MONUMENT_ID.Centre_Commercial):
							self.receiveGold(1)

func _find_player_by_id(player_array: Array, target_id: int) -> Player:
	for p in player_array:
		if p.id == target_id:
			return p
	return null
