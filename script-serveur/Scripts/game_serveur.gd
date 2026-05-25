extends Node
class_name GameServer

var lobby_id: String
var players: Array = []
var currentPlayerIndex: int = 0
var shop: Shop
var current_roll_value: int = 0
var takes_bonus_turn: bool = false
var has_constructed_this_turn: bool = false

var carte_owner_pour_echange = null
var adversaire_choisi_pour_echange = null
var carte_adversaire_pour_echange = null
var carte_choisie_pour_don = null
var adversaire_choisi_pour_don = null
var monument_choisi_pour_demolition: int = -1
var pending_activations: Array = []
var turn_phase: String = "waiting_for_roll"

var last_d1: int = 0
var last_d2: int = 0

signal player_choice_received(choice_data: Dictionary)

func init_game(l_id: String, initial_players: Array, goldInitAmount: int = 3):
	self.lobby_id = l_id
	self.players = initial_players
	self.shop = Shop.new() 
	
	for p in players:
		p.balance = goldInitAmount
		p.deck.push_back([1, 1])
		p.deck.push_back([7, 1])
		p.monumentCount = 0
		
	print("[GameServer] Game initialized for lobby: ", lobby_id)
	
	_broadcast_sync_state()
	_broadcast_turn_start()

func handle_client_message(player_id, data: Dictionary):
	print("[DEBUG] Serveur a reçu : ", data) 
	if data.has("username"): print("[DEBUG] Pseudo : ", data["username"])
		
	var active_player = players[currentPlayerIndex]
	print("[GameServer] Received action '", data.get("game_action", "unknown"), "' from network ID: ", player_id)

	# --- CORRECTION GUEST : Système de secours si le routeur renvoie null ---
	var eff_player_id = player_id
	if eff_player_id == null:
		if data.has("guest_id"): eff_player_id = data["guest_id"]
		elif data.has("player_id"): eff_player_id = data["player_id"]
		
	if eff_player_id != null and str(active_player.id) != str(eff_player_id):
		print("[GameServer] REJECTED: Active is ", active_player.id, " but request came from ", eff_player_id)
		_broadcast_to_lobby({
			"action_reply": "debug_error",
			"message": "REJECTED: active_player=" + str(active_player.id) + " but sender=" + str(eff_player_id)
		})
		return
	elif eff_player_id == null:
		print("[GameServer] WARNING: Action accepted with null ID (Guest fallback)")

	print("[GameServer] ACCEPTED: Processing action...")
		
	match data.get("game_action", ""):
		"roll_dice":
			_server_dice_phase(data.get("amount", 1))
		"resolve_dice":
			_server_resolve_dice(data.get("modifier", "none"), data.get("amount_rolled", 1))
		"buy_card":
			_server_buy_phase(data.get("card_id", -1))
		"build_monument":
			_server_build_phase(data.get("monument_id", -1))
		"skip_turn":
			_server_skip_phase()
		"purple_card_choice":
			player_choice_received.emit(data)
		"ui_interaction":
			_server_ui_interaction(active_player, data)

func _server_dice_phase(amount: int):
	# --- LA BARRIÈRE DE SÉCURITÉ ---
	if turn_phase != "waiting_for_roll": 
		_broadcast_to_lobby({"action_reply": "debug_error", "message": "Phase de lancer invalide"})
		return
		
	turn_phase = "waiting_for_resolution"
	has_constructed_this_turn = false
	takes_bonus_turn = false
	
	var d1 = (randi() % 6) + 1
	var d2 = (randi() % 6) + 1 if amount == 2 else 0
	
	last_d1 = d1
	last_d2 = d2
	current_roll_value = d1 + d2

	print("[GameServer] _server_dice_phase: rolling d1=", d1, " d2=", d2, " lobby_id=", lobby_id)
	_broadcast_to_lobby({
		"action_reply": "dice_rolled",
		"d1": d1,
		"d2": d2,
		"amount_rolled": amount
	})

