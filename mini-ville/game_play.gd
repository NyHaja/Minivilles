class_name Game_Play extends Control

signal choix(input : int)

@onready var button: Button = %one
@onready var button_2: Button = %two
@onready var resultat: Label = $ColorRect/Dé/VBoxContainer/Resultat
@onready var d_2: Label = $ColorRect/Dé/VBoxContainer/HBoxContainer2/D2
@onready var d_1: Label = $ColorRect/Dé/VBoxContainer/HBoxContainer2/D1

var window_open : bool = false

func _ready() -> void:
	set_process_unhandled_input(false) #desactive les autre input non gére
	if button:
		button.pressed.connect(_button_1_press)
	if button_2:
		button_2.pressed.connect(_button_2_press)
	hide()
	
func _button_1_press() -> void:
	_close_modal("1")

func _button_2_press() -> void:
	_close_modal("2")
	
func prompt() -> int:
	show()
	window_open = true
	set_process_unhandled_key_input(true)
	var choixattendu:String = await choix
	return int(choixattendu)
	
func _close_modal(input:String) -> void:
	set_process_unhandled_key_input(false)
	choix.emit(input)
	set_deferred("window_open", false)
	#hide()

func affiche_resultat(res1:int,res2:int):
	d_1.text = String.num(res1,0)
	d_2.text = String.num(res2,0)
