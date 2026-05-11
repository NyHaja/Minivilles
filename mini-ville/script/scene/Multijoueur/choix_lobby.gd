extends Control

var pop_setting_scene = preload("res://scene/popup/popup_parametres.tscn")
var popup_setting

var pop_login_scene = preload("res://scene/popup/popup_login.tscn")
var popup_login

@onready var connexion_requise = $PanelConnexionRequise

func _ready():
	# print("[choix_lobby] _ready() appelé depuis : ", get_stack())
	$Content/gameMode/BtnRejoindreWrap/BtnRejoindre.pressed.connect(func(): 
		get_tree().change_scene_to_file("res://scene/Multijoueur/rejoindre_lobby.tscn"))
	$HBoxContainer2/BtnRetour/BtnBack.pressed.connect(func():
		get_tree().change_scene_to_file("res://scene/Ecran principale/mode_de_jeu.tscn"))
		
	popup_setting = pop_setting_scene.instantiate()
	popup_login = pop_login_scene.instantiate()
	
	add_child(popup_login)
	add_child(popup_setting)
	popup_setting.hide()
	popup_login.hide()
	connexion_requise.hide()
	
func affiche_parametre():
	SoundManager.play_click()
	#$Content/gameMode.hide()
	popup_setting.show()

func _on_btn_creer_pressed():
	var est_guest    = NetworkManager.est_guest()
	var est_connecte = NetworkManager.est_connecte() and not est_guest

	print("[DEBUG] est_guest=", est_guest, " est_connecte=", est_connecte)

	if not est_connecte:
		_afficher_panel_connexion_requise()
	else:
		get_tree().change_scene_to_file("res://scene/Multijoueur/creation_lobby.tscn")

func _afficher_panel_connexion_requise():
	$PanelConnexionRequise.show()
	$PanelConnexionRequise/VBoxContainer/HBoxContainer/BtnFermer.pressed.connect(func():
		$PanelConnexionRequise.hide(), CONNECT_ONE_SHOT)
	$PanelConnexionRequise/VBoxContainer/HBoxContainer/BtnSeConnecter.pressed.connect(func():
		$PanelConnexionRequise.hide()
		popup_login.show()
		, CONNECT_ONE_SHOT)
