extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	NetworkManager.message_recu.connect(_on_message)
	NetworkManager.connecte.connect(_on_connecte)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_connecte():
	NetworkManager.envoyer({
		"action": "authentification",
		"identification": "ton_email@test.com",
		"mot_de_passe": "tom_mot_de_passe"
	})

# Bouton pour créer un lobby
func _on_btn_creer_lobby_pressend():
	$LobbyHandler.creer_lobby("Partie Test", 4, false)
	
# Bouton pour lancer la partie
func _on_btn_lancer_pressed():
	$LobbyHandler.lancer_partie()
	
func _on_message(data: Dictionary):
	match data.get("action_reply", ""):
		"authentification":
			if data.get("status") == "success":
				print("[TEST] Login OK - joueur : ", data.get("played_id"))
			else:
				print("TEST Login échoué : ", data.get("message"))
