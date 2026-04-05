extends Node

var tcp := StreamPeerTCP.new()
var host = "185.155.93.105" # IP du bastion
var port = 22000            # Port redirigé vers le port 10000 de ta VM-0

func _ready():
	print("--- DÉMARRAGE DU CLIENT ---")
	print("ATTENTION : Clique bien dans la fenêtre du jeu avant d'appuyer sur Entrée/Espace !")
	print("Tentative de connexion au serveur via le bastion...")
	
	# On initie la connexion au serveur via le bastion
	var err = tcp.connect_to_host(host, port)
	if err != OK:
		print("Erreur lors de la tentative de connexion : ", err)

func _process(_delta):
	# Il faut "poll" manuellement le flux TCP à chaque frame pour actualiser son état
	tcp.poll()
	
	var status = tcp.get_status()
	
	# Si des données sont reçues depuis le serveur
	if status == StreamPeerTCP.STATUS_CONNECTED and tcp.get_available_bytes() > 0:
		var bytes_to_read = tcp.get_available_bytes()
		
		# On utilise get_data pour éviter les erreurs de décodage
		var data_array = tcp.get_data(bytes_to_read)
		if data_array[0] == OK:
			var response = data_array[1].get_string_from_utf8()
			print("Réponse reçue du serveur : ", response)

## ----------------------------------------------------
## 1. REQUÊTE : ENREGISTREMENT D'UN JOUEUR 
## ----------------------------------------------------
func send_register_request(pseudo: String, mot_de_passe: String, adresse_email: String, avatar_url: String):
	if tcp.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		# On crée le dictionnaire qui correspond aux colonnes de ta table
		var request_data = {
			"action": "register",
			"nickname": pseudo,
			"password": mot_de_passe,
			"email": adresse_email,
			"avatar_url" : avatar_url
		}
		
		# On n'oublie pas le délimiteur "\n"
		var json_string = JSON.stringify(request_data) + "\n"
		tcp.put_data(json_string.to_utf8_buffer())
		print("Requête d'inscription envoyée pour : ", pseudo)
	else:
		print("Impossible d'envoyer : non connecté au serveur.")


## ----------------------------------------------------
## 2. REQUÊTE : ENREGISTRER UNE ACTION DANS L'HISTORIQUE
## ----------------------------------------------------
func send_historic(game_id: int, turn_number: int, action_type: String, player_id: int = -1, guest_id: int = -1, card_id: int = -1, monument_id: int = -1, dice_result: int = 0, amount_exchanged: int = 0):
	if tcp.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		
		# Champs obligatoires (NOT NULL)
		var request_data = {
			"action": "log_history",
			"game_id": game_id,
			"turn_number": turn_number,
			"action_type": action_type,
			"dice_result": dice_result,
			"amount_exchanged": amount_exchanged
		}
		
		# Champs optionnels (on ne les ajoute que s'ils sont valides)
		if player_id > 0:
			request_data["player_id"] = player_id
		if guest_id > 0:
			request_data["guest_id"] = guest_id
		if card_id > 0:
			request_data["card_id"] = card_id
		if monument_id > 0:
			request_data["monument_id"] = monument_id
			
		var json_string = JSON.stringify(request_data) + "\n"
		tcp.put_data(json_string.to_utf8_buffer())
		print("-> Événement historique envoyé : ", action_type)
	else:
		print("Impossible d'envoyer l'historique : non connecté.")


func _input(event):
	# Appuie sur Espace / Entrée (l'action ui_accept par défaut) pour tester l'envoi
	if event.is_action_pressed("ui_accept"):
		# On envoie un faux joueur test
		send_register_request("JoueurTest2", "monSuperMdp", "joueur2@test.com", "http://image.com/avatar.png")
