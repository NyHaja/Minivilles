class_name Game_Play extends Control

signal choice_made(input: int)
signal roll_dice_siganl
signal purchase_signal

# Joueur
@onready var pseudo: Label = $"PRINCIPAL/MAIN/INFO BASE/JOUEUR/Pseudo"
@onready var balance: Label = $"PRINCIPAL/MAIN/INFO BASE/Gold/BALANCE"
@onready var deck: HBoxContainer = $"PRINCIPAL/MAIN/INFO BASE/DECK"

# Shop
@onready var list_shop: HBoxContainer = $PRINCIPAL/MAIN/SHOP/Liste
@onready var buy_button: Button = $PRINCIPAL/MAIN/SHOP/acheter

var selected_card: CardView = null
var selected_card_id: int = -1

var card_view_scene = preload("res://card_view.tscn")

# Dé
@onready var button: Button = %one
@onready var button_2: Button = %two
@onready var result: Label = $"PRINCIPAL/MAIN/Dé/Resultat/Resultat"
@onready var d_2: Label = $"PRINCIPAL/MAIN/Dé/Resultat/D2"
@onready var d_1: Label = $"PRINCIPAL/MAIN/Dé/Resultat/D1"
@onready var button_roll: Button = $"PRINCIPAL/MAIN/Dé/LANCER"
@onready var dice_window: VBoxContainer = $PRINCIPAL/MAIN/Dé

var dice_count: int = 1
var window_open: bool = false


func _ready() -> void:
	set_process_unhandled_input(false)

	if button:
		button.pressed.connect(_button_1_press)
	if button_2:
		button_2.pressed.connect(_button_2_press)
	if button_roll:
		button_roll.pressed.connect(show_roll_modal)
	if buy_button:
		buy_button.pressed.connect(purchase_modal)


func showBasicPlayerInfo(j: Player):
	self.pseudo.text = j.username
	self.balance.text = String.num(j.balance, 0)
	showdeck(j.deck)


func RefreshBasicInfo(game: Game) -> void:
	set_process_unhandled_key_input(true)
	await get_tree().create_timer(1).timeout
	resetshowdice()
	showBasicPlayerInfo(game.getActivePlayer())
	reset_select_card()
	showShop(game.shop)


func showdeck(player_deck: Array) -> void:
	print("showdeck called")
	for child in self.deck.get_children():
		child.queue_free()

	var i := 0
	for instance in player_deck:
		var card_id = instance[0]
		var quantity = instance[1]

		var card_data = CardFactory.get_card_by_id(card_id)
		if card_data == null:
			continue

		var card: CardView = card_view_scene.instantiate()
		self.deck.add_child(card)
		card.setup(card_data)

		# Optionnel : afficher la quantité dans l'ID
		card.set_quantity(quantity)

		card.play_spawn_animation(i * 0.05)
		i += 1


# SHOP
func showShop(shop: Shop):
	print("showShop called")
	for child in list_shop.get_children():
		child.queue_free()

	var i := 0
	for slot in shop.shop:
		var card_data = CardFactory.get_card_by_id(slot.id)
		if card_data == null:
			continue

		var card: CardView = card_view_scene.instantiate()
		list_shop.add_child(card)
		card.setup(card_data)
		card.play_spawn_animation(i * 0.05)

		card.gui_input.connect(func(event): _on_shop_card_input(event, card, slot.id))

		i += 1
		print("Creating shop card")


func _on_shop_card_input(event: InputEvent, card: CardView, id: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_select_shop(card, id)


func card_select_shop(card: CardView, id: int):
	if selected_card:
		selected_card.set_selected(false)

	selected_card = card
	selected_card_id = id
	selected_card.set_selected(true)


func reset_select_card():
	if selected_card == null:
		return

	selected_card.set_selected(false)
	selected_card = null
	selected_card_id = -1


func buy():
	await purchase_signal
	return [Game.CHOICE.Build_ESTABLISHMENT, selected_card_id]


func purchase_modal():
	if selected_card:
		purchase_signal.emit()


### Dé
func resetshowdice():
	dice_window.hide()
	showResult(0, 0)


func _button_1_press() -> void:
	choice_modal("1")
	button_2.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_color", Color.RED)


func _button_2_press() -> void:
	choice_modal("2")
	button.add_theme_color_override("font_color", Color.WHITE)
	button_2.add_theme_color_override("font_color", Color.RED)


func howManyDice() -> int:
	dice_window.show()
	set_process_unhandled_key_input(true)
	await roll_dice_siganl
	return dice_count


func choice_modal(input: String) -> void:
	set_process_unhandled_key_input(false)
	choice_made.emit(input)
	set_deferred("window_open", false)
	set_deferred("dice_count", int(input))


func show_roll_modal():
	roll_dice_siganl.emit()


func showResult(res1: int, res2: int):
	d_1.text = String.num(res1, 0)
	d_2.text = String.num(res2, 0)
