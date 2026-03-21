extends Node
@onready var game_play: Game_Play = $GamePlay


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var j1 = Player.new("j1", 0, 5)
	var j2 = Player.new("j2", 1, 5)
	
	var lesJouers : Array[Player] = []
	lesJouers.insert(0,j1)
	lesJouers.insert(1,j2)
	
	var game = Game.new(1,10,lesJouers,game_play)
	game.startGame()
