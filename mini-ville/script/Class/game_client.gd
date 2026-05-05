extends Node
class_name GameClient

var gameplayScreen
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
		"request_purple_choice":
			_handle_purple_choice(data)

func _handle_turn_started(data: Dictionary):
	var active_id = data.get("active_player_id", -1)
	var active_name = data.get("player_name", "Inconnu")
	is_my_turn = (active_id == my_player_id)
	
	if gameplayScreen:
		gameplayScreen.set_actions_enabled(is_my_turn)
		gameplayScreen.lbl_turn_announcement.text = tr("Tour de ") + active_name
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
	var shop_data = data.get("shop", {})
	
	if gameplayScreen and gameplayScreen.has_method("update_network_boards"):
		gameplayScreen.update_network_boards(players_data)
	if gameplayScreen and gameplayScreen.has_method("update_network_shop"):
		gameplayScreen.update_network_shop(shop_data)

func _handle_purple_choice(data: Dictionary):
	if not gameplayScreen: return
	
	var choice_type = data.get("choice_type", "")
	var response_payload = {
		"action": "game_action",
		"game_action": "purple_card_choice"
	}
	
	match choice_type:
		"choose_player":
			response_payload["target_id"] = await gameplayScreen.ask_choose_player() 
			
		"trade_cards":
			var trade_data = await gameplayScreen.ask_trade_cards()
			response_payload["my_card_id"] = trade_data[0]
			response_payload["target_id"] = trade_data[1]
			response_payload["target_card_id"] = trade_data[2]
			
		"give_card":
			var move_data = await gameplayScreen.ask_give_card()
			response_payload["my_card_id"] = move_data[0]
			response_payload["target_id"] = move_data[1]
			
		"demolish_monument":
			response_payload["monument_id"] = await gameplayScreen.ask_demolish_monument()

	NetworkManager.envoyer(response_payload)


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
