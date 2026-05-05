extends Control

# ----------------------------------------------------------------
# CONFIGURATION
# ----------------------------------------------------------------
const DURATIONS_TEXT = ["1 min", "2 min", "3 min", "5 min"]
const MIN_JOUEURS = 2	
var max_joueurs_lobby: int = 4

# ----------------------------------------------------------------
# STATE
# ----------------------------------------------------------------
var remaining_seconds: int = 120
#var nb_prets: int = 0
var slots: Array = []

# ----------------------------------------------------------------
# NŒUDS
# ----------------------------------------------------------------
@onready var label_code    = $LabelCode
@onready var label_timer   = $LabelTimer
@onready var label_duree   = $DureeTourRow/LabelDuree
#@onready var btn_pret      = $BtnPret
@onready var label_attente = $VBoxContainer2/Attente
@onready var btn_commencer = $VBoxContainer2/BtnCommencer
@onready var timer_chrono  = $TimerChrono

# ----------------------------------------------------------------
# INITIALISATION
# ----------------------------------------------------------------
func _ready():
	slots = [
		$JoueursRow/Joueur1,
		$JoueursRow/Joueur2,
		$JoueursRow/Joueur3,
		$JoueursRow/Joueur4,
	]

	# --- Signaux réseau ---
	LobbyHandler.joueur_mis_a_jour.connect(_on_joueurs_mis_a_jour)
	#NetworkManager.message_recu.connect(_on_message)

	# --- Affichage initial ---
	label_code.text = LobbyHandler.get_lobby_id()

	var dur_index = get_tree().get_meta("tour_duration_index", 1)
	label_duree.text = DURATIONS_TEXT[dur_index]
	remaining_seconds = [60, 120, 180, 300][dur_index]
	
	var max_joueurs = get_tree().get_meta("nb_joueurs", 4)
	_update_label_attente(LobbyHandler.get_joueurs().size(), max_joueurs)

	_rafraichir_slots(LobbyHandler.get_joueurs())

	# --- Boutons Lancer visible seulement pour le host ---
	#btn_pret.pressed.connect(_on_pret_pressed)
	btn_commencer.pressed.connect(_on_commencer_pressed)
	btn_commencer.visible = false

	# --- Timer ---
	timer_chrono.wait_time = 1.0
	timer_chrono.timeout.connect(_on_tick)
	timer_chrono.start()

# ----------------------------------------------------------------
# RÉSEAU → ENVOI
# ----------------------------------------------------------------
func _on_pret_pressed():
	NetworkManager.envoyer({
		"action": "joueur_pret",
		"token": NetworkManager.get_token(),
		"lobby_id": LobbyHandler.get_lobby_id()
	})

	# Host → cache Prêt, montre Lancer (désactivé jusqu'à ce que tous soient prêts)
	if LobbyHandler.is_host():
		btn_commencer.visible = true
		var total = LobbyHandler.get_joueurs().size()
		var assez = total >= MIN_JOUEURS
		btn_commencer.disabled = true  # toujours désactivé ici, attend que tous soient prêts
		btn_commencer.text = "En attente... (1/%d)" % total if assez else "Minimum %d joueurs requis" % MIN_JOUEURS


# ----------------------------------------------------------------
# MISE À JOUR JOUEURS
# ----------------------------------------------------------------
func _on_joueurs_mis_a_jour(joueurs: Array):
	_rafraichir_slots(joueurs)

func _rafraichir_slots(joueurs: Array):
	for i in 4:
		var slot = slots[i]
		var occupe = i < joueurs.size()
		slot.visible = occupe
		if occupe:
			var label = slot.get_node_or_null("LabelNom")
			if label:
				label.text = str(joueurs[i])
			var badge = slot.get_node_or_null("ReadyBadge")  # ← faute corrigée
			if badge:
				_afficher_badge(badge)
	
	max_joueurs_lobby = get_tree().get_meta("nb_joueurs", 4)
	_update_label_attente(joueurs.size(), max_joueurs_lobby)
	if LobbyHandler.is_host():
		_update_btn_commencer(joueurs.size())
	
func _update_label_attente(nb_actuels: int, max_joueurs: int):
	if not LobbyHandler.is_host():
		# Joueur non-host : toujours "En attente du host..."
		label_attente.visible = true
		label_attente.text = "En attente du host..."
	elif nb_actuels >= max_joueurs:
		# Host + lobby plein : cache le label
		label_attente.visible = false
	else:
		# Host + lobby pas encore plein : affiche le compteur
		label_attente.visible = true
		label_attente.text = "En attente joueur %d/%d" % [nb_actuels, max_joueurs]
	

func _update_btn_commencer(nb_joueurs: int):
	if nb_joueurs >= max_joueurs_lobby:
		btn_commencer.visible = true
		btn_commencer.text = "Lancer la partie"
	else:
		btn_commencer.visible = false


# ----------------------------------------------------------------
# LANCER LA PARTIE
# ----------------------------------------------------------------
func _on_commencer_pressed():
	LobbyHandler.lancer_partie()
	btn_commencer.disabled = true  # anti double-clic

# ----------------------------------------------------------------
# TIMER
# ----------------------------------------------------------------
func _on_tick():
	remaining_seconds = max(0, remaining_seconds - 1)
	_update_display()
	if remaining_seconds == 0:
		timer_chrono.stop()
		if LobbyHandler.is_host():
			LobbyHandler.lancer_partie()

func _update_display():
	var m = remaining_seconds / 60
	var s = remaining_seconds % 60
	label_timer.text = "%02d:%02d" % [m, s]
	if remaining_seconds <= 10:
		label_timer.modulate = Color(1, 0.15, 0.15, 1)
		var t = label_timer.create_tween()
		t.tween_property(label_timer, "modulate:a", 0.3, 0.25)
		t.tween_property(label_timer, "modulate:a", 1.0, 0.25)
	elif remaining_seconds <= 30:
		label_timer.modulate = Color(1, 0.55, 0.1, 1)
	else:
		label_timer.modulate = Color(1, 1, 1, 1)
		
func _afficher_badge(badge: Node):
	if badge.visible:
		return  # déjà affiché, pas d'animation double
	badge.visible = true
	badge.modulate.a = 0.0
	var t = badge.create_tween()
	t.tween_property(badge, "modulate:a", 1.0, 0.3)
	t.parallel().tween_property(badge, "scale", Vector2(1.2, 1.2), 0.15)
	t.tween_property(badge, "scale", Vector2(1.0, 1.0), 0.15)
