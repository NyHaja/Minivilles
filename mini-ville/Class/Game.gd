class_name Game
extends Node


var gameId:int

var timer:int
var goldInitAmount :int

var playerCount:int
var currentPlayerIndex:int
var playerArray : Array[Player]
var current_roll_value = 0
var takes_bonus_turn: bool = false

var shop:Shop

var gameplayScreen:Jeu # OBJET (ECRAN) où possède les function d'affichage et d'input

enum CHOICE {
	SKIP,
	Build_MONUMENT,
	Build_ESTABLISHMENT
}

# Constructeur
func _init(gameId:int,timer:int,players:Array[Player],eg:Jeu,goldInitAmount:int = 3) -> void:
	self.timer = timer
	self.playerCount = players.size()
	self.playerArray = players
	self.gameId = gameId
	self.gameplayScreen = eg
	self.goldInitAmount = goldInitAmount
	self.currentPlayerIndex = 0 # RANDOM
	shop = Shop.new() #Generer les xxx (a voir) carte dans la pioche
	
func startGame() ->void:
	# INIT
	#Donner champ blé et boulangerie a tout les joueur et 3 gold
	for player:Player in playerArray:
		player.recieveGold(goldInitAmount)
		player.deck.push_back([1, 1])
		player.deck.push_back([7, 1])
	
	
	var winner = false
	var hasConstructed = false
	var bonusTurn = false
	var action_successful = false
	# LOOP de partie
	while not(winner):
		hasConstructed = false
		bonusTurn = false
		action_successful = false
		
		await gameplayScreen.RefreshBasicInfo(self)
		var resDice:int = await DicePhase()
		EffectPhase(resDice)
		
		while not action_successful:
		
			var choice = await gameplayScreen.pause()
			print(choice)
			# choix = INPUT
			
			match  choice[0]:
				CHOICE.Build_MONUMENT : 
					action_successful = buildPhase(choice[1])
				CHOICE.Build_ESTABLISHMENT : 
					action_successful = buyPhase(choice[1])
				CHOICE.SKIP : 
					skipPhase(hasConstructed)
					action_successful = true
					
			if not action_successful:
				print("Action failed. Try something else!")
			
		winner = verifyVictory(getActivePlayer())
		
		if winner == true:
			print(getActivePlayer().username, " has won the game!")
			gameplayScreen.show_victory_screen(getActivePlayer().username)
			break
			
		if takes_bonus_turn == true:
			print("Extra turn for ", getActivePlayer().username)
		else:
			currentPlayerIndex = (currentPlayerIndex + 1) % playerArray.size()
		
		
func getActivePlayer() -> Player:
	return playerArray[currentPlayerIndex % playerCount ]

func getPlayerCounterClockwise(reference:Player) -> Array[Player]:
	var counter_clockwise_array: Array[Player] = []
	var start_index = playerArray.find(reference)
	
	for i in range(playerCount):
		var current_index = (start_index - i + playerCount) % playerCount
		counter_clockwise_array.append(playerArray[current_index])
		
	return counter_clockwise_array


func verifyVictory(player:Player) -> bool:
	return player.monumentCount == 5

func finishGame(winner:Player) -> void:
	# mise à jour des stat à envoie pour le BDD
	pass


func DicePhase() -> int:
	var numberDice = await gameplayScreen.waitForDiceRoll()
	
	var resArray = rollDice(numberDice)
	
	# Monument Radio : pouvoir de relancer
	if getActivePlayer().monumentArray[Monument.MONUMENT_ID.Radio]:
		#RELANCER ?
		var wants_reroll = await gameplayScreen.ask_yes_no("Use Radio Tower to reroll?")
		if wants_reroll:
			numberDice = await gameplayScreen.waitForDiceRoll()
			
			resArray = rollDice(numberDice)
		
		takes_bonus_turn = false
		
	# Monument Parc Arctraction : double -> tour bonus
	if getActivePlayer().monumentArray[Monument.MONUMENT_ID.Parc]:
		if numberDice == 2 && resArray[0] == resArray[1]:
			print("Bonus turn earned!")
			takes_bonus_turn = true
	
	var sum = resArray[0] + resArray[1]
	# Monument Port : resultat des >= 10, ajoutez +2.
	if getActivePlayer().monumentArray[Monument.MONUMENT_ID.Port]:
		var add2
		if add2:
			if sum >= 10:
				var wants_add2 = await gameplayScreen.ask_yes_no("Add 2 to roll?")
				if wants_add2:
					sum = sum + 2
	
	current_roll_value = sum
	return sum

