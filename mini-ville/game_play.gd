class_name Game_Play extends Control

signal choix(input : int)
signal lancer
# Joueur
@onready var pseudo: Label = $"PRINCIPAL/MAIN/INFO BASE/JOUEUR/Pseudo"
@onready var balance: Label = $"PRINCIPAL/MAIN/INFO BASE/Gold/BALANCE"

# Dé
@onready var button: Button = %one
@onready var button_2: Button = %two
@onready var resultat: Label = $"PRINCIPAL/MAIN/Dé/Resultat/Resultat"
@onready var d_2: Label =$"PRINCIPAL/MAIN/Dé/Resultat/D2"
@onready var d_1: Label = $"PRINCIPAL/MAIN/Dé/Resultat/D1"
@onready var button_lancer: Button = $"PRINCIPAL/MAIN/Dé/LANCER"
@onready var window_dee: VBoxContainer = $PRINCIPAL/MAIN/Dé

var nbde:int = 1

var window_open : bool = false

func _ready() -> void:
	set_process_unhandled_input(false) #desactive les autre input non gére
	if button:
		button.pressed.connect(_button_1_press)
	if button_2:
		button_2.pressed.connect(_button_2_press)
	if button_lancer:
		button_lancer.pressed.connect(lancer_modal)
	

func RafraichirBasicInfo(game:Game) -> void:
	set_process_unhandled_key_input(true)
	window_dee.hide()
	afficher_basic_info_principal_joueur(game.getJoueurActif())
	await get_tree().create_timer(1).timeout
	
func afficher_basic_info_principal_joueur(j:Player):
	self.pseudo.text = j.pseudo
	self.balance.text = String.num(j.balance,0)

#Dée

func _button_1_press() -> void:
	choix_modal("1")
	button_2.add_theme_color_override("font_color",Color.WHITE)
	button.add_theme_color_override("font_color",Color.RED)
	

func _button_2_press() -> void:
	choix_modal("2")
	button.add_theme_color_override("font_color",Color.WHITE)
	button_2.add_theme_color_override("font_color",Color.RED)

func lancer_de() -> int:
	window_dee.show()
	set_process_unhandled_key_input(true)
	await lancer
	window_dee.hide()
	return nbde
	
func choix_modal(input:String) -> void:
	set_process_unhandled_key_input(false)
	choix.emit(input)
	set_deferred("window_open", false)
	set_deferred("nbde", int(input))

func lancer_modal():
	lancer.emit()
	
func affiche_resultat(res1:int,res2:int):
	d_1.text = String.num(res1,0)
	d_2.text = String.num(res2,0)
