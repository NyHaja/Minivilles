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

var carte_owner_pour_echange: int = -1
var adversaire_choisi_pour_echange: Player = null
var carte_adversaire_pour_echange: int = -1

var carte_choisie_pour_don: int = -1
var adversaire_choisi_pour_don: Player = null

var monument_choisi_pour_demolition: int = -1

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
		player.receiveGold(goldInitAmount)
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
		await EffectPhase(resDice)
		
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
	
	for i in range(1, playerCount):
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
	
	var can_reroll = getActivePlayer().monumentIsActive(Monument.MONUMENT_ID.Radio)
	var choix = await gameplayScreen.showResult(resArray[0], resArray[1], can_reroll)
	
	# --- 1. GESTION DE LA RELANCE (Tour Radio) ---
	if choix == "reroll":
		print("Player used Radio Tower to reroll!")
		resArray = rollDice(numberDice)
		choix = await gameplayScreen.showResult(resArray[0], resArray[1], false)
		
	var sum = resArray[0] + resArray[1]
	
	# --- 2. GESTION DU BONUS (Port) ---
	if choix == "add2":
		print("Player used Port to add 2 to the dice!")
		sum += 2
	
	# --- 3. GESTION DU TOUR BONUS (Parc d'attraction) ---
	takes_bonus_turn = false
	if getActivePlayer().monumentIsActive(Monument.MONUMENT_ID.Parc):
		if numberDice == 2 and resArray[0] == resArray[1]:
			print("Bonus turn earned!")
			takes_bonus_turn = true
	
	current_roll_value = sum
	return sum

func rollDice(numberDice: int) -> Array[int]:
	var res:Array[int] = [0, 0]
	#res[0] = (randi() %6) + 1
	res[0] = 1
	
	#if numberDice == 2:
	res[1] = 2 #(randi() %6) + 1
		
	return res

func EffectPhase(resDice) -> void:
	var currentPlayer = getActivePlayer()
	# ROUGE
	for player:Player in getPlayerCounterClockwise(getActivePlayer()):
		await player.activateEffect(CardColor.Type.RED, self, currentPlayer)
	# Bleu
	for player:Player in playerArray:
		await player.activateEffect(CardColor.Type.BLUE, self, currentPlayer)
	#VERT
	await currentPlayer.activateEffect(CardColor.Type.GREEN, self, currentPlayer)
	#Violet
	await currentPlayer.activateEffect(CardColor.Type.PURPLE, self, currentPlayer)
	
	await gameplayScreen.executer_animations_collectees()


		
#func lance
func skipPhase(hasConstructed) -> void:
	var player = getActivePlayer()
	if not(hasConstructed):
		if player.balance <=2:
			player.balance =  2
		# Monument Radio : pouvoir de relancer
		if getActivePlayer().monumentIsActive(Monument.MONUMENT_ID.Aeroport):
			player.balance = player.balance + 10

func buyPhase(card_id:int) -> bool:
	var active_player:Player = getActivePlayer()
	var card_to_buy = CardFactory.get_card(card_id)
	
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
	
	if active_player.monumentIsActive(monument_id):
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
	
	
	
	
	
	
	
	
	
	
	
	
