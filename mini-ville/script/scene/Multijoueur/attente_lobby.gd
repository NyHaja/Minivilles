extends Control


# -------------- Popup -----------------------------
var pop_setting_scene = preload("res://scene/popup/popup_parametres.tscn")
var popup_setting

var pop_stat_scene = preload("res://scene/popup/popup_stat.tscn")
var popup_stat

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
@onready var btn_commencer = $VBoxContainer2/HBoxContainer/BtnCommencer
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
	
	var max_joueurs = get_tree().get_meta("nb_joueurs", 4)
	_update_label_attente(LobbyHandler.get_joueurs().size(), max_joueurs)

	_rafraichir_slots(LobbyHandler.get_joueurs())

	# --- Boutons Lancer visible seulement pour le host ---
	#btn_pret.pressed.connect(_on_pret_pressed)
	btn_commencer.pressed.connect(_on_commencer_pressed)
	btn_commencer.visible = false

	# --- Timer ---
	#NetworkManager.message_recu.connect(_on_message)
	
	# --- Paramètre ----
	popup_setting = pop_setting_scene.instantiate()
	add_child(popup_setting)
	popup_setting.hide()
	
	# --- Statistique du joueur ---
	popup_stat = pop_stat_scene.instantiate()
	add_child(popup_stat)
	popup_stat.hide()

	$VBoxContainer2/HBoxContainer/BtnQuitter.pressed.connect(_on_quitter_pressed)
	$VBoxContainer/BtnParametres.pressed.connect(affiche_parametre)
	
	# Rend le label cliquable
	label_code.mouse_filter = Control.MOUSE_FILTER_STOP
	label_code.gui_input.connect(_on_label_code_clique)

func affiche_parametre():
	SoundManager.play_click()
	#$Content/gameMode.hide()
	popup_setting.show()
	
func affiche_stats(data: Dictionary):
	SoundManager.play_click()
	popup_stat.show()
	popup_stat.update_stats(data)
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
		btn_commencer.text = tr("En attente... (1/%d)") % total if assez else tr("Minimum %d joueurs requis") % MIN_JOUEURS


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
			var joueur = joueurs[i]
			var label = slot.get_node_or_null("LabelNom")
			if label:
				if typeof(joueur) == TYPE_DICTIONARY:
					label.text = joueur.get("nickname", "Joueur")
				else:
					label.text = str(joueur)
			var badge = slot.get_node_or_null("ReadyBadge")
			if badge:
				_afficher_badge(badge)

			# Force les enfants à ignorer les clics
			for enfant in slot.get_children():
				if enfant is Control:
					enfant.mouse_filter = Control.MOUSE_FILTER_IGNORE

			slot.mouse_filter = Control.MOUSE_FILTER_STOP

			# ← retire CONNECT_ONE_SHOT et déconnecte avant de reconnecter
			if slot.gui_input.is_connected(_on_slot_clique):
				slot.gui_input.disconnect(_on_slot_clique)
			slot.gui_input.connect(_on_slot_clique.bind(joueur))
		else:
			slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	max_joueurs_lobby = get_tree().get_meta("nb_joueurs", 4)
	_update_label_attente(joueurs.size(), max_joueurs_lobby)
	if LobbyHandler.is_host():
		_update_btn_commencer(joueurs.size())
	
func _update_label_attente(nb_actuels: int, max_joueurs: int):
	if not LobbyHandler.is_host():
		# Joueur non-host : toujours "En attente du host..."
		label_attente.visible = true
		label_attente.text = tr("En attente du host...")
	elif nb_actuels >= max_joueurs:
		# Host + lobby plein : cache le label
		label_attente.visible = false
	else:
		# Host + lobby pas encore plein : affiche le compteur
		label_attente.visible = true
		label_attente.text = tr("En attente joueur %d/%d") % [nb_actuels, max_joueurs]
	

func _update_btn_commencer(nb_joueurs: int):
	if nb_joueurs >= max_joueurs_lobby:
		btn_commencer.visible = true
		btn_commencer.disabled = false
		btn_commencer.text = tr("Lancer la partie")
	elif nb_joueurs >= MIN_JOUEURS:
		# Assez de joueurs mais pas le max → peut lancer
		btn_commencer.visible = true
		btn_commencer.disabled = false
		btn_commencer.text = tr("Lancer la partie")
	else:
		# Pas assez de joueurs → cache le bouton
		btn_commencer.visible = false


func _on_slot_clique(event: InputEvent, joueur):
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return

	# Ignore les guests — pas de stats
	if typeof(joueur) == TYPE_DICTIONARY:
		if joueur.get("type") == "guest":
			_afficher_message_guest()
			return
		_demander_stats(joueur.get("id"))
	else:
		_demander_stats(joueur)


func _afficher_message_guest():
	var label = Label.new()
	label.text = "Joueur invité\npas de statistiques"
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	add_child(label)
	label.global_position = get_global_mouse_position() + Vector2(10, 10)
	await get_tree().create_timer(1.5).timeout
	label.queue_free()


func _demander_stats(player_id):
	NetworkManager.envoyer({
		"action":    "get_stats",
		"token":     NetworkManager.get_token(),
		"player_id": player_id
	})

# ----------------------------------------------------------------
# LANCER LA PARTIE
# ----------------------------------------------------------------
var _partie_lancee := false

func _on_commencer_pressed():
	if _partie_lancee: return
	_partie_lancee = true
	timer_chrono.stop()
	btn_commencer.disabled = true  # anti double-clic
	LobbyHandler.lancer_partie()
# ----------------------------------------------------------------
# TIMER
# ----------------------------------------------------------------
func _on_tick():
	remaining_seconds = max(0, remaining_seconds - 1)
	_update_display()
	if remaining_seconds == 0:
		timer_chrono.stop()
		if LobbyHandler.is_host() and not _partie_lancee:
			var nb = LobbyHandler.get_joueurs().size()
			if nb < MIN_JOUEURS:
			# Host seul -> quitte le lobby automatiquement
				LobbyHandler.quitter_lobby()
				get_tree().change_scene_to_file("res://scene/Multijoueur/choix_game.tscn")
			else :
				_on_commencer_pressed()

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


func _on_message(data: Dictionary):
	match data.get("type", ""):
		"timer_sync":
			remaining_seconds = data.get("remaining", 0)
			_update_display()
		"lobby_dissous":
			_on_lobby_dissous()
		"game_demarre":
			timer_chrono.stop()
			_partie_lancee = true

	# Stats reçues
	if data.get("action_reply") == "get_stats" and data.get("status") == "success":
		affiche_stats(data)

func _on_quitter_pressed():
	SoundManager.play_click()
	LobbyHandler.quitter_lobby()
	get_tree().change_scene_to_file("res://scene/Multijoueur/choix_game.tscn")
	
func _on_lobby_dissous():
	LobbyHandler.reset()  # remet lobby_id et joueurs à vide
	get_tree().change_scene_to_file("res://scene/Multijoueur/choix_game.tscn")
	
func _on_label_code_clique(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var code = LobbyHandler.get_lobby_id()
		DisplayServer.clipboard_set(code)
		_afficher_feedback_copie()

func _afficher_feedback_copie():
	var original_text = label_code.text
	label_code.text = "Copié ✓"
	label_code.modulate = Color(0.2, 1.0, 0.2, 1)  # vert
	await get_tree().create_timer(1.5).timeout
	label_code.text = original_text
	label_code.modulate = Color(1, 1, 1, 1)  # remet blanc
