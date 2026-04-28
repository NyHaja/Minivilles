extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	NetworkManager.message_recu.connect(_on_message)
	NetworkManager.connecte.connect(_on_connecte)
	# ------------ signal ----------------------------
	LobbyHandler.joueur_mis_a_jour.connect(_on_joueurs_mis_a_jour)
	LobbyHandler.lobby_creer_signal.connect(_on_lobby_cree)
	# ------------------------------------------------
	#affiche le code du lobby
	#$HBoxContainer/lancer.visible = LobbyHandler.is_host()
	
	var lobby_id = LobbyHandler.get_lobby_id()
	if lobby_id != "":
		$LabelCode.text = lobby_id
		_rafraichir_liste(LobbyHandler.get_joueurs())

func _on_lobby_cree(lobby_id: String):
	$LabelCode.text = lobby_id
	$HBoxContainer/creer.disabled = false
	# Afficher le host dans la liste imédiatement
	_rafraichir_liste(LobbyHandler.get_joueurs())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_connecte():
	NetworkManager.envoyer({
		"action": "authentification",
		"email": "atg230@gmail.com",
		"password": "test123"
	})

# Bouton pour créer un lobby
func _on_btn_creer_lobby_pressed():
	$HBoxContainer/creer.disabled = true  # éviter les doubles clics
	LobbyHandler.creer_lobby("Partie", 2, true)
	
# Bouton pour lancer la partie
func _on_btn_lancer_pressed():
	LobbyHandler.lancer_partie()
	
func _on_message(data: Dictionary):
	match data.get("action_reply", ""):
		"authentification":
			if data.get("status") == "success":
				print("[TEST] Login OK - joueur : ", data.get("player_id"))
			else:
				print("TEST Login échoué : ", data.get("message"))

func _on_joueurs_mis_a_jour(joueurs :Array):
	_rafraichir_liste(joueurs)
	
func _rafraichir_liste(joueurs: Array):
	for enfant in $ListeJoueurs/PanelContainer/ListeJoueurs1.get_children():
		enfant.queue_free()
	
	for joueur in joueurs:
		var label = Label.new()
		label.text = "Joueur : "+ str(joueur)
		$ListeJoueurs/PanelContainer/ListeJoueurs1.add_child(label)
