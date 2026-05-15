extends Control

var durations = ["1 min", "2 min", "3 min", "5 min"]
var dur_index = 1
var nb_joueurs = 2
var is_private = false

const ICON_WIDTH = 91.0
const ICON_GAP = 39.0
const ICON_STEP = ICON_WIDTH + ICON_GAP
const ICON_Y_TOP = 0.0
const ICON_Y_BOTTOM = 125.0
const CENTER_X = 280.0

var pop_setting_scene = preload("res://scene/popup/popup_parametres.tscn")
var popup_setting

func _ready():

	%LabelDuree.text = durations[dur_index]
	%ArrowGaucheDuree.pressed.connect(_on_duree_gauche)
	%ArrowDroiteDuree.pressed.connect(_on_duree_droite)
	%ArrowGaucheJoueurs.pressed.connect(_on_joueurs_gauche)
	%ArrowDroiteJoueurs.pressed.connect(_on_joueurs_droite)
	_update_joueurs()
	$VBoxContainer/backbtn.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			get_tree().change_scene_to_file("res://scene/Multijoueur/choix_game.tscn"))
	
	# ------------ signal ----------------------------
	LobbyHandler.lobby_creer_signal.connect(_on_lobby_cree)
	$Content/BtnCreerWrap/BtnCreer.pressed.connect(_on_btn_creer_pressed)
	
	popup_setting = pop_setting_scene.instantiate()
	
	add_child(popup_setting)
	popup_setting.hide()
	$settingbtn/TextureButton.pressed.connect(affiche_parametre)
	
func affiche_parametre():
	SoundManager.play_click()
	popup_setting.show()	

func _on_duree_gauche():
	dur_index = (dur_index - 1 + durations.size()) % durations.size()
	%LabelDuree.text = durations[dur_index]


func _on_duree_droite():
	dur_index = (dur_index + 1) % durations.size()
	%LabelDuree.text = durations[dur_index]


func _on_joueurs_gauche():
	nb_joueurs = max(2, nb_joueurs - 1)
	_update_joueurs()


func _on_joueurs_droite():
	nb_joueurs = min(4, nb_joueurs + 1)
	_update_joueurs()


func _update_joueurs():
	var joueurs = [%Joueur1, %Joueur2, %Joueur3, %Joueur4]
	var total_width = nb_joueurs * ICON_WIDTH + (nb_joueurs - 1) * ICON_GAP
	var start_x = CENTER_X - total_width / 2.0
	for i in 4:
		var j = joueurs[i]
		j.visible = (i + 1) <= nb_joueurs
		j.offset_left = start_x + i * ICON_STEP
		j.offset_right = j.offset_left + ICON_WIDTH
		j.offset_top = ICON_Y_TOP
		j.offset_bottom = ICON_Y_BOTTOM
		

func _on_lobby_cree(lobby_id: String):
	#Navigue vers la salle d'attente en passant le lobby_id
	$Content/BtnCreerWrap/BtnCreer.disabled = true
	#LobbyHandler.creer_lobby("Partie", nb_joueurs, dur_index)
	get_tree().set_meta("nb_joueurs", nb_joueurs)
	get_tree().set_meta("tour_duration_index", dur_index)  # ← manquait aussi
	get_tree().change_scene_to_file("res://scene/Multijoueur/attente_lobby.tscn")
	
	# Afficher le host dans la liste imédiatement
	#_rafraichir_liste(LobbyHandler.get_joueurs())

func _on_btn_creer_pressed():
	$Content/BtnCreerWrap/BtnCreer.disabled = true
	LobbyHandler.creer_lobby("Partie", nb_joueurs)
