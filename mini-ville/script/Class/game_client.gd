extends Node
class_name GameClient

var gameplayScreen
var my_player_id: int
var is_my_turn: bool = false
var active_player_id: int = -1 # <-- Indispensable pour la synchro visuelle

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
		"dice_resolved": # <-- Indispensable pour débloquer les spectateurs
			_handle_dice_resolved(data)
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

	active_player_id = int(data.get("active_player_id", -1))
	is_my_turn = (active_player_id == int(my_player_id))

	if gameplayScreen.has_method("try_show_turn_overlay"):
		gameplayScreen.try_show_turn_overlay(data)
	else:
		gameplayScreen.set_actions_enabled(is_my_turn)

func _handle_dice_rolled(data: Dictionary):
	var d1 = data.get("d1", 1)
	var d2 = data.get("d2", 0)
	var amount_rolled = data.get("amount_rolled", 1)
	
	if gameplayScreen and is_instance_valid(gameplayScreen):
		# Gestion du Relancer (Tour Radio) si on est spectateur
		if not is_my_turn and gameplayScreen.result_overlay and gameplayScreen.result_overlay.visible:
			gameplayScreen.force_dice_decision("reroll")
			await get_tree().create_timer(0.1).timeout
			
		if gameplayScreen.turn_overlay:
			gameplayScreen.turn_overlay.hide()
			
		gameplayScreen.set_meta("last_d1", d1)
		gameplayScreen.set_meta("last_d2", d2)
		
		if is_my_turn:
			var my_data = gameplayScreen.latest_players_data.get(str(my_player_id), {})
			var can_reroll = my_data.get("monuments", {}).get("24", false) or my_data.get("monuments", {}).get(24, false)
			
			var modifier = await gameplayScreen.showResult(d1, d2, can_reroll, false, active_player_id)
			request_resolve_dice(modifier, amount_rolled)
		else:
			await gameplayScreen.showResult(d1, d2, false, true, active_player_id)

func _handle_dice_resolved(data: Dictionary):
	# On débloque l'écran du spectateur selon la décision finale envoyée par le serveur
	if not is_my_turn and gameplayScreen and is_instance_valid(gameplayScreen):
		var final_value = data.get("final_value", 0)
		var d1 = gameplayScreen.get_meta("last_d1", 0)
		var d2 = gameplayScreen.get_meta("last_d2", 0)
		
		if final_value > (d1 + d2):
			gameplayScreen.force_dice_decision("add2")
		else:
			gameplayScreen.force_dice_decision("keep")

func _handle_sync_state(data: Dictionary):
	if not gameplayScreen or not is_instance_valid(gameplayScreen):
		cached_sync_data = data

func _handle_purple_choice(data: Dictionary):
	if int(data.get("active_player_id", -1)) != int(my_player_id): return
	if not gameplayScreen or not is_instance_valid(gameplayScreen): return
	
	var choice_type = data.get("choice_type", "")
	var response_payload = {"action": "game_action", "game_action": "purple_card_choice"}
	
	match choice_type:
		"choose_player": response_payload["target_id"] = await gameplayScreen.ask_choose_player() 
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
	NetworkManager.envoyer({"action": "game_action", "game_action": "roll_dice", "lobby_id": current_lobby_id, "amount": amount})

func request_resolve_dice(modifier: String, amount_rolled: int):
	if not is_my_turn: return
	NetworkManager.envoyer({"action": "game_action", "game_action": "resolve_dice", "lobby_id": current_lobby_id, "modifier": modifier, "amount_rolled": amount_rolled})

func request_buy_card(card_id: int):
	if not is_my_turn: return
	is_my_turn = false  
	NetworkManager.envoyer({"action": "game_action", "game_action": "buy_card", "lobby_id": current_lobby_id, "card_id": card_id})

func request_build_monument(monument_id: int):
	if not is_my_turn: return
	is_my_turn = false  
	NetworkManager.envoyer({"action": "game_action", "game_action": "build_monument", "lobby_id": current_lobby_id, "monument_id": monument_id})

func request_skip_turn():
	if not is_my_turn: return
	is_my_turn = false  
	NetworkManager.envoyer({"action": "game_action", "game_action": "skip_turn", "lobby_id": current_lobby_id})
