extends Node

var active_games: Dictionary = {}
const GameServerScene = preload("res://Scripts/game_serveur.gd") 

# ─────────────────────────────────────────
# 1. START A NEW GAME
# ─────────────────────────────────────────
func start_new_game(lobby_id: String, players: Array):
	print("[GameHandler] Spawning new game instance for lobby: ", lobby_id)
	
	var new_game = GameServerScene.new()
	add_child(new_game)
	
	active_games[lobby_id] = new_game
	
	new_game.init_game(lobby_id, players)

# ─────────────────────────────────────────
# 2. ROUTE ACTIONS TO THE CORRECT GAME
# ─────────────────────────────────────────
func handle(client: StreamPeerTLS, data: Dictionary):
	var lobby_id = data.get("lobby_id", "")
	
	if active_games.has(lobby_id):
		var player_id = get_parent().get_player_id(client) 
		
		var game_instance = active_games[lobby_id]
		game_instance.handle_client_message(player_id, data)
	else:
		print("[GameHandler] ERROR: Action received for unknown lobby: ", lobby_id)