func _server_resolve_dice(modifier: String, amount_rolled: int):
	# --- LA BARRIÈRE DE SÉCURITÉ ---
	if turn_phase != "waiting_for_resolution":
		_broadcast_to_lobby({"action_reply": "debug_error", "message": "Phase de résolution invalide"})
		return
		
	var active_player = players[currentPlayerIndex]
	
	if modifier == "reroll" and active_player.monumentIsActive(Monument.MONUMENT_ID.Radio):
		print("[GameServer] Player used Radio Tower to reroll!")
		turn_phase = "waiting_for_roll" # On l'autorise exceptionnellement à relancer
		_server_dice_phase(amount_rolled)
		return 
		
	# --- ON FIGE LE SERVEUR ---
	turn_phase = "processing_effects" 
	current_roll_value = last_d1 + last_d2
	
	if modifier == "add2" and active_player.monumentIsActive(Monument.MONUMENT_ID.Port):
		if current_roll_value >= 10:
			current_roll_value += 2
		
	if active_player.monumentIsActive(Monument.MONUMENT_ID.Parc):
		if amount_rolled == 2 and last_d1 == last_d2:
			takes_bonus_turn = true
		
	_broadcast_to_lobby({
		"action_reply": "dice_resolved",
		"final_value": current_roll_value
	})
	
	# Le serveur attend impérativement la fin des cartes violettes
	await _execute_effect_phase(current_roll_value)
	
	# On libère le joueur pour qu'il puisse acheter
	turn_phase = "waiting_for_action"

func _execute_effect_phase(dice_value: int):
	var current_player = players[currentPlayerIndex]

	pending_activations.clear()
	
	for player in _get_players_counter_clockwise(current_player):
		player.activateEffect(CardColor.Type.RED, self, current_player) 
		
	for player in players:
		player.activateEffect(CardColor.Type.BLUE, self, current_player)
		
	current_player.activateEffect(CardColor.Type.GREEN, self, current_player)
	
	await current_player.activateEffect(CardColor.Type.PURPLE, self, current_player)
	
	_broadcast_sync_state()

func request_player_choice(action_type: String, metadata: Dictionary = {}) -> Dictionary:
	var active_player = players[currentPlayerIndex]
	
	# 👇 LA CORRECTION MAGIQUE : On vide la file d'attente des animations 
	# et on les envoie aux joueurs AVANT d'ouvrir le menu !
	_broadcast_sync_state()
	
	var serveur = get_parent().get_parent()
	if serveur and serveur.has_method("send_to_player"):
		serveur.send_to_player(int(active_player.id), {
			"action_reply": "request_purple_choice",
			"active_player_id": active_player.id,
			"choice_type": action_type,
			"metadata": metadata
		})
	
	var response = await self.player_choice_received
	return response

func _server_buy_phase(card_id: int):
	if turn_phase != "waiting_for_action":
		_broadcast_to_lobby({"action_reply": "debug_error", "message": "Ce n'est pas le moment d'agir"})
		return
	var active_player = players[currentPlayerIndex]
	var card_to_buy = CardFactory.get_card(card_id)
	
	if card_to_buy == null or not shop.available(card_id):
		_broadcast_to_lobby({"action_reply": "buy_error"})
		return 
		
	if active_player.buyCard(card_to_buy):
		shop.removeCardFromStock(card_id)
		has_constructed_this_turn = true
		_broadcast_sync_state()
		_advance_turn()
	else:
		# --- CORRECTION : On débloque le client si l'achat échoue ---
		_broadcast_to_lobby({"action_reply": "buy_error"}) 

func _server_build_phase(monument_id: int):
	if turn_phase != "waiting_for_action":
		_broadcast_to_lobby({"action_reply": "debug_error", "message": "Ce n'est pas le moment d'agir"})
		return
	var active_player = players[currentPlayerIndex]
	
	if active_player.monumentIsActive(monument_id):
		_broadcast_to_lobby({"action_reply": "buy_error"})
		return 
		
	var monument_data = _get_monument_data(monument_id)
	var monument_to_build = Monument.new()
	monument_to_build.id = monument_id
	monument_to_build.cost = monument_data.cost
	
	if active_player.constructMonument(monument_to_build):
		has_constructed_this_turn = true
		_broadcast_sync_state()
		
		if _verify_victory(active_player):
			_broadcast_to_lobby({
				"action_reply": "game_over",
				"winner_name": active_player.username
			})
			_record_match_history(active_player)
		else:
			_advance_turn()
	else:
		# --- CORRECTION : On débloque le client si la construction échoue ---
		_broadcast_to_lobby({"action_reply": "buy_error"})

func _server_skip_phase():
	if turn_phase != "waiting_for_action":
		_broadcast_to_lobby({"action_reply": "debug_error", "message": "Ce n'est pas le moment d'agir"})
		return
	var active_player = players[currentPlayerIndex]
	
	if not has_constructed_this_turn:
		if active_player.monumentIsActive(Monument.MONUMENT_ID.Aeroport):
			active_player.balance += 10
			
	if active_player.balance <= 2:
		active_player.balance = 2
	
	_broadcast_sync_state()
	_advance_turn()

