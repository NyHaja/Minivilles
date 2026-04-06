extends Node

@onready var jeu: Jeu = $Jeu

func _ready() -> void:
	var lesJouers : Array[Player] = []
	
	if GameData.player_names.is_empty():
		print("No names found in GameData. Using default testing names.")
		GameData.player_names = ["Test P1", "Test P2"]
		
	for i in range(GameData.player_names.size()):
		var p_name = GameData.player_names[i]
		
		var new_player = Player.new(p_name, i, 0)
		lesJouers.append(new_player)
	
	var game = Game.new(1, 10, lesJouers, jeu)
	add_child(game)
	
	game.startGame()
