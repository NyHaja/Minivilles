extends Jeu

func _ready() -> void:
	super._ready()

	var les_joueurs: Array[Player] = []

	les_joueurs.append(Player.new("Player 1", 0, 0))
	les_joueurs.append(Player.new("Player 2", 1, 0))

	var game = GameScenario.new(1, 10, les_joueurs, self, 0)
	add_child(game)

	game.startGame()
