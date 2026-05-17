extends Control

# ----------------------------------------------------------------
# VARIABLES
# ----------------------------------------------------------------
var code := ""
var boxes  := []
var panels := []

var style_filled := StyleBoxFlat.new()
var style_empty  := StyleBoxFlat.new()
var style_error  := StyleBoxFlat.new()

var pop_setting_scene = preload("res://scene/popup/popup_parametres.tscn")
var popup_setting

@onready var btn_rejoindre = $Panel/BtnRejoindre
@onready var label_erreur = $Panel/LabelErreur

# ----------------------------------------------------------------
# INITIALISATION
# ----------------------------------------------------------------
func _ready():
	_init_styles()

	# Adapte les chemins exacts à ta scène
	boxes = [
		$Panel/CodeRow/Box1/LabelBox1,
		$Panel/CodeRow/Box2/LabelBox2,
		$Panel/CodeRow/Box3/LabelBox3,
		$Panel/CodeRow/Box4/LabelBox4,
		$Panel/CodeRow/Box5/LabelBox5,
		$Panel/CodeRow/Box6/LabelBox6,
	]
	panels = [
		$Panel/CodeRow/Box1,
		$Panel/CodeRow/Box2,
		$Panel/CodeRow/Box3,
		$Panel/CodeRow/Box4,
		$Panel/CodeRow/Box5,
		$Panel/CodeRow/Box6,
	]

	# --- Signaux réseau ---
	LobbyHandler.joueur_mis_a_jour.connect(_on_lobby_rejoint)
	NetworkManager.message_recu.connect(_on_message)

	# --- Boutons ---
	btn_rejoindre.pressed.connect(_on_rejoindre_pressed)
	$Panel/BtnAnnuler.pressed.connect(func():
		get_tree().change_scene_to_file("res://scene/Multijoueur/choix_game.tscn"))
	$BtnRetour/Fleche.pressed.connect(func():
		get_tree().change_scene_to_file("res://scene/Multijoueur/choix_game.tscn"))

	label_erreur.visible = false
	
	_update_boxes()
	
	popup_setting = pop_setting_scene.instantiate()
	add_child(popup_setting)
	popup_setting.hide()

	$VBoxContainer/BtnParametres.pressed.connect(affiche_parametre)
	
func affiche_parametre():
	SoundManager.play_click()
	#$Content/gameMode.hide()
	popup_setting.show()


# ----------------------------------------------------------------
# SAISIE CLAVIER
# ----------------------------------------------------------------
func _unhandled_key_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.unicode >= 32 and code.length() < 6:
			code += char(event.unicode).to_upper()
			_update_boxes()
		elif event.keycode == KEY_BACKSPACE and code.length() > 0:
			code = code.left(code.length() - 1)
			_update_boxes()


func _update_boxes():
	for i in 6:
		if i < code.length():
			boxes[i].text = code[i]
			panels[i].add_theme_stylebox_override("panel", style_filled)
		else:
			boxes[i].text = ""
			panels[i].add_theme_stylebox_override("panel", style_empty)


# ----------------------------------------------------------------
# RÉSEAU → ENVOI
# ----------------------------------------------------------------
func _on_rejoindre_pressed():
	if code.length() < 6:
		_feedback_erreur("Veuillez entrer le code complet")
		return
	btn_rejoindre.disabled = true
	label_erreur.visible =  false
	LobbyHandler.rejoindre_lobby(code)


# ----------------------------------------------------------------
# RÉSEAU → RÉCEPTION
# ----------------------------------------------------------------
func _on_message(data: Dictionary):
	
	btn_rejoindre.disabled = false
	match data.get("type", ""):
		"lobby_erreur":
			btn_rejoindre.disabled = false
			_feedback_erreur("Ce lobby n'existe pas.")
		"lobby_plein":
			btn_rejoindre.disabled = false
			_feedback_erreur("Ce lobby est plein.")
		"partie_commencee":
			btn_rejoindre.disabled = false
			_feedback_erreur("La partie a déjà commencé")
		#""

func _on_lobby_rejoint(_joueurs: Array):
	# Lobby rejoint avec succès → salle d'attente
	#get_tree().set_meta("nb_joueurs", LobbyHandler.get_joueurs().size()	)
	get_tree().change_scene_to_file("res://scene/Multijoueur/attente_lobby.tscn")


# ----------------------------------------------------------------
# FEEDBACK ERREUR
# ----------------------------------------------------------------
func _feedback_erreur(message: String):
	# Affiche le message en rouge
	label_erreur.text = message
	label_erreur.visible = true
	
	for panel in panels:
		panel.add_theme_stylebox_override("panel", style_error)
	
	# Animation secousse
	var pos_origine = position
	var tween = create_tween()
	tween.tween_property(self, "position", pos_origine + Vector2(-12, 0), 0.05)
	tween.tween_property(self, "position", pos_origine + Vector2( 12, 0), 0.05)
	tween.tween_property(self, "position", pos_origine + Vector2( -8, 0), 0.05)
	tween.tween_property(self, "position", pos_origine + Vector2(  8, 0), 0.05)
	tween.tween_property(self, "position", pos_origine, 0.05)
	await tween.finished
	#for i in 6:
		#panels[i].add_theme_stylebox_override(
			#"panel",
			#style_filled if i < code.length() else style_empty
		#)
	code = ""
	_update_boxes()


# ----------------------------------------------------------------
# STYLES
# ----------------------------------------------------------------
func _init_styles():
	_setup_style(style_filled, Color(1,1,1,0.18), Color(1,1,1,0.9),    4, 18)
	_setup_style(style_empty,  Color(1,1,1,0.06), Color(1,1,1,0.35),   4, 18)
	_setup_style(style_error,  Color(0.6,0.05,0.05,0.5), Color(1,0.1,0.1,1), 4, 18)

func _setup_style(style: StyleBoxFlat, bg: Color, border: Color, border_w: int, radius: int):
	style.bg_color = bg
	style.border_color = border
	for side in ["left", "top", "right", "bottom"]:
		style.set("border_width_" + side, border_w)
	for corner in ["top_left", "top_right", "bottom_right", "bottom_left"]:
		style.set("corner_radius_" + corner, radius)