func rollDice(numberDice: int) -> Array[int]:
	var res:Array[int] = [0, 0]
	res[0] = (randi() %6) + 1
	if numberDice == 2:
		res[1] = (randi() %6) + 1
		
	gameplayScreen.showResult(res[0],res[1])
	return res

func EffectPhase(resDice) -> void:
	var currentPlayer = getActivePlayer()
	# ROUGE
	for player:Player in getPlayerCounterClockwise(getActivePlayer()):
		player.activateEffect(Establishment.COLOR.RED, self, currentPlayer)
	# Bleu
	for player:Player in playerArray:
		player.activateEffect(Establishment.COLOR.BLUE, self, currentPlayer)
	#VERT
	currentPlayer.activateEffect(Establishment.COLOR.GREEN, self, currentPlayer)
	#Violet
	currentPlayer.activateEffect(Establishment.COLOR.PURPLE, self, currentPlayer)
	
	

func get_card_from_factory(card_id: int) -> Establishment: # PLACEHOLDER 
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

		
#func lance
func skipPhase(hasConstructed) -> void:
	var player = getActivePlayer()
	if not(hasConstructed):
		if player.balance <=2:
			player.balance =  2
		# Monument Radio : pouvoir de relancer
		if getActivePlayer().monumentArray[Monument.MONUMENT_ID.Aeroport]:
			player.balance = player.balance + 10

func buyPhase(card_id:int) -> bool:
	var active_player:Player = getActivePlayer()
	var card_to_buy = get_card_from_factory(card_id)
	
	if card_to_buy == null:
		print("cart_to_but = null!")
		return false
		
	if not shop.available(card_id):
		print("Card not in stock!")
		return false
	
	if active_player.buyCard(card_to_buy):
		shop.removeCardFromStock(card_id)
		print(active_player.username, " successfully bought ", card_to_buy.name)
		return true
	else:
		print("transaction failed")
		return false
	
	
	
func buildPhase(monument_id: int) -> bool:
	var active_player = getActivePlayer()
	
	if active_player.monumentArray[monument_id] == true:
		print("Monument already build")
		return false
		
	var monument_data = getMonumentData(monument_id)
	
	var monument_to_build = Monument.new()
	monument_to_build.id = monument_id
	monument_to_build.cost = monument_data.cost
	
	if active_player.constructMonument(monument_to_build):
		print(active_player.username, " successfully constructed ", monument_data.name) # AFFICHER LE NOM DU MONUNMENT
		return true
	else:
		print("Not enough gold!")
		return false
	
	
func getMonumentData(monument_id: int) -> Dictionary: # VALEURS A REVOIR
	match monument_id:
		Monument.MONUMENT_ID.Gare: 
			return {"name": "Gare", "cost": 4}
		Monument.MONUMENT_ID.Centre_Commercial: 
			return {"name": "Centre Commercial", "cost": 10}
		Monument.MONUMENT_ID.Parc: 
			return {"name": "Parc d'Attractions", "cost": 16}
		Monument.MONUMENT_ID.Radio: 
			return {"name": "Tour Radio", "cost": 22}
		Monument.MONUMENT_ID.Port: 
			return {"name": "Port", "cost": 2} 
		Monument.MONUMENT_ID.Aeroport: 
			return {"name": "Aéroport", "cost": 30} 
		_: 
			return {"name": "Unknown Monument", "cost": 999}
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
