extends Node
class_name Jeu

signal action_selected(choide_data:Array)
signal dice_amount_chosen(amount: int)
signal yes_no_answered(result: bool)

var current_player: Player
var test_shop: Shop
var game:Game

@onready var shop_container: GridContainer = %ShopContainer

@onready var btn_roll_1: Button = %BtnRoll1
@onready var btn_roll_2: Button = %BtnRoll2
@onready var lbl_dice: Label = %LblDice

@onready var acrtive_deck_container: HFlowContainer = %ActiveDeckContainer
@onready var active_name: Label = %ActiveName
@onready var lbl_active_gold: Label = %LblActiveGold
@onready var lbl_active_stats: Label = %LblActiveStats

@onready var player2_deck_container: HFlowContainer = %Player2DeckContainer
@onready var lbl_p2_name: Label = %Player2Name
@onready var lbl_p2_gold: Label = %LblP2Gold
@onready var lbl_p2_stats: Label = %LblP2Stats

@onready var open_monuments: Button = %OpenMonuMenu
@onready var monument_menu: ColorRect = $MonumentMenu
@onready var confirm_buy: Button = $MonumentMenu/BuySelected
@onready var close_menu: Button = $MonumentMenu/Close
@onready var monument_info: Label = $MonumentMenu/MonuInfo

@onready var victory_screen: ColorRect = $VictoryScreen
@onready var lbl_winner_name: Label = $VictoryScreen/LblWinnerName
@onready var btn_quit: Button = $VictoryScreen/ReturnToMenu

@onready var yes_no_panel: ColorRect = %YesNoPanel
@onready var lbl_question: Label = %LblQuestion
@onready var btn_yes: Button = %BtnYes
@onready var btn_no: Button = %BtnNo

var selected_monument_id: int = -1

#Dé
var  DiceNUmber :int = 1
var card_view_scene = preload("res://card_view.tscn")
var selected_shop_card: CardView = null
var selected_shop_card_id: int = -1

func _ready() -> void:
	%Skip.pressed.connect(_on_skip_pressed)
	open_monuments.pressed.connect(_on_open_monuments_pressed)
	close_menu.pressed.connect(_on_close_menu_pressed)
	confirm_buy.pressed.connect(_on_confirm_buy_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)
	btn_yes.pressed.connect(_on_yes_pressed)
	btn_no.pressed.connect(_on_no_pressed)
	
	setup_monument_button($MonumentMenu/BuildGare, Monument.MONUMENT_ID.Gare)
	setup_monument_button($MonumentMenu/BuildCentreCommercial, Monument.MONUMENT_ID.Centre_Commercial)
	setup_monument_button($MonumentMenu/BuildParcAttraction, Monument.MONUMENT_ID.Parc)
	setup_monument_button($MonumentMenu/BuildRadio, Monument.MONUMENT_ID.Radio)
	setup_monument_button($MonumentMenu/BuildAeroport, Monument.MONUMENT_ID.Aeroport)
	setup_monument_button($MonumentMenu/BuildPort, Monument.MONUMENT_ID.Port)
	
	btn_roll_2.disabled = true
	
	print("\n=== GAME STARTED ===")

	
func RefreshBasicInfo(current_game: Game) -> void:
	self.game = current_game
	self.current_player = game.getActivePlayer()
	self.test_shop = game.shop
	
	print("It is now ", current_player.username, "'s turn! \n")
	
	update_shop_ui()
	update_deck_ui()
	update_opponent_ui()
	updateMonumentColors()
	print_player_stats()
	update_names()
	
	set_actions_enabled(false) 
	set_dice_buttons_enabled(true)




func ask_yes_no(question: String) -> bool:
	lbl_question.text = question
	yes_no_panel.show()
	
	var result = await yes_no_answered
	
	yes_no_panel.hide()
	return result

func _on_yes_pressed() -> void:
	yes_no_answered.emit(true)

func _on_no_pressed() -> void:
	yes_no_answered.emit(false)






func howManyDice() -> int:
	print("Waiting for ", current_player.username ," to choose dice amount...")
	btn_roll_1.disabled = false
	
	btn_roll_2.disabled = not current_player.monumentIsActive(Monument.MONUMENT_ID.Gare)
	
	var amount = await dice_amount_chosen
	
	btn_roll_1.disabled = true
	btn_roll_2.disabled = true
	
	return amount

