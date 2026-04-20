extends Node

### ====== À IMPORTER DANS TOUS LES SCRIPTS DU JEU POUR RESTER CONNECTER AVEC LE SERVEUR ======

# ------------------------------------
#	CONFIGURATION
# ------------------------------------
const HOST = "185.155.93.105"
const PORT = 22000

# ------------------------------------
#	SIGNAUX
# ------------------------------------
signal connecte
signal deconnecte
signal message_recu(data: Dictionary)

# ------------------------------------
#	VARIABLE INTERNES
# ------------------------------------
var tcp := StreamPeerTCP.new()
var _buffer := ""
var _connecte := false
var _session_token := ""
var _joueur_id := -1

var _est_guest := false
var _guest_id = -1

# ------------------------------------
#	INITIALISATION
# ------------------------------------
func _ready() -> void:
	print("[NetworkManager] Démarrage...")
	_connecter()
	
 # -> Établie la connexion TCP au serveur
func _connecter():
	var err = tcp.connect_to_host(HOST, PORT)
	if err != OK:
		print("[NetworkManager] Erreur connexion : ", err)
	else:
		print("[NetworkManager] Connexion en cours vers ", HOST, ":", PORT)

func set_guest(id : int):
	_guest_id = id
	_est_guest = true

# ------------------------------------
#	BOUCLE PRINCIPALE
# ------------------------------------
# -> Surveille l'état TCP et lit les messages entrants
func _process(delta):
	tcp.poll()
	var status = tcp.get_status()
	if not _connecte and status == StreamPeerTCP.STATUS_CONNECTED:
		_connecte = true
		print("[NetworkManager] Connecté au serveur")
		connecte.emit()
		
	if _connecte and status != StreamPeerTCP.STATUS_CONNECTED:
		_connecte = false
		print("[NetworkManager] Déconnecté du serveur")
		deconnecte.emit()
		
	if _connecte and tcp.get_available_bytes() > 0:
		var data_array = tcp.get_data(tcp.get_available_bytes())
		if data_array[0] == OK:
			_buffer += data_array[1].get_string_from_utf8()
			_traiter_buffer()
			
# ------------------------------------
#	GESTION DU BUFFER
# ------------------------------------
# -> Reconstritue les messages fragmentés grâce au \n
func _traiter_buffer():
	while "\n" in _buffer:
		var idx = _buffer.find("\n")
		var ligne = _buffer.substr(0, idx).strip_edges()
		_buffer = _buffer.substr(idx + 1)
		if ligne != "":
			_traiter_message(ligne)

# -> Parse le JSON et émet message_recu
func _traiter_message(raw: String):
	var json = JSON.new()
	if json.parse(raw) != OK:
		print("[NetworkManager] JSON invalide : ", raw)
		return
	var data = json.get_data()

# -> Stocker le token si login réussi
	if data.get("action_reply") == "authentification" and data.get("status") == "success":
		var token = data.get("access_token", "")
		if token != "":
			set_token(token)
			set_joueur_id(int(data.get("player_id", -1)))
			print("[NetworkManager] Token stocké, joueur : ", _joueur_id)
			
	if data.get("type") == "token_expire":
		_session_token = ""
		_joueur_id = -1
		print("[NetworkManager] Session expirée, déconnexion.")
	# Retourner à l'écran de login
		get_tree().change_scene_to_file("res://main_client.tscn") # à adapter

	message_recu.emit(data)
	
# ------------------------------------
#	ENVOI
# ------------------------------------
# -> Envoie un dictionnaire JSON au serveur
func envoyer(data:Dictionary):
	if not _connecte:
		print("[NetworkManger] Impossible d'envoyer : non connecté")
		return
	tcp.put_data((JSON.stringify(data) + "\n").to_utf8_buffer())
	
# ------------------------------------
#	UTILITAIRES
# ------------------------------------
func est_connecte() ->bool:
	return _connecte
	
# -> Retourne le token de session
func get_token() -> String:
	return _session_token
	
func get_joueur_id() -> int:
	return _joueur_id
# -> Sauvegarde le token après login

func set_token(token: String):
	_session_token = token

func set_joueur_id(id: int):
	_joueur_id = id
	
func est_guest():
	return 
	
func get_guest_id() -> int:
	return _guest_id
