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
func handle(client: WebSocketPeer, data: Dictionary):
	var lobby_id = data.get("lobby_id", "")
	
	if lobby_id == "":
		var serveur = get_parent()
		for l_id in serveur.lobbies.keys():
			if client in serveur.lobbies[l_id]["joueurs"]:
				lobby_id = l_id
				break

	if active_games.has(lobby_id):
		var player_id = get_parent().get_player_id(client)
		print("[GameHandler] DEBUG routing to game. lobby=", lobby_id, " player_id=", player_id)
		var game_instance = active_games[lobby_id]
		game_instance.handle_client_message(player_id, data)
	else:
		print("[GameHandler] ERROR: Action received for unknown lobby: ", lobby_id)
		get_parent().send_to_client(client, {
			"action_reply": "debug_error",
			"message": "GameHandler: no active game for lobby '" + lobby_id + "'. Known: " + str(active_games.keys())
		})