func showResult(d1: int, d2: int) -> void:
	if d2 == 0:
		lbl_dice.text = "Rolled: " + str(d1)
	else:
		lbl_dice.text = "Rolled: " + str(d1) + " + " + str(d2) + " = " + str(d1 + d2)
		
func pause() -> Array:
	print("Waiting for ", current_player.username, "to take an action...")
	print_player_stats() 
	update_opponent_ui()
	set_actions_enabled(true)
	var choice = await action_selected
	set_actions_enabled(false)
	return choice

func next_round(): #Init les variables
	current_player = game.getActivePlayer()
	update_deck_ui()
	DiceNUmber = 1 # BOUTON 1 DOIT ETRE SELECTIONNER PAR DEFAUT
	




func waitForDiceRoll() -> int:
	set_actions_enabled(false)
	set_dice_buttons_enabled(true)
	
	var amount = await dice_amount_chosen
	
	set_dice_buttons_enabled(false)
	return amount
	
func set_actions_enabled(can_act: bool) -> void:
	%Skip.disabled = !can_act
	open_monuments.disabled = !can_act
	
	#for btn in shop_container.get_children():
	#	btn.disabled = !can_act
	
func set_dice_buttons_enabled(can_roll: bool) -> void:
	btn_roll_1.disabled = !can_roll
	
	if can_roll and current_player.monumentIsActive(Monument.MONUMENT_ID.Gare):
		btn_roll_2.disabled = false
	else:
		btn_roll_2.disabled = true
	

func _on_roll_1_pressed() -> void:
	dice_amount_chosen.emit(1)
	
	# TRIGGER EFFECTS A VOIR AVEC CLEMENT
	
func _on_roll_2_pressed() -> void:
	dice_amount_chosen.emit(2)
	
	# TRIGGER EFFECTS A VOIR AVEC CLEMENT
	
	
	
	
func setup_monument_button(btn: Button, monu_id: int) -> void:
	
	# Red (Not Bought)
	var red_style = StyleBoxFlat.new()
	red_style.bg_color = Color(0.6, 0.1, 0.1) 
	btn.add_theme_stylebox_override("normal", red_style)
	btn.add_theme_stylebox_override("hover", red_style) 
	
	# Green (Bought)
	var green_style = StyleBoxFlat.new()
	green_style.bg_color = Color(0.1, 0.6, 0.1) 
	btn.add_theme_stylebox_override("pressed", green_style)
	btn.add_theme_stylebox_override("hover_pressed", green_style) 
	
	btn.button_pressed = false
	
	btn.pressed.connect(_on_monument_selected.bind(monu_id))




func _on_open_monuments_pressed() -> void:
	selected_monument_id = -1
	confirm_buy.disabled = true
	monument_info.text = "Select a monument to view details."
	monument_menu.show()

func _on_close_menu_pressed() -> void:
	monument_menu.hide()

func _on_monument_selected(monu_id: int) -> void:
	selected_monument_id = monu_id
	confirm_buy.disabled = false
	
	var data = game.getMonumentData(monu_id)
	monument_info.text = data["name"] + "\nCost: " + str(data["cost"]) + " Gold"

func _on_confirm_buy_pressed() -> void:
	monument_menu.hide()
	action_selected.emit([Game.CHOICE.Build_MONUMENT, selected_monument_id])

func _on_buy_pressed(card_id: int) -> void:
	action_selected.emit([game.CHOICE.Build_ESTABLISHMENT, card_id])
	
func _on_skip_pressed() -> void:
	action_selected.emit([game.CHOICE.SKIP, 0])




func _on_add_gold_pressed() -> void:
	current_player.recieveGold(5)
	print("\n[+] Added 5 Gold.")
	print_player_stats()

func _on_remove_gold_pressed() -> void:
	current_player.loseGold(2)
	print("\n[-] Lost 2 Gold.")
	print_player_stats()


