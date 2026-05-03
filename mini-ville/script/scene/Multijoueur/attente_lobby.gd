extends Control

# ----------------------------------------------------------------
# CONFIGURATION
# ----------------------------------------------------------------
const DURATIONS_TEXT = ["1 min", "2 min", "3 min", "5 min"]
const MIN_JOUEURS = 2

# ----------------------------------------------------------------
# STATE
# ----------------------------------------------------------------
var remaining_seconds: int = 120
var nb_prets: int = 0
var slots: Array = []

# ----------------------------------------------------------------
# NŒUDS
# ----------------------------------------------------------------
@onready var label_code    = $LabelCode
@onready var label_timer   = $LabelTimer
@onready var label_duree   = $DureeTourRow/LabelDuree
@onready var btn_pret      = $BtnPret
@onready var btn_commencer = $BtnCommencer
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
	NetworkManager.message_recu.connect(_on_message)

	# --- Affichage initial ---
	label_code.text = LobbyHandler.get_lobby_id()

	var dur_index = get_tree().get_meta("tour_duration_index", 1)
	label_duree.text = DURATIONS_TEXT[dur_index]
	remaining_seconds = [60, 120, 180, 300][dur_index]

	_rafraichir_slots(LobbyHandler.get_joueurs())

	# --- Boutons ---
	btn_pret.pressed.connect(_on_pret_pressed)
	btn_commencer.pressed.connect(_on_commencer_pressed)
	btn_commencer.visible = false

	if not LobbyHandler.is_host():
		#btn_pret.text = "En attente du host ..."
		btn_pret.disabled = true
	# --- Timer ---
	timer_chrono.wait_time = 1.0
	timer_chrono.timeout.connect(_on_tick)
	timer_chrono.start()

# ----------------------------------------------------------------
# RÉSEAU → RÉCEPTION
# ----------------------------------------------------------------
func _on_message(data: Dictionary):
	match data.get("type", ""):
		"joueur_pret":
			_on_joueur_pret_recu(data)
		"tous_prets":
			_on_tous_prets_recu()
		"game_demarre":
			pass  # LobbyHandler gère la navigation

func _on_joueur_pret_recu(data: Dictionary):
	var d = data.get("data", {})
	var prets: Array = d.get("joueurs_prets", [])
	var joueurs = LobbyHandler.get_joueurs()
	nb_prets = prets.size()

	# Met à jour les badges visuels
	for i in min(slots.size(), joueurs.size()):
		var badge = slots[i].get_node_or_null("ReadyBadge")  # ← faute corrigée
		if badge:
			if prets.has(joueurs[i]):
				_afficher_badge(badge)
			else:
				badge.visible = false

	# Met à jour le compteur sur le bouton Lancer (host uniquement)
	if LobbyHandler.is_host() and btn_commencer.visible:
		var total = joueurs.size()
		var assez_de_joueurs = total >= MIN_JOUEURS
		var tous_prets = nb_prets >= total
		
		if assez_de_joueurs and tous_prets:
			btn_commencer.disabled = false
			btn_commencer.text = "Lancer la partie !"
		elif not assez_de_joueurs:
			btn_commencer.disabled = true
			btn_commencer.text = "Minimum %d joueurs requis" % MIN_JOUEURS
		else:
			btn_commencer.disabled = true
			btn_commencer.text = "En attente... (%d/%d)" % [nb_prets, total]


func _afficher_badge(badge: Node):
	badge.visible = true
	badge.modulate.a = 0.0
	var t = badge.create_tween()
	t.tween_property(badge, "modulate:a", 1.0, 0.3)
	t.parallel().tween_property(badge, "scale", Vector2(1.2, 1.2), 0.15)
	t.tween_property(badge, "scale", Vector2(1.0, 1.0), 0.15)

func _on_tous_prets_recu():
	if LobbyHandler.is_host():
		btn_pret.visible = false
		btn_commencer.visible = true
		# Active seulement si assez de joueurs
		var assez = LobbyHandler.get_joueurs().size() >= MIN_JOUEURS
		btn_commencer.disabled = not assez
		btn_commencer.text = "Lancer la partie !" if assez else "Minimum %d joueurs requis" % MIN_JOUEURS

# ----------------------------------------------------------------
# RÉSEAU → ENVOI
# ----------------------------------------------------------------
func _on_pret_pressed():
	NetworkManager.envoyer({
		"action": "joueur_pret",
		"token": NetworkManager.get_token(),
		"lobby_id": LobbyHandler.get_lobby_id()
	})
	btn_pret.disabled = true
	btn_pret.text = "Prêt ✓"

	# Host → cache Prêt, montre Lancer (désactivé jusqu'à ce que tous soient prêts)
	if LobbyHandler.is_host():
		btn_pret.visible = false
		btn_commencer.visible = true
		var total = LobbyHandler.get_joueurs().size()
		var assez = total >= MIN_JOUEURS
		btn_commencer.disabled = true  # toujours désactivé ici, attend que tous soient prêts
		btn_commencer.text = "En attente... (1/%d)" % total if assez else "Minimum %d joueurs requis" % MIN_JOUEURS

func _on_commencer_pressed():
	LobbyHandler.lancer_partie()
	btn_commencer.disabled = true  # anti double-clic

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
				badge.visible = false  # reset, mis à jour par _on_joueur_pret_recu

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
