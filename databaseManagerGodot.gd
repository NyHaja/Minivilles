extends Node

const API_URL = "http://192.168.100.125:5000"

# ============================================================================
# MÉTHODES UTILITAIRES (POST ET GET)
# ============================================================================

func _send_post(endpoint: String, data: Dictionary, target: Object, method: String):
	var http_request := HTTPRequest.new()
	add_child(http_request)

	http_request.request_completed.connect(
		Callable(self, "_on_request_completed").bind(http_request, target, method)
	)

	var body := JSON.stringify(data)
	var headers := ["Content-Type: application/json"]

	http_request.request(API_URL + endpoint, headers, HTTPClient.METHOD_POST, body)


func _send_get(endpoint: String, target: Object, method: String):
	var http_request := HTTPRequest.new()
	add_child(http_request)

	http_request.request_completed.connect(
		Callable(self, "_on_request_completed").bind(http_request, target, method)
	)

	http_request.request(API_URL + endpoint, ["Accept: application/json"], HTTPClient.METHOD_GET)


# ============================================================================
# TRAITEMENT DES RÉPONSES
# ============================================================================

func _on_request_completed(result, response_code, headers, body, http_request, target, method):
	http_request.queue_free()

	var json_response = null

	if body.size() > 0:
		var text_body: String = body.get_string_from_utf8()
		if text_body != "":
			json_response = JSON.parse_string(text_body)

	if target and target.has_method(method):
		target.call_deferred(method, response_code, json_response)


# ============================================================================
# API : JOUEURS / INVITÉS
# ============================================================================

func register_player(nickname: String, password: String, email: String, avatar_url: String, target: Object, method: String):
	var data = {
		"nickname": nickname,
		"password": password,
		"email": email,
		"avatar_url": avatar_url
	}
	_send_post("/register", data, target, method)


func login(email: String, password: String, target: Object, method: String):
	var data = {"email": email, "password": password}
	_send_post("/login", data, target, method)


func register_guest(nickname: String, target: Object, method: String):
	var data = {"nickname": nickname}
	_send_post("/guest/register", data, target, method)


func check_guest_valid(guest_id: int, target: Object, method: String):
	_send_get("/guest/%d/valid" % guest_id, target, method)


# ============================================================================
# API : PARTIES
# ============================================================================

func create_game(player_id: int, player_type: String, target: Object, method: String):
	var data = {"player_id": player_id, "player_type": player_type}
	_send_post("/game/create", data, target, method)


func join_game(player_id: int, game_id: int, player_type: String, target: Object, method: String):
	var data = {
		"player_id": player_id,
		"game_id": game_id,
		"player_type": player_type
	}
	_send_post("/game/join", data, target, method)


func end_game(game_id: int, winner_id: int, winner_type: String, target: Object, method: String):
	var data = {
		"game_id": game_id,
		"winner_id": winner_id,
		"winner_type": winner_type
	}
	_send_post("/game/end", data, target, method)


func leave_game(player_id: int, game_id: int, player_type: String, target: Object, method: String):
	var data = {
		"player_id": player_id,
		"game_id": game_id,
		"player_type": player_type
	}
	_send_post("/game/leave", data, target, method)


# ============================================================================
# API : HISTORIQUE
# ============================================================================

func insert_history(
	game_id: int,
	player_id,
	guest_id,
	card_id,
	monument_id,
	turn_number: int,
	action_type: String,
	dice_result: int,
	amount_exchanged: int,
	action_details: String,
	target: Object,
	method: String
):
	var data = {
		"game_id": game_id,
		"player_id": player_id,
		"guest_id": guest_id,
		"card_id": card_id,
		"monument_id": monument_id,
		"turn_number": turn_number,
		"action_type": action_type,
		"dice_result": dice_result,
		"amount_exchanged": amount_exchanged,
		"action_details": action_details
	}
	_send_post("/history/insert", data, target, method)


# ============================================================================
# API : STATS
# ============================================================================

func count_participants(game_id: int, target: Object, method: String):
	_send_get("/game/%d/participants" % game_id, target, method)


func get_winrate(email: String, target: Object, method: String):
	_send_get("/player/winrate?email=" + email.uri_encode(), target, method)


func get_player_rank(player_id: int, target: Object, method: String):
	_send_get("/player/%d/rank" % player_id, target, method)


func is_game_full(game_id: int, target: Object, method: String):
	_send_get("/game/%d/isfull" % game_id, target, method)


func has_winner(game_id: int, target: Object, method: String):
	_send_get("/game/%d/haswinner" % game_id, target, method)


func get_monument_price(monument_id: int, target: Object, method: String):
	_send_get("/monument/%d/price" % monument_id, target, method)

