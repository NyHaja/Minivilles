extends Node

# L'IP privée de ta VM 1 (Base de données) et le port de ton API Python
const API_URL = "http://192.168.100.125:5000"

# ============================================================================
# MÉTHODES UTILITAIRES (POST ET GET)
# ============================================================================

func _send_post(endpoint: String, data: Dictionary, target: Object, method: String):
    var http_request = HTTPRequest.new()
    add_child(http_request)
    
    # Syntaxe Godot 3 pour les signaux avec des arguments supplémentaires (binds)
    http_request.connect("request_completed", self, "_on_request_completed", [http_request, target, method])
    
    var body = JSON.print(data) # JSON.print() dans Godot 3
    var headers = ["Content-Type: application/json"]
    
    # En Godot 3, la méthode request() prend un argument booléen pour le SSL
    http_request.request(API_URL + endpoint, headers, true, HTTPClient.METHOD_POST, body)

func _send_get(endpoint: String, target: Object, method: String):
    var http_request = HTTPRequest.new()
    add_child(http_request)
    
    http_request.connect("request_completed", self, "_on_request_completed", [http_request, target, method])
    
    http_request.request(API_URL + endpoint, ["Accept: application/json"], true, HTTPClient.METHOD_GET)


# ============================================================================
# FONCTION COMMUNE DE TRAITEMENT DES RÉPONSES
# ============================================================================

func _on_request_completed(_result, response_code, _headers, body, http_request, target, method):
    # 1. On détruit le noeud HTTPRequest
    http_request.queue_free()
    
    # 2. On lit le JSON renvoyé par l'API Python
    var json_response = null
    if body.size() > 0:
        var text_body = body.get_string_from_utf8()
        if text_body != "":
            var parse_result = JSON.parse(text_body) # JSON.parse() dans Godot 3
            if parse_result.error == OK:
                json_response = parse_result.result
        
    # 3. On déclenche la fonction de retour si elle existe
    if target and target.has_method(method):
        target.call_deferred(method, response_code, json_response)


# ============================================================================
# APPELS À L'API : JOUEURS ET INVITÉS
# ============================================================================

func register_player(nickname: String, password: String, email: String, avatar_url: String, target: Object, method: String):
    var data = {"nickname": nickname, "password": password, "email": email, "avatar_url": avatar_url}
    _send_post("/register", data, target, method)

func login(email: String, password: String, target: Object, method: String):
    var data = {"email": email, "password": password}
    _send_post("/login", data, target, method)

func register_guest(nickname: String, target: Object, method: String):
    var data = {"nickname": nickname}
    _send_post("/guest/register", data, target, method)

func check_guest_valid(guest_id: int, target: Object, method: String):
    _send_get("/guest/" + str(guest_id) + "/valid", target, method)


# ============================================================================
# APPELS À L'API : GESTION DES PARTIES
# ============================================================================

func create_game(player_id: int, player_type: String, target: Object, method: String):
    var data = {"player_id": player_id, "player_type": player_type}
    _send_post("/game/create", data, target, method)

func join_game(player_id: int, game_id: int, player_type: String, target: Object, method: String):
    var data = {"player_id": player_id, "game_id": game_id, "player_type": player_type}
    _send_post("/game/join", data, target, method)

func end_game(game_id: int, winner_id: int, winner_type: String, target: Object, method: String):
    var data = {"game_id": game_id, "winner_id": winner_id, "winner_type": winner_type}
    _send_post("/game/end", data, target, method)

func leave_game(player_id: int, game_id: int, player_type: String, target: Object, method: String):
    var data = {"player_id": player_id, "game_id": game_id, "player_type": player_type}
    _send_post("/game/leave", data, target, method)


# ============================================================================
# APPELS À L'API : HISTORIQUE
# ============================================================================

func insert_history(game_id: int, player_id, guest_id, card_id, monument_id, turn_number: int, action_type: String, dice_result: int, amount_exchanged: int, action_details: String, target: Object, method: String):
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
# APPELS À L'API : LECTURE DE DONNÉES / STATS
# ============================================================================

func count_participants(game_id: int, target: Object, method: String):
    _send_get("/game/" + str(game_id) + "/participants", target, method)

func get_winrate(email: String, target: Object, method: String):
    # En Godot 3, on utilise percent_encode() au lieu de uri_encode()
    _send_get("/player/winrate?email=" + email.percent_encode(), target, method)

func get_player_rank(player_id: int, target: Object, method: String):
    _send_get("/player/" + str(player_id) + "/rank", target, method)

func is_game_full(game_id: int, target: Object, method: String):
    _send_get("/game/" + str(game_id) + "/isfull", target, method)

func has_winner(game_id: int, target: Object, method: String):
    _send_get("/game/" + str(game_id) + "/haswinner", target, method)

func get_monument_price(monument_id: int, target: Object, method: String):
    _send_get("/monument/" + str(monument_id) + "/price", target, method)