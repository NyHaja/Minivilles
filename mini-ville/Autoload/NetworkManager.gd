extends Node

### ====== GESTIONNAIRE RÉSEAU CENTRALISÉ (WEBSOCKETS) ======

# ------------------------------------
#	CONFIGURATION
# ------------------------------------
# On utilise l'URL du Reverse Proxy de la fac au lieu de l'IP du Bastion
const URL = "wss://mai-projet-integrateur.u-strasbg.fr/vmProjetIntegrateurgrp12-0/"

# ------------------------------------
#	SIGNAUX (Déclarés ici pour être reconnus globalement)
# ------------------------------------
signal connecte
signal deconnecte
signal message_recu(data: Dictionary)
signal stats_received(data: Dictionary)

# Signaux pour l'interface (UI)
signal auth_finished(success: bool, message: String)
signal register_finished(success: bool, message: String)

# ------------------------------------
#	VARIABLES INTERNES
# ------------------------------------
var _ws : WebSocketPeer
var _connecte := false
var _session_token := ""
var _joueur_id := -1
var _est_guest := false

# Variables pour le Heartbeat (Maintien de connexion)
var _temps_ecoule := 0.0
const DELAI_PING := 20.0

# ------------------------------------
#	INITIALISATION & CONNEXION
# ------------------------------------
func _ready() -> void:
	# On force la création de l'objet WebSocket une fois que le script est chargé
	_ws = WebSocketPeer.new()
	print("[NetworkManager] En attente du signal de démarrage...")

func lancer_connexion_reseau():
	if _connecte: return
	_connecter()
	
func _connecter():
	print("[NetworkManager] Tentative de connexion WebSocket vers ", URL)
	var tls_options = TLSOptions.client_unsafe()
	var err = _ws.connect_to_url(URL)
	if err != OK:
		print("[NetworkManager] Erreur d'initialisation WebSocket : ", err)

# ------------------------------------
#	BOUCLE RÉSEAU
# ------------------------------------
func _process(delta): # <- Remplacement de _delta par delta pour l'utiliser
	# SÉCURITÉ : On s'assure que _ws existe bien avant de faire quoi que ce soit
	if _ws == null: return
		
	_ws.poll()
	var state = _ws.get_ready_state()

	# 1. Gestion des statuts de connexion
	if state == WebSocketPeer.STATE_OPEN and not _connecte:
		_connecte = true
		connecte.emit()
		print("[NetworkManager] Connecté au serveur en WebSocket (wss) !")
		
	elif state == WebSocketPeer.STATE_CLOSED and _connecte:
		_connecte = false
		deconnecte.emit()
		print("[NetworkManager] Déconnecté du serveur.")

	# --- AJOUT : Gestion du Heartbeat (Ping) ---
	if _connecte:
		_temps_ecoule += delta
		if _temps_ecoule >= DELAI_PING:
			envoyer({"action": "ping"})
			_temps_ecoule = 0.0
	# -------------------------------------------

	# 2. Lecture des données
	if state == WebSocketPeer.STATE_OPEN:
		# Les WebSockets lisent des paquets entiers, plus besoin de couper avec "\n"
		while _ws.get_available_packet_count() > 0:
			var raw = _ws.get_packet().get_string_from_utf8()
			_traiter_message(raw)

# ------------------------------------
#	LOGIQUE DE TRAITEMENT CENTRALISÉE
# ------------------------------------
func _traiter_message(raw: String):
	var json = JSON.new()
	if json.parse(raw) != OK: return
	var data = json.get_data()

	var action = data.get("action_reply", "")
	print(">>> [NetworkManager] _traiter_message: action=", action)
	var status = data.get("status", "error")
	var message = data.get("message", "")

	# --- AJOUT : Ignorer silencieusement le Pong ---
	if action == "pong":
		return
	# -----------------------------------------------

	# --- DEBUG : Afficher les erreurs serveur côté client ---
	if action == "debug_error":
		print("!!! [SERVER DEBUG] ", data.get("message", ""))
		return
	# --------------------------------------------------------

	# 1. Traitement Authentification
	if action == "authentification":
		if status == "success":
			_session_token = data.get("access_token", "")
			_joueur_id = data.get("player_id","")
			_est_guest = false
			# On émet le signal déclaré en haut
			auth_finished.emit(true, "Connexion réussie")
		else:
			auth_finished.emit(false, message if message != "" else "Identifiants incorrects")

	# 2. Traitement Inscription
	elif action == "register":
		if status == "success":
			# On émet le signal déclaré en haut
			register_finished.emit(true, "Compte créé avec succès")
		else:
			var clean_error = _parse_sql_error(message)
			register_finished.emit(false, clean_error)
			
	# 3. Traitement Statistiques
	elif action == "get_stats":
		if status == "success":
			stats_received.emit(data)
		else:
			print("[NetworkManager] Erreur lors de la récupération des stats : ", message)

	# Envoi du message brut pour les autres scripts (LobbyHandler, Client, etc.)
	message_recu.emit(data)

func _parse_sql_error(error_msg: String) -> String:
	var err = error_msg.to_lower()
	if "nickname" in err: return "Ce pseudo est déjà utilisé."
	if "email" in err: return "Cette adresse email est déjà enregistrée."
	return error_msg

# ------------------------------------
#	ENVOI & UTILITAIRES
# ------------------------------------
func envoyer(data: Dictionary):
	if not _connecte: return
	# On envoie le JSON sous forme de paquet natif, plus besoin d'ajouter le "\n"
	_ws.put_packet(JSON.stringify(data).to_utf8_buffer())

func est_connecte() -> bool: return _connecte
func get_token() -> String: return _session_token
func get_joueur_id() -> int: return _joueur_id
func connecter_guest(): _est_guest = true
func est_guest()->bool: return _est_guest

func set_token(token: String):
	_session_token = token
	_est_guest = false  # si on a un token, c'est pas un guest
	
func set_guest(id: int):
	_joueur_id = id
	_est_guest = true
