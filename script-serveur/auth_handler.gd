extends Node

# ─────────────────────────────────────────
# POINT D'ENTRÉE
# ─────────────────────────────────────────
func handle(client: StreamPeerTCP, data: Dictionary):
	match data.get("action", ""):
		"register":        _handle_register(client, data)
		"authentification": _handle_authentification(client, data)
		"guest_player":    _handle_guest(client, data)
		"historic":        _handle_historic(client, data)

# ─────────────────────────────────────────
# REGISTER
# ─────────────────────────────────────────
func _handle_register(client: StreamPeerTCP, data: Dictionary):
	var payload = {
		"nickname":   data.get("nickname", ""),
		"password":   data.get("password", ""),
		"email":      data.get("email", ""),
		"avatar_url": data.get("avatar_url", "")
	}
	$"../FlaskManager".send("register", "/register", payload, client)

# ─────────────────────────────────────────
# LOGIN
# ─────────────────────────────────────────
func _handle_authentification(client: StreamPeerTCP, data: Dictionary):
	var payload = {
		"email":    data.get("email", ""),
		"password": data.get("password", "")
	}
	$"../FlaskManager".send("authentification", "/login", payload, client)

# ─────────────────────────────────────────
# GUEST
# ─────────────────────────────────────────
func _handle_guest(client: StreamPeerTCP, data: Dictionary):
	var payload = {
		"nickname": data.get("nickname", "")
	}
	$"../FlaskManager".send("guest_player", "/guest/register", payload, client)

# ─────────────────────────────────────────
# HISTORIC
# ─────────────────────────────────────────
func _handle_historic(client: StreamPeerTCP, data: Dictionary):
	var raw_player_id = data.get("player_id", -1)
	var raw_guest_id  = data.get("guest_id", -1)

	var payload = {
		"game_id":         data.get("game_id", ""),
		"turn_number":     data.get("turn_number", ""),
		"action_type":     data.get("action_type", ""),
		"dice_result":     data.get("dice_result", ""),
		"amount_exchanged": data.get("amount_exchanged", 0),
		"player_id":       null if raw_player_id == -1 else raw_player_id,
		"guest_id":        null if raw_guest_id  == -1 else raw_guest_id,
		"card_id":         data.get("card_id", ""),
		"monument_id":     data.get("monument_id", "")
	}
	$"../FlaskManager".send("historic", "/history/insert", payload, client)
