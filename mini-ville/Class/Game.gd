class_name Game
extends Node


var gameId:int

var timer:int
var goldInitAmount :int

var playerCount:int
var currentPlayerIndex:int
var playerArray : Array[Player]
var current_roll_value = 0

var shop:Shop

var gameplayScreen:Game_Play # OBJET (ECRAN) où possède les function d'affichage et d'input

enum CHOICE {
	SKIP,
	Build_MONUMENT,
	Build_ESTABLISHMENT
}

# Constructeur
func _init(gameId:int,timer:int,players:Array[Player],eg:Game_Play,goldInitAmount:int = 3) -> void:
	self.timer = timer
	self.playerCount = players.size()
	self.playerArray = players
	self.gameId = gameId
	self.gameplayScreen = eg
	self.goldInitAmount = goldInitAmount
	shop = Shop.new() #Generer les xxx (a voir) carte dans la pioche
	
func startGame() ->void:
	# INIT
		#Donner champ blé et boulangerie a tout les joueur et 3 gold
	for player:Player in playerArray:
		player.recieveGold(goldInitAmount)
		player.deck.push_back([0, 1]) # A REVOIR METTRE LE VRAI ID DE LA CARTE !!!!!
		player.deck.push_back([1, 1]) # A REVOIR METTRE LE VRAI ID DE LA CARTE !!!!!
	
	
	var winner = false
	var hasConstructed = false
	var bonusTurn = false
	# LOOP de partie
	while not(winner):
		hasConstructed = false
		bonusTurn = false
		
		await gameplayScreen.RefreshBasicInfo(self)
		var resDice:int = await DicePhase()
		EffectPhase(resDice)
		
		var choice = await  gameplayScreen.buy()
		print(choice)
		# choix = INPUT
		
		match  choice[0]:
			CHOICE.Build_MONUMENT : 
				buildPhase(0)
			CHOICE.Build_ESTABLISHMENT : 
				buyPhase(0)
			CHOICE.SKIP : 
				skipPhase(hasConstructed)
		
		winner = verifyVictory(getActivePlayer())
		
		if not(bonusTurn):
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
	var resArray = await rollDice()
	
	# Monument Radio : pouvoir de relancer
	if getActivePlayer().monumentArray[Monument.MONUMENT_ID.Radio]:
		#RELANCER ?
		var reroll
		#relancer = INPUT
		if reroll:
			resArray = await rollDice()
			
	# Monument Parc Arctraction : douvle -> tour bonus
	if getActivePlayer().monumentArray[Monument.MONUMENT_ID.Parc]:
		if resArray[0] == resArray[1]:
			# TOUR BONUS
			pass
		pass
	
	var sum = resArray[0] + resArray[1]
	# Monument Port : resultat des >= 10, ajoutez +2.
	if getActivePlayer().monumentArray[Monument.MONUMENT_ID.Port]:
		if sum >= 10:
			sum = sum + 2
		pass
	current_roll_value = sum
	return sum

func rollDice() -> Array[int]:
	var res:Array[int]
	res.insert(0,(randi()%6) + 1)
	res.insert(1,0)

	var numberDice = 1
	
	if getActivePlayer().monumentArray[Monument.MONUMENT_ID.Gare]:
		numberDice = await gameplayScreen.rollDice() #INPUT
	if numberDice == 2:
		res.insert(1,(randi()%6) + 1)
		
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
	
	
		
#func lance
func skipPhase(hasConstructed) -> void:
	var player = getActivePlayer()
	if not(hasConstructed):
		if player.balance <=2:
			player.balance =  2
		# Monument Radio : pouvoir de relancer
		if getActivePlayer().monumentArray[Monument.MONUMENT_ID.Aeroport]:
			player.balance = player.balance + 10

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


func buyPhase(card_id:int) -> void:
	var active_player:Player = getActivePlayer()
	var card_to_buy = get_card_from_factory(card_id)
	
	if not shop.available(card_id):
		print("Card not in stock!")
	
	if active_player.buyCard(card_to_buy):
		shop.bought(active_player, card_id)
		print(active_player, " successfully bought ", card_to_buy.name)
	else:
		print("transaction failed")
	
	
func buildPhase(monument_id: int) -> void:
	var active_player = getActivePlayer()
	
	if active_player.monumentArray[monument_id] == true:
		print("Monument already build")
		return
		
	var monument_data = getMonumentData(monument_id)
	
	var monument_to_build = Monument.new()
	monument_to_build.id = monument_id
	monument_to_build.cost = monument_data.cost
	
	if active_player.constructMonument(monument_to_build):
		print(active_player, " successfully constructed ", monument_data.name) # AFFICHER LE NOM DU MONUNMENT
	else:
		print("Not enough gold!")
	
	
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
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
