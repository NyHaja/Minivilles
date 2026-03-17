class_name Game_Play extends Control

signal choix(input : int)
signal lancer
# Joueur
@onready var pseudo: Label = $ColorRect/Dé/VBoxContainer/JOUEUR/Pseudo
# Dé
@onready var button: Button = %one
@onready var button_2: Button = %two
@onready var resultat: Label = $"ColorRect/Dé/VBoxContainer/Dé/Resultat/Resultat"
@onready var d_2: Label =$"ColorRect/PRINCIPAL/VBoxContainer/Dé/Resultat/D2"
@onready var d_1: Label = $"ColorRect/PRINCIPAL/VBoxContainer/Dé/Resultat/D1"
@onready var button_lancer: Button = $ColorRect/PRINCIPAL/VBoxContainer/Dé/LANCER

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
	hide()
	
func _button_1_press() -> void:
	_close_modal("1")
	button_2.add_theme_color_override("font_color",Color.WHITE)
	button.add_theme_color_override("font_color",Color.RED)
	

func _button_2_press() -> void:
	_close_modal("2")
	button.add_theme_color_override("font_color",Color.WHITE)
	button_2.add_theme_color_override("font_color",Color.RED)
	
func prompt() -> void:
	show()
	window_open = true
	set_process_unhandled_key_input(true)
	#var choixattendu:String = await choix
	#return int(choixattendu)
	
func lancer_de() -> int:
	show()
	window_open = true
	set_process_unhandled_key_input(true)
	await lancer
	return nbde
	
func _close_modal(input:String) -> void:
	set_process_unhandled_key_input(false)
	choix.emit(input)
	set_deferred("window_open", false)
	set_deferred("nbde", int(input))
	
	#hide()

func lancer_modal():
	lancer.emit()
	

func affiche_resultat(res1:int,res2:int):
	d_1.text = String.num(res1,0)
	d_2.text = String.num(res2,0)
