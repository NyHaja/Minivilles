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
	var password_clair =  data.get("password", "")
	
	var password_hashe = $"../Hasher".PreparePasswordForDB(password_clair)	
	var payload = {
		"nickname":   data.get("nickname", ""),
		"password": password_hashe,
		"email":      data.get("email", ""),
		"avatar_url": data.get("avatar_url", "")
	}
	$"../FlaskManager".send("register", "/register", payload, client)

# ─────────────────────────────────────────
# LOGIN
# ─────────────────────────────────────────
func _handle_authentification(client: StreamPeerTCP, data: Dictionary):
	var email = data.get("email", "")
	var password_saisi = data.get("password","")
	
		
	var payload = { "email": email }
	$"../FlaskManager".send("get_auth_data", "/get_auth_data", payload, client,{"password": password_saisi})

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
