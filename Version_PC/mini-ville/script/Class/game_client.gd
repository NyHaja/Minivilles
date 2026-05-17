extends Node
class_name GameClient

var gameplayScreen
var my_player_id: int
var is_my_turn: bool = false

var current_lobby_id = LobbyHandler.get_lobby_id()

var cached_sync_data: Dictionary = {}
var cached_turn_data: Dictionary = {}

func _ready():
	NetworkManager.message_recu.connect(_on_server_message)
	print("[GameClient] Client ready. My ID is: ", my_player_id)

func _on_server_message(data: Dictionary):
	print("[GameClient] Message received: ", data.get("action_reply", data.get("action", "unknown")))
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
	if not gameplayScreen or not is_instance_valid(gameplayScreen):
		cached_turn_data = data
		return

	var active_id = data.get("active_player_id", -1)
	is_my_turn = (int(active_id) == int(my_player_id))

	# Delegate to jeu_multi, which will delay showing the overlay
	# until all fly animations (deck→shop, shop→hand) have finished.
	if gameplayScreen.has_method("try_show_turn_overlay"):
		gameplayScreen.try_show_turn_overlay(data)
	else:
		# Fallback for non-multiplayer screens
		gameplayScreen.set_actions_enabled(is_my_turn)

func _handle_dice_rolled(data: Dictionary):
	print(">>> [GameClient] _handle_dice_rolled called! d1=", data.get("d1"), " d2=", data.get("d2"))
	var d1 = data.get("d1", 1)
	var d2 = data.get("d2", 0)
	var amount_rolled = data.get("amount_rolled", 1)
	
	if gameplayScreen and is_instance_valid(gameplayScreen):
		if gameplayScreen.turn_overlay:
			gameplayScreen.turn_overlay.hide()
		
		if is_my_turn:
			var modifier = await gameplayScreen.showResult(d1, d2, false)
			request_resolve_dice(modifier, amount_rolled)
		else:
			await gameplayScreen.showResult(d1, d2, false, true)

func _handle_sync_state(data: Dictionary):
	print("[GameClient] _handle_sync_state called. gameplayScreen valid: ", gameplayScreen and is_instance_valid(gameplayScreen))
	if gameplayScreen and is_instance_valid(gameplayScreen):
		# jeu_multi._on_network_message handles sync_state directly (including gold animations).
		# Calling update_network_boards here would overwrite latest_players_data before
		# jeu_multi can diff the old vs new balances, killing the gold float animations.
		pass
	else:
		cached_sync_data = data
		print("[GameClient] Caught sync_state during loading screen!")

func _handle_purple_choice(data: Dictionary):
	if int(data.get("active_player_id", -1)) != int(my_player_id):
		return
		
	if not gameplayScreen or not is_instance_valid(gameplayScreen): return
	
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
	print(">>> [GameClient] Clicked Roll Dice! Amount: ", amount)
	print(">>> [GameClient] Security Check -> my_id: ", my_player_id, " | is_my_turn: ", is_my_turn)
	
	if not is_my_turn: 
		print(">>> [GameClient] FAIL: The client thinks it is not your turn. Aborting send!")
		return
		
	print(">>> [GameClient] SUCCESS: Sending roll request to server... lobby_id=", current_lobby_id)
	NetworkManager.envoyer({
		"action": "game_action",
		"game_action": "roll_dice",
		"lobby_id": current_lobby_id,
		"amount": amount
	})

func request_resolve_dice(modifier: String, amount_rolled: int):
	if not is_my_turn: return
	# NOTE: is_my_turn stays true — player still needs to buy or skip after this
	NetworkManager.envoyer({
		"action": "game_action",
		"game_action": "resolve_dice",
		"lobby_id": current_lobby_id,
		"modifier": modifier,
		"amount_rolled": amount_rolled
	})

func request_buy_card(card_id: int):
	if not is_my_turn: return
	is_my_turn = false  # End of turn
	NetworkManager.envoyer({
		"action": "game_action",
		"game_action": "buy_card",
		"lobby_id": current_lobby_id,
		"card_id": card_id
	})

func request_build_monument(monument_id: int):
	if not is_my_turn: return
	is_my_turn = false  # End of turn
	NetworkManager.envoyer({
		"action": "game_action",
		"game_action": "build_monument",
		"lobby_id": current_lobby_id,
		"monument_id": monument_id
	})

func request_skip_turn():
	if not is_my_turn: return
	is_my_turn = false  # End of turn
	NetworkManager.envoyer({
		"action": "game_action",
		"game_action": "skip_turn",
		"lobby_id": current_lobby_id,
	})
