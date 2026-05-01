extends Node

### ====== GESTIONNAIRE RÉSEAU CENTRALISÉ ======

# ------------------------------------
#	CONFIGURATION
# ------------------------------------
const HOST = "185.155.93.105"
const PORT = 22000

# ------------------------------------
#	SIGNAUX (Déclarés ici pour être reconnus globalement)
# ------------------------------------
signal connecte
signal deconnecte
signal message_recu(data: Dictionary)

# Signaux pour l'interface (UI)
signal auth_finished(success: bool, message: String)
signal register_finished(success: bool, message: String)

# ------------------------------------
#	VARIABLES INTERNES
# ------------------------------------
var _tcp := StreamPeerTCP.new()
var _tls := StreamPeerTLS.new()

var _buffer := ""
var _connecte := false
var _session_token := ""
var _joueur_id := -1
var _est_guest := false

# ------------------------------------
#	INITIALISATION & CONNEXION
# ------------------------------------
func _ready() -> void:
	print("[NetworkManager] En attente du signal de démarrage...")

func lancer_connexion_reseau():
	if _connecte: return
	_connecter()
	
func _connecter():
	var err = _tcp.connect_to_host(HOST, PORT)
	if err != OK:
		print("[NetworkManager] Erreur TCP : ", err)
	else:
		print("[NetworkManager] Connexion TCP vers ", HOST)

# ------------------------------------
#	BOUCLE RÉSEAU
# ------------------------------------
func _process(_delta):
	_tcp.poll()
	_tls.poll() 
	
	var tcp_status = _tcp.get_status()
	var tls_status = _tls.get_status()

	# 1. Handshake TLS
	if tcp_status == StreamPeerTCP.STATUS_CONNECTED and tls_status == StreamPeerTLS.STATUS_DISCONNECTED:
		var options = TLSOptions.client_unsafe()
		_tls.connect_to_stream(_tcp, HOST, options)

	# 2. Status de connexion
	if not _connecte and tls_status == StreamPeerTLS.STATUS_CONNECTED:
		_connecte = true
		connecte.emit()
		
	if _connecte and tls_status != StreamPeerTLS.STATUS_CONNECTED:
		_connecte = false
		deconnecte.emit()
		
	# 3. Lecture des données
	if _connecte and _tls.get_available_bytes() > 0:
		var data_array = _tls.get_data(_tls.get_available_bytes())
		if data_array[0] == OK:
			_buffer += data_array[1].get_string_from_utf8()
			_traiter_buffer()

func _traiter_buffer():
	while "\n" in _buffer:
		var idx = _buffer.find("\n")
		var ligne = _buffer.substr(0, idx).strip_edges()
		_buffer = _buffer.substr(idx + 1)
		if ligne != "":
			_traiter_message(ligne)

# ------------------------------------
#	LOGIQUE DE TRAITEMENT CENTRALISÉE
# ------------------------------------
func _traiter_message(raw: String):
	var json = JSON.new()
	if json.parse(raw) != OK: return
	var data = json.get_data()
	
	var action = data.get("action_reply", "")
	var status = data.get("status", "error")
	var message = data.get("message", "")

	# 1. Traitement Authentification
	if action == "authentification":
		if status == "success":
			_session_token = data.get("access_token", "")
			_joueur_id = int(data.get("player_id", -1))
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

	# Envoi du message brut pour les autres scripts
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
	_tls.put_data((JSON.stringify(data) + "\n").to_utf8_buffer())

func est_connecte() -> bool: return _connecte
func get_token() -> String: return _session_token
func get_joueur_id() -> int: return _joueur_id
func connecter_guest(): _est_guest = true
func est_guest()->bool: return _est_guest

func set_token(token: String):
	_session_token = token
	_est_guest = false  # si on a un token, c'est pas un guest