func _advance_turn():
	if takes_bonus_turn:
		takes_bonus_turn = false
	else:
		currentPlayerIndex = (currentPlayerIndex + 1) % players.size()
		
	turn_phase = "waiting_for_roll" # <-- AJOUT : Prêt pour le lancer du nouveau joueur !
	_broadcast_turn_start()

func _broadcast_turn_start():
	var active_player = players[currentPlayerIndex]
	_broadcast_to_lobby({
		"action_reply": "turn_started",
		"active_player_id": active_player.id,
		"player_name": active_player.username
	})

func _broadcast_sync_state():
	var state_data = {}
	for p in players:
		state_data[p.id] = {
			"balance": p.balance, 
			"deck": p.deck, 
			"username": p.username,
			"monuments": p.monumentArray
		}
		
	var shop_data = {}
	for slot in shop.shop:
		if slot.id != -1 and slot.quantity > 0:
			shop_data[slot.id] = slot.quantity
			
	_broadcast_to_lobby({
		"action_reply": "sync_state",
		"players": state_data,
		"shop": shop_data,
		"activations": pending_activations.duplicate()
	})

	pending_activations.clear()

func _broadcast_to_lobby(payload: Dictionary):
	var serveur = get_parent().get_parent()
	print("[GameServer] _broadcast_to_lobby: action=", payload.get("action_reply","?"), " serveur=", serveur, " lobby_id=", lobby_id)
	if serveur and serveur.has_method("broadcast_lobby"):
		serveur.broadcast_lobby(lobby_id, payload)
	else:
		print("[GameServer] ERROR: serveur null or missing broadcast_lobby! serveur=", serveur)

func _record_match_history(winner: Player):
	var parent_server = get_parent().get_parent()
	var flask_manager = parent_server.get_node_or_null("FlaskManager")
	
	if flask_manager:
		var game_db_id = parent_server.lobbies[lobby_id].get("game_id", "")
		var payload = {
			"game_id": game_db_id,
			"turn_number": 999,
			"action_type": "game_won",
			"player_id": winner.id
		}
		
		flask_manager.send("historic", "/history/insert", payload, null)
		print("[GameServer] Victory saved to database for player: ", winner.username)

func _get_players_counter_clockwise(reference: Player) -> Array:
	var counter_clockwise_array = []
	var start_index = players.find(reference)
	var count = players.size()
	for i in range(1, count):
		var current_index = (start_index - i + count) % count
		counter_clockwise_array.append(players[current_index])
	return counter_clockwise_array

func _verify_victory(player: Player) -> bool:
	return player.monumentCount >= 5

func _get_monument_data(monument_id: int) -> Dictionary:
	match monument_id:
		Monument.MONUMENT_ID.Gare: return {"name": "Gare", "cost": 4}
		Monument.MONUMENT_ID.Centre_Commercial: return {"name": "Centre Commercial", "cost": 10}
		Monument.MONUMENT_ID.Parc: return {"name": "Parc d'Attractions", "cost": 16}
		Monument.MONUMENT_ID.Radio: return {"name": "Tour Radio", "cost": 22}
		Monument.MONUMENT_ID.Port: return {"name": "Port", "cost": 2}
		Monument.MONUMENT_ID.Aeroport: return {"name": "Aéroport", "cost": 30}
		_: return {"name": "Unknown Monument", "cost": 999}

func notifier_activation(joueur, card_id: int, balance_changes: Dictionary = {}):
	var changes_ids = {}
	for p in balance_changes:
		# Assure qu'on stocke l'ID sous forme de chaîne propre
		var p_id = str(p.id) if (typeof(p) == TYPE_OBJECT and p.get("id") != null) else str(p)
		changes_ids[p_id] = balance_changes[p]

	var j_id = joueur.id if (typeof(joueur) == TYPE_OBJECT and joueur.get("id") != null) else joueur
	
	pending_activations.append({
		"player_id": j_id,
		"card_id": card_id,
		"balance_changes": changes_ids
	})

func _server_ui_interaction(active_player: Player, data: Dictionary):
	# Le serveur ne fait que relayer l'action aux autres joueurs
	var payload = data.duplicate()
	payload["action_reply"] = "spectator_ui"
	payload["active_player_id"] = active_player.id
	
	_broadcast_to_lobby(payload)
