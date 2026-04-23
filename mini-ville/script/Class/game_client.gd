extends Node
class_name GameClient

var gameplayScreen # Reference to your main Jeu / UI node
var my_player_id: int
var is_my_turn: bool = false

func _ready():
	my_player_id = NetworkManager.get_joueur_id()
	
	NetworkManager.message_recu.connect(_on_server_message)
	print("[GameClient] Client ready. My ID is: ", my_player_id)

func _on_server_message(data: Dictionary):
	var action = data.get("action_reply", "")
	
	match action:
		"turn_started":
			_handle_turn_started(data)
			
		"dice_rolled":
			_handle_dice_rolled(data)
			
		"sync_state":
			_handle_sync_state(data)
			
		"game_over":
			if gameplayScreen and gameplayScreen.has_method("show_victory_screen"):
				gameplayScreen.show_victory_screen(data.get("winner_name", "Un joueur"))

func _handle_turn_started(data: Dictionary):
	var active_id = data.get("active_player_id", -1)
	var active_name = data.get("player_name", "Inconnu")
	is_my_turn = (active_id == my_player_id)
	
	if gameplayScreen:
		gameplayScreen.set_actions_enabled(is_my_turn)
		gameplayScreen.lbl_turn_announcement.text = "Tour de " + active_name
		# Show the dice rolling overlay only for the active player
		if is_my_turn and gameplayScreen.turn_overlay:
			gameplayScreen.turn_overlay.show()
		elif gameplayScreen.turn_overlay:
			gameplayScreen.turn_overlay.hide()

func _handle_dice_rolled(data: Dictionary):
	var d1 = data.get("d1", 1)
	var d2 = data.get("d2", 0)
	var amount_rolled = data.get("amount_rolled", 1)
	
	if gameplayScreen:
		if gameplayScreen.turn_overlay:
			gameplayScreen.turn_overlay.hide()
			
		var modifier = await gameplayScreen.showResult(d1, d2, false) 
		
		if is_my_turn:
			request_resolve_dice(modifier, amount_rolled)

func _handle_sync_state(data: Dictionary):
	var players_data = data.get("players", {})
	
	if gameplayScreen and gameplayScreen.has_method("update_network_boards"):
		gameplayScreen.update_network_boards(players_data)



func request_roll_dice(amount: int):
	if not is_my_turn: return
	NetworkManager.envoyer({
		"action": "game_action",
		"game_action": "roll_dice",
		"amount": amount
	})

func request_resolve_dice(modifier: String, amount_rolled: int):
	if not is_my_turn: return
	NetworkManager.envoyer({
		"action": "game_action",
		"game_action": "resolve_dice",
		"modifier": modifier,
		"amount_rolled": amount_rolled
	})

func request_buy_card(card_id: int):
	if not is_my_turn: return
	NetworkManager.envoyer({
		"action": "game_action",
		"game_action": "buy_card",
		"card_id": card_id
	})

func request_build_monument(monument_id: int):
	if not is_my_turn: return
	NetworkManager.envoyer({
		"action": "game_action",
		"game_action": "build_monument",
		"monument_id": monument_id
	})

func request_skip_turn():
	if not is_my_turn: return
	NetworkManager.envoyer({
		"action": "game_action",
		"game_action": "skip_turn"
	})
