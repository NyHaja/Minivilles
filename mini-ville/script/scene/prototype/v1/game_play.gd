class_name Game_Play extends Control

signal choice_made(input : int)
signal roll_dice_siganl
signal purchase_signal
# Joueur
@onready var pseudo: Label = $"PRINCIPAL/MAIN/INFO BASE/JOUEUR/Pseudo"
@onready var balance: Label = $"PRINCIPAL/MAIN/INFO BASE/Gold/BALANCE"
@onready var deck: HBoxContainer = $"PRINCIPAL/MAIN/INFO BASE/DECK"


#Shop
@onready var list_shop: HBoxContainer = $PRINCIPAL/MAIN/SHOP/Liste
var selected_card : Button = null
var selected_card_id :int = -1
@onready var buy_button: Button = $PRINCIPAL/MAIN/SHOP/acheter

# Dé
@onready var button: Button = %one
@onready var button_2: Button = %two
@onready var result: Label = $"PRINCIPAL/MAIN/Dé/Resultat/Resultat"
@onready var d_2: Label =$"PRINCIPAL/MAIN/Dé/Resultat/D2"
@onready var d_1: Label = $"PRINCIPAL/MAIN/Dé/Resultat/D1"
@onready var button_roll: Button = $"PRINCIPAL/MAIN/Dé/LANCER"
@onready var dice_window: VBoxContainer = $PRINCIPAL/MAIN/Dé

var dice_count: int = 1

var window_open : bool = false

func _ready() -> void:
	set_process_unhandled_input(false) #desactive les autre input non gére
	if button:
		button.pressed.connect(_button_1_press)
	if button_2:
		button_2.pressed.connect(_button_2_press)
	if button_roll:
		button_roll.pressed.connect(show_roll_modal)
	if buy_button:
		buy_button.pressed.connect(purchase_modal)
	
func showBasicPlayerInfo(j:Player):
	self.pseudo.text = j.username
	self.balance.text = String.num(j.balance,0)
	showdeck(j.deck)

func RefreshBasicInfo(game:Game) -> void:
	set_process_unhandled_key_input(true)
	await get_tree().create_timer(1).timeout
	resetshowdice()
	showBasicPlayerInfo(game.getActivePlayer())
	reset_select_card()
	showShop(game.shop)
	

func showdeck(player_deck:Array) -> void:
	for child in self.deck.get_children():
		child.queue_free()
	for instance in player_deck:
		var card_id = instance[0]
		var quantity = instance[1]
		
		var newl :Label = Label.new()
		newl.text = String.num(card_id,0)
		self.deck.add_child(newl)
	
# SHOP

func showShop(shop:Shop):
	for child in list_shop.get_children():
		child.queue_free()
	for slot in shop.shop:
		var newb:Button = Button.new()
		newb.text = String.num(slot.id,0)
		list_shop.add_child(newb)
		newb.pressed.connect(func():card_select_shop(newb,slot.id))
		
func card_select_shop(b:Button,id:int):
	if selected_card:
		selected_card.add_theme_color_override("font_color",Color.WHITE)
	selected_card = b
	selected_card_id = id
	b.add_theme_color_override("font_color",Color.RED)
	
func reset_select_card():
	if selected_card == null:
		return
	selected_card.add_theme_color_override("font_color",Color.WHITE)
	selected_card = null
	selected_card_id = -1

func buy():
	await purchase_signal # Not selected loop
	return [Game.CHOICE.Build_ESTABLISHMENT,selected_card_id]

func purchase_modal():
	if selected_card :
		purchase_signal.emit()
###Dée

func resetshowdice():
	dice_window.hide()
	showResult(0,0)
		
func _button_1_press() -> void:
	choice_modal("1")
	button_2.add_theme_color_override("font_color",Color.WHITE)
	button.add_theme_color_override("font_color",Color.RED)
	
func _button_2_press() -> void:
	choice_modal("2")
	button.add_theme_color_override("font_color",Color.WHITE)
	button_2.add_theme_color_override("font_color",Color.RED)

func howManyDice() -> int:
	dice_window.show()
	set_process_unhandled_key_input(true)
	await roll_dice_siganl
	return dice_count
	
func choice_modal(input:String) -> void:
	set_process_unhandled_key_input(false)
	choice_made.emit(input)
	set_deferred("window_open", false)
	set_deferred("dice_count", int(input))

func show_roll_modal():
	roll_dice_siganl.emit()
	
func showResult(res1:int,res2:int):
	d_1.text = String.num(res1,0)
	d_2.text = String.num(res2,0)