func _on_shop_card_input(event: InputEvent, card: CardView, id: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if selected_shop_card:
			selected_shop_card.set_selected(false)

		selected_shop_card = card
		selected_shop_card_id = id
		selected_shop_card.set_selected(true)

		_on_buy_pressed(id)

func update_shop_ui() -> void:
	for child in shop_container.get_children():
		child.queue_free()

	var i := 0
	for slot in test_shop.shop:
		var card_data = current_player.get_card_from_factory(slot.id)
		if card_data == null:
			continue

		var card: CardView = card_view_scene.instantiate()
		shop_container.add_child(card)
		card.setup(card_data)
		card.set_quantity(slot.quantity)
		card.play_spawn_animation(i * 0.05)

		card.gui_input.connect(func(event): _on_shop_card_input(event, card, slot.id))

		i += 1

func update_deck_ui() -> void:
	for child in acrtive_deck_container.get_children():
		child.queue_free()

	var i := 0
	for instance in current_player.deck:
		if typeof(instance) != TYPE_ARRAY:
			continue

		var card_id = instance[0]
		var quantity = instance[1]

		var card_data = current_player.get_card_from_factory(card_id)
		if card_data == null:
			continue

		for j in range(quantity):
			var card: CardView = card_view_scene.instantiate()
			acrtive_deck_container.add_child(card)
			card.setup(card_data)
			card.play_spawn_animation(i * 0.03)
			i += 1		
	
func update_names() -> void:
	active_name.text = current_player.username
	
	
func updateMonumentColors() -> void:
	check_and_color_monument($MonumentMenu/BuildGare, Monument.MONUMENT_ID.Gare)
	check_and_color_monument($MonumentMenu/BuildCentreCommercial, Monument.MONUMENT_ID.Centre_Commercial)
	check_and_color_monument($MonumentMenu/BuildParcAttraction, Monument.MONUMENT_ID.Parc)
	check_and_color_monument($MonumentMenu/BuildRadio, Monument.MONUMENT_ID.Radio)
	check_and_color_monument($MonumentMenu/BuildAeroport, Monument.MONUMENT_ID.Aeroport)
	check_and_color_monument($MonumentMenu/BuildPort, Monument.MONUMENT_ID.Port)

	
func check_and_color_monument(btn: Button, monu_id: int) -> void:
	var style = StyleBoxFlat.new()
	
	if current_player.monumentIsActive(monu_id):
		style.bg_color = Color(0.1, 0.6, 0.1)
	else:
		style.bg_color = Color(0.6, 0.1, 0.1)
		
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)

func update_opponent_ui() -> void:
	for child in player2_deck_container.get_children():
		child.queue_free()

	for player in game.playerArray:
		if player == current_player:
			continue

		lbl_p2_name.text = player.username
		lbl_p2_gold.text = "Gold: " + str(player.balance)
		lbl_p2_stats.text = "Establishments: " + str(player.establishmentCount) + "\nMonuments: " + str(player.monumentCount)

		var i := 0
		for instance in player.deck:
			var card_id = instance[0]
			var quantity = instance[1]
			var card_data = player.get_card_from_factory(card_id)

			if card_data == null:
				continue

			for j in range(quantity):
				var card: CardView = card_view_scene.instantiate()
				player2_deck_container.add_child(card)
				card.setup(card_data)
				card.scale = Vector2(0.7, 0.7)
				card.play_spawn_animation(i * 0.02)
				i += 1

func show_victory_screen(winner_name: String) -> void:
	set_actions_enabled(false)
	set_dice_buttons_enabled(false)
	
	lbl_winner_name.text = "🏆 " + winner_name + " WINS! 🏆\nAll 5 Monuments Built!"
	victory_screen.show()
	
func _on_quit_pressed() -> void:
	get_tree().change_scene_to_file("res://MainMenu.tscn")


func print_player_stats() -> void:
	lbl_active_gold.text = "Gold: " + str(current_player.balance)
	lbl_active_stats.text = "Establishments: " + str(current_player.establishmentCount) + "\nMonuments: " + str(current_player.monumentCount)
	
	print("--- PLAYER STATS ---")
	print("Current Player: ", current_player.username)
	print("Gold: ", current_player.balance)
	print("Establishments: ", current_player.establishmentCount)
	print("Monuments: ", current_player.monumentCount)
	print("Deck Array: ", current_player.deck)
	print("--------------------")
