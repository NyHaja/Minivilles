class_name Game
extends Node


var gameId:int

var timer:int
var goldInitAmount :int

var playerCount:int
var currentPlayerIndex:int
var playerArray : Array[Player]

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
		player.deck.push_back([0,1]) # A REVOIR METTRE LE VRAI ID DE LA CARTE !!!!!
		player.deck.push_back([0,1]) # A REVOIR
	
	
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
		
		var choice
		# choix = INPUT
		
		match  choice:
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
		player.activateEffect(Establishment.COLOR.RED, currentPlayer)
	# Bleu
	for player:Player in playerArray:
		player.activateEffect(Establishment.COLOR.BLUE, currentPlayer)
	#VERT
	currentPlayer.activateEffect(Establishment.COLOR.GREEN, currentPlayer)
	#Violet
	currentPlayer.activateEffect(Establishment.COLOR.PURPLE, currentPlayer)
	
	
		
#func lance
func skipPhase(hasConstructed) -> void:
	var player = getActivePlayer()
	if not(hasConstructed):
		if player.balance <=2:
			player.balance =  2
		# Monument Radio : pouvoir de relancer
		if getActivePlayer().monumentArray[Monument.MONUMENT_ID.Aeroport]:
			player.balance = player.balance + 10
	
func buyPhase(card_id:int):
	pass
func buildPhase(Monument_id):
	pass
