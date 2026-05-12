extends Node

### ====== GESTIONNAIRE RÉSEAU CENTRALISÉ (WEBSOCKETS) ======

# ------------------------------------
#	CONFIGURATION
# ------------------------------------
# On utilise l'URL du Reverse Proxy de la fac au lieu de l'IP du Bastion
const URL = "wss://mai-projet-integrateur.u-strasbg.fr/vmProjetIntegrateurgrp12-0/"

# ------------------------------------
#	SIGNAUX
# ------------------------------------
signal connecte
signal deconnecte
signal message_recu(data: Dictionary)
signal stats_received(data: Dictionary)
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
const DELAI_PING := 20.0 # Envoi un ping toutes les 20 secondes

# ------------------------------------
#	INITIALISATION & CONNEXION
# ------------------------------------
func _ready() -> void:
	_ws = WebSocketPeer.new()
	print("[NetworkManager] En attente du signal de démarrage...")

func lancer_connexion_reseau():
	if _connecte: return
	_connecter()
	
func _connecter():
	print("[NetworkManager] Tentative de connexion WebSocket vers ", URL)
	var err = _ws.connect_to_url(URL)
	if err != OK:
		print("[NetworkManager] Erreur d'initialisation WebSocket : ", err)

# ------------------------------------
#	BOUCLE RÉSEAU
# ------------------------------------
func _process(delta):
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

	# 2. Gestion du Heartbeat (Ping)
	if _connecte:
		_temps_ecoule += delta
		if _temps_ecoule >= DELAI_PING:
			envoyer({"action": "ping"})
			_temps_ecoule = 0.0

	# 3. Lecture des données
	if state == WebSocketPeer.STATE_OPEN:
		while _ws.get_available_packet_count() > 0:
			var raw = _ws.get_packet().get_string_from_utf8()
			_traiter_message(raw)

# ------------------------------------
#	LOGIQUE DE TRAITEMENT
# ------------------------------------
func _traiter_message(raw: String):
	var json = JSON.new()
	if json.parse(raw) != OK: return
	var data = json.get_data()
	
	var action = data.get("action_reply", "")
	var status = data.get("status", "error")
	var message = data.get("message", "")

	# Gestion silencieuse du Pong
	if action == "pong":
		return

	# Traitement Authentification
	if action == "authentification":
		if status == "success":
			_session_token = data.get("access_token", "")
			_joueur_id = data.get("player_id","")
			auth_finished.emit(true, "Connexion réussie")
		else:
			auth_finished.emit(false, message if message != "" else "Identifiants incorrects")

	# Traitement Inscription
	elif action == "register":
		if status == "success":
			register_finished.emit(true, "Compte créé avec succès")
		else:
			var clean_error = _parse_sql_error(message)
			register_finished.emit(false, clean_error)
			
	# Traitement Statistiques
	elif action == "get_stats":
		if status == "success":
			stats_received.emit(data)

	message_recu.emit(data)

func _parse_sql_error(error_msg: String) -> String:
	var err = error_msg.to_lower()
	if "nickname" in err: return "Ce pseudo est déjà utilisé."
	if "email" in err: return "Cette adresse email est déjà enregistrée."
	return error_msg

func envoyer(data: Dictionary):
	if not _connecte: return
	_ws.put_packet(JSON.stringify(data).to_utf8_buffer())

func est_connecte() -> bool: return _connecte
func get_token() -> String: return _session_token
