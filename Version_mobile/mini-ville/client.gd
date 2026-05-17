extends Node

# On ne définit plus de variable TCP ici, c'est NetworkManager qui gère.

func _ready():
	print("--- DÉMARRAGE DU CLIENT (Refactorisé) ---")
	# On se connecte au signal du NetworkManager pour traiter les réponses
	NetworkManager.message_recu.connect(_on_serveur_message_recu)
	
	if NetworkManager.est_connecte():
		print("Prêt à envoyer des requêtes.")
	else:
		print("En attente de connexion...")

# Cette fonction sera appelée à chaque fois que le serveur envoie un JSON valide
func _on_serveur_message_recu(data: Dictionary):
	print("Réponse reçue du serveur : ", data)
	
	# Exemple de traitement selon l'action
	if data.has("status"):
		match data["status"]:
			"success":
				print("Action réussie !")
			"error":
				print("Erreur serveur : ", data.get("message", "Inconnue"))

## ----------------------------------------------------
## 1. REQUÊTE : ENREGISTREMENT D'UN JOUEUR 
## ----------------------------------------------------
func send_register_request(pseudo: String, mot_de_passe: String, adresse_email: String, avatar_url: String):
	var request_data = {
		"action": "register",
		"nickname": pseudo,
		"password": mot_de_passe,
		"email": adresse_email,
		"avatar_url" : avatar_url
	}
	
	# On utilise la méthode factorisée du NetworkManager
	NetworkManager.envoyer(request_data)
	print("Requête d'inscription envoyée pour : ", pseudo)

## ----------------------------------------------------
## 2. REQUÊTE : ENREGISTRER UNE ACTION DANS L'HISTORIQUE
## ----------------------------------------------------
func send_historic(game_id: int, turn_number: int, action_type: String, player_id: int = -1, guest_id: int = -1, card_id: int = -1, monument_id: int = -1, dice_result: int = 0, amount_exchanged: int = 0):
	var request_data = {
		"action": "historic",
		"game_id": game_id,
		"turn_number": turn_number,
		"action_type": action_type,
		"dice_result": dice_result,
		"amount_exchanged": amount_exchanged
	}
	
	if player_id > 0: request_data["player_id"] = player_id
	if guest_id > 0: request_data["guest_id"] = guest_id
	if card_id > 0: request_data["card_id"] = card_id
	if monument_id > 0: request_data["monument_id"] = monument_id
		
	NetworkManager.envoyer(request_data)
	print("-> Événement historique envoyé : ", action_type)

## ----------------------------------------------------
## 3. REQUÊTE : CREATION D'UNE PARTIE 
## ----------------------------------------------------
func create_game():
	var request_data = {
		"action": "create_game",
	}
	NetworkManager.envoyer(request_data)

## ----------------------------------------------------
## 4. REQUÊTE : AUTHENTIFICATION 
## ----------------------------------------------------	
func authentication(identifiant: String, mdp: String):
	var request_data = {
		"action" : "authentification",
		"email": identifiant, 
		"password": mdp
	}
	NetworkManager.envoyer(request_data)
## ----------------------------------------------------
## 5. REQUÊTE : MOT DE PASSE OUBLIé 
## ----------------------------------------------------	
func forgot_password(email: String):
	var request_data = {
		"action": "forgot_password",
		"email": email
	}
	
	NetworkManager.envoyer(request_data)
	print("Requête mot de passe oublié envoyée pour : ", email)

## ----------------------------------------------------
## 5.1 REQUÊTE : VERFICIATION RESET CODE
## ----------------------------------------------------	
func verify_reset_code(email: String, code: String, new_password: String):
	NetworkManager.envoyer({
		"action":       "verify_reset_code",
		"email":        email,
		"code":         code,
		"new_password": new_password
	})

## ----------------------------------------------------
## 6. REQUÊTE : GET STATS
## ----------------------------------------------------	
# Pour soi-même :
func get_my_stats():
	NetworkManager.envoyer({"action": "get_stats"})

# Pour un autre joueur :
func get_player_stats(player_id: int):
	NetworkManager.envoyer({
		"action":    "get_stats",
		"player_id": player_id
	})
	
## ----------------------------------------------------
## 7. REQUÊTE : Deconnexion 
## ----------------------------------------------------	

func logout(): 
	var request_data = {
		"action": "logout"
	}
	NetworkManager.envoyer(request_data)
