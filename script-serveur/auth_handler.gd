extends Node

# ─────────────────────────────────────────
# POINT D'ENTRÉE
# ─────────────────────────────────────────
func handle(client: StreamPeerTLS, data: Dictionary):
	match data.get("action", ""):
		"register":        _handle_register(client, data)
		"authentification": _handle_authentification(client, data)
		"guest_player":    _handle_guest(client, data)
		"historic":        _handle_historic(client, data)
		"forgot_password": _handle_forgot_password(client, data)
		"get_stats": _handle_get_stats(client, data)

# ─────────────────────────────────────────
# REGISTER
# ─────────────────────────────────────────
func _handle_register(client: StreamPeerTLS, data: Dictionary):
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
func _handle_authentification(client: StreamPeerTLS, data: Dictionary):
	var email = data.get("email", "")
	var password_saisi = data.get("password","")
	
		
	var payload = { "email": email, 
					"password": password_saisi
		}
	$"../FlaskManager".send("login", "/login", payload, client,{"password": password_saisi})

# ─────────────────────────────────────────
# GUEST
# ─────────────────────────────────────────
func _handle_guest(client: StreamPeerTLS, data: Dictionary):
	var payload = {
		"nickname": data.get("nickname", "")
	}
	$"../FlaskManager".send("guest_player", "/guest/register", payload, client)



# ─────────────────────────────────────────
# FORGOT PASSWORD
# ─────────────────────────────────────────
func _handle_forgot_password(client: StreamPeerTLS, data: Dictionary):
	var payload = {
		"email": data.get("email", "")
	}
	$"../FlaskManager".send("forgot_password", "/forgot_password", payload, client)


# ─────────────────────────────────────────
# GET STATS
# ─────────────────────────────────────────
func _handle_get_stats(client: StreamPeerTLS, data: Dictionary):
	var player_id = data.get("player_id", get_parent().get_player_id(client))
	if player_id == null:
		get_parent().send_to_client(client, {
			"action_reply": "get_stats",
			"status": "error",
			"message": "player_id manquant."
		})
		return
	$"../FlaskManager".send_get("get_stats", "/player/" + str(int(player_id)) + "/stats", client)


# ─────────────────────────────────────────
# HISTORIC
# ─────────────────────────────────────────
func _handle_historic(client: StreamPeerTLS, data: Dictionary):
	var serveur = get_parent()
	var raw_player_id = serveur.get_player_id(client)
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
	var token = get_parent().get_token(client)
	$"../FlaskManager".send("historic", "/history/insert", payload, client,{}, token)
