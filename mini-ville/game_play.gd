class_name Game_Play extends Control

signal choix(input : int)
signal lancer
signal purchase
# Joueur
@onready var pseudo: Label = $"PRINCIPAL/MAIN/INFO BASE/JOUEUR/Pseudo"
@onready var balance: Label = $"PRINCIPAL/MAIN/INFO BASE/Gold/BALANCE"
@onready var deck: HBoxContainer = $"PRINCIPAL/MAIN/INFO BASE/DECK"


#Shop
@onready var Listshop: HBoxContainer = $PRINCIPAL/MAIN/SHOP/Liste
var card_selec : Button = null
var card_selec_id :int = -1
@onready var acheter: Button = $PRINCIPAL/MAIN/SHOP/acheter

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
	if acheter:
		acheter.pressed.connect(purchase_modal)
	
func afficher_basic_info_principal_joueur(j:Player):
	self.pseudo.text = j.username
	self.balance.text = String.num(j.balance,0)
	showdeck(j.deck)

func RefreshBasicInfo(game:Game) -> void:
	set_process_unhandled_key_input(true)
	await get_tree().create_timer(1).timeout
	resetshowdice()
	afficher_basic_info_principal_joueur(game.getActivePlayer())
	reset_select_card()
	showShop(game.shop)
	

func showdeck(deck:Array[int]):
	for child in self.deck.get_children():
		child.queue_free()
	for id in deck:
		var newl :Label = Label.new()
		newl.text = String.num(id,0)
		self.deck.add_child(newl)
	
# SHOP

func showShop(shop:Shop):
	for child in Listshop.get_children():
		child.queue_free()
	for slot in shop.shop:
		var newb:Button = Button.new()
		newb.text = String.num(slot.id,0)
		Listshop.add_child(newb)
		newb.pressed.connect(func():card_select_shop(newb,slot.id))
		
func card_select_shop(b:Button,id:int):
	if card_selec:
		card_selec.add_theme_color_override("font_color",Color.WHITE)
	card_selec = b
	card_selec_id = id
	b.add_theme_color_override("font_color",Color.RED)
	
func reset_select_card():
	if card_selec == null:
		return
	card_selec.add_theme_color_override("font_color",Color.WHITE)
	card_selec = null
	card_selec_id = -1

func buy():
	await purchase
	return [Game.CHOICE.Build_ESTABLISHMENT,card_selec_id]

func purchase_modal():
	if card_selec :
		purchase.emit()
###Dée

func resetshowdice():
	window_dee.hide()
	showResult(0,0)
		
func _button_1_press() -> void:
	choix_modal("1")
	button_2.add_theme_color_override("font_color",Color.WHITE)
	button.add_theme_color_override("font_color",Color.RED)
	
func _button_2_press() -> void:
	choix_modal("2")
	button.add_theme_color_override("font_color",Color.WHITE)
	button_2.add_theme_color_override("font_color",Color.RED)

func rollDice() -> int:
	window_dee.show()
	set_process_unhandled_key_input(true)
	await lancer
	return nbde
	
func choix_modal(input:String) -> void:
	set_process_unhandled_key_input(false)
	choix.emit(input)
	set_deferred("window_open", false)
	set_deferred("nbde", int(input))

func lancer_modal():
	lancer.emit()
	
func showResult(res1:int,res2:int):
	d_1.text = String.num(res1,0)
	d_2.text = String.num(res2,0)
