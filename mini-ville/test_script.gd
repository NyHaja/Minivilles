extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	
	print(" ---- TEST CREATION DE JOUEUR ----")
	print("\n")
	print("\n")
	
	var Player1 = Player.new("John", 0, 3)
	add_child(Player1)
	print("Created new Player: ")
	print(Player1.username)
	print(Player1.id)
	print(Player1.getBalance())
	
	
	print("\n")
	print("\n")
	
	print(" ---- TESTS SUR L'ECONOMIE ----")
	print("\n")
	print("\n")
		
	Player1.recieveGold(5)
	print(Player1.username, " received 5 Gold. Balance is now (8 expected): ", Player1.getBalance())
	print("\n")
	
	Player1.loseGold(100)
	print(Player1.username, " lost 100 Gold. Balance is now (0 expected): ", Player1.getBalance())
	print("\n")
	print("\n")
	
	print(" ---- TESTS POUR LES ETABLISSEMENTS ----")
	
	var test_establishment = Establishment.new()
	test_establishment.id = 2
	test_establishment.cost = 5
	var test_establishment2 = Establishment.new()
	test_establishment2.id = 4
	test_establishment2.cost = 5
	
	print("\n")
	
	print("Deck before buying a card: (not enough Gold) ", Player1.deck)
	Player1.buyCard(test_establishment)
	print("Deck after buying a card: (not enough Gold) ", Player1.deck)
	print("Establishment count: (0 expected): ", Player1.establishmentCount)
	
	print("\n")
	
	Player1.recieveGold(6)
	print("Deck before buying a card: (enough Gold) ", Player1.deck)
	Player1.buyCard(test_establishment)
	print("Deck after buying a card: (enough Gold) ", Player1.deck)
	print("Establishment count: (1 expected) ", Player1.establishmentCount)
	print("New Player balance: (1 expected) ", Player1.getBalance())
	
	print("\n")
	
	Player1.recieveGold(5)
	print("Deck before buying a new card: (enough Gold) ", Player1.deck)
	Player1.buyCard(test_establishment2)
	print("Deck after buying a new card: (enough Gold) ", Player1.deck)
	print("Establishment count: (2 expected) ", Player1.establishmentCount)
	
	print("\n")
	
	Player1.recieveGold(5)
	print("Deck before buying a same card: (enough Gold) ", Player1.deck)
	Player1.buyCard(test_establishment)
	print("Deck after buying a same card: (enough Gold) ", Player1.deck)
	print("Establishment count: (3 expected) ", Player1.establishmentCount)
	
	print("\n")
	print("\n")
	
	print(" ---- TESTS POUR LES MONUMENTS ----")
	
	print("\n")
	print("\n")
	
	var test_monument = Monument.new()
	test_monument.cost = 5
	test_monument.id = 1
	
	print("monumentArray before building a monument: (not enough Gold) ", Player1.monumentArray)
	Player1.constructMonument(test_monument)
	print("monumentArray after building a monument: (not enough Gold) ", Player1.monumentArray)
	print("Monument count: (0 expected): ", Player1.monumentCount)
	
	print("\n")
	
	Player1.recieveGold(5)
	print("monumentArray before building a monument: (enough Gold) ", Player1.monumentArray)
	Player1.constructMonument(test_monument)
	print("monumentArray after building a monument: (enough Gold) ", Player1.monumentArray)
	print("Monument count: (1 expected) ", Player1.monumentCount)
	print("New Player balance: (1 expected) ", Player1.getBalance())
	
