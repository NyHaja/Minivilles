extends Node
class_name Jeu

signal action_selected(choide_data:Array)
signal dice_amount_chosen(amount: int)
signal yes_no_answered(result: bool)
signal player_chosen(target: Player)
signal trade_completed(trade_data: Array)
signal give_card_completed(give_data: Array)
signal demolish_completed(monu_id: int)
signal chalutier_roll_pressed()

var current_player: Player
var test_shop: Shop
var game:Game

@onready var shop_container: GridContainer = %ShopContainer

@onready var btn_roll_1: Button = %BtnRoll1
@onready var btn_roll_2: Button = %BtnRoll2
@onready var lbl_dice: Label = %LblDice


#Active Player (Bottom)

@onready var acrtive_deck_container: HBoxContainer = %ActiveDeckContainer
@onready var active_name: Label = %ActiveName
@onready var lbl_active_gold: Label = %LblActiveGold
@onready var lbl_active_stats: Label = %LblActiveStats

#Top Player

@onready var top_deck_container: HBoxContainer = %PlayerTopDeckContainer
@onready var lbl_top_name: Label = %LblPlayerTopName
@onready var lbl_top_gold: Label = %LblPlayerTopGold
@onready var lbl_top_stats: Label = %LblPlayerTopStats

#Left Player

@onready var left_deck_container: HBoxContainer = %LeftDeckContainer
@onready var lbl_left_name: Label = %LblLeftName
@onready var lbl_left_gold: Label = %LblLeftGold
@onready var lbl_left_stats: Label = %LblLeftStats

#Right Playee

@onready var right_deck_container: HBoxContainer = %RightDeckContainer
@onready var lbl_right_name: Label = %LblRightName
@onready var lbl_right_gold: Label = %LblRightGold
@onready var lbl_right_stats: Label = %LblRightStats


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

@onready var choose_player_panel: ColorRect = $ChoosePlayerPanel
@onready var player_buttons_container: VBoxContainer = $ChoosePlayerPanel/PlayerButtonsContainer
@onready var trade_panel: ColorRect = $TradePanel
@onready var trade_opponents: HBoxContainer = %TradeOpponents
@onready var trade_their_cards: HFlowContainer = %TradeTheirCards
@onready var trade_my_cards: HFlowContainer = %TradeMyCards
@onready var btn_confirm_trade: Button = %ConfirmTrade
@onready var give_panel: ColorRect = $GiveCardPanel
@onready var give_my_cards: HFlowContainer = %GiveMyCards
@onready var give_opponents: HBoxContainer = %GiveOpponents
@onready var btn_confirm_give: Button = %ConfirmGive
@onready var demolish_panel: ColorRect = $DemolishPanel
@onready var demolish_monuments: HBoxContainer = %DemolishMonuments
@onready var btn_confirm_demolish: Button = %ConfirmDemolish

@onready var buy_confirm_panel: ColorRect = $ConfirmCardBuyPanel
@onready var card_preview: Control = %CardPreview
@onready var confirm_card_buy: Button = %ConfirmCardBuy
@onready var cancel_card_buy: Button = %CancelCardBuy


@onready var chalutier_panel: ColorRect = %ChalutierPanel
@onready var lbl_chalutier_result: Label = %LblChalutierResult
@onready var chalutier_roll: Button = %ChalutierRoll

var trade_target: Player = null
var trade_their_card_id: int = -1
var trade_my_card_id: int = -1
var give_target: Player = null
var give_card_id: int = -1
var demolish_monu_id: int = -1

var selected_monument_id: int = -1

var selected_shop_card_id: int = -1

#Dé
var  DiceNUmber :int = 1


func _ready() -> void:
	%Skip.pressed.connect(_on_skip_pressed)
	open_monuments.pressed.connect(_on_open_monuments_pressed)
	close_menu.pressed.connect(_on_close_menu_pressed)
	confirm_buy.pressed.connect(_on_confirm_buy_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)
	btn_yes.pressed.connect(_on_yes_pressed)
	btn_no.pressed.connect(_on_no_pressed)
	%ConfirmTrade.pressed.connect(_on_confirm_trade_pressed)
	%ConfirmGive.pressed.connect(_on_confirm_give_pressed)
	%ConfirmDemolish.pressed.connect(_on_confirm_demolish_pressed)
	%ConfirmCardBuy.pressed.connect(_on_confirm_buy_shop_pressed)
	%CancelCardBuy.pressed.connect(_on_cancel_buy_shop_pressed)
	chalutier_roll.pressed.connect(func(): chalutier_roll_pressed.emit())
	
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
		lbl_dice.text = tr("Lancer: %s") % str(d1)
	else:
		lbl_dice.text = tr("Lancer: %s") % (str(d1) + " + " + str(d2) + " = " + str(d1 + d2))
		
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
	
	for card_visual in shop_container.get_children():
		var button = card_visual.get_node_or_null("Visual")
		if button and button is TextureButton:
			button.disabled = !can_act
	
func set_dice_buttons_enabled(can_roll: bool) -> void:
	btn_roll_1.disabled = !can_roll
	
	if can_roll and current_player.monumentIsActive(Monument.MONUMENT_ID.Gare):
		btn_roll_2.disabled = false
	else:
		btn_roll_2.disabled = true
	

func _on_roll_1_pressed() -> void:
	dice_amount_chosen.emit(1)
	
func _on_roll_2_pressed() -> void:
	dice_amount_chosen.emit(2)
	
	
	
	
func setup_monument_button(btn: Button, monu_id: int) -> void:
	
	var red_style = StyleBoxFlat.new()
	red_style.bg_color = Color(0.6, 0.1, 0.1) 
	btn.add_theme_stylebox_override("normal", red_style)
	btn.add_theme_stylebox_override("hover", red_style) 
	
	var green_style = StyleBoxFlat.new()
	green_style.bg_color = Color(0.1, 0.6, 0.1) 
	btn.add_theme_stylebox_override("pressed", green_style)
	btn.add_theme_stylebox_override("hover_pressed", green_style) 
	
	btn.button_pressed = false
	
	btn.pressed.connect(_on_monument_selected.bind(monu_id))




func _on_open_monuments_pressed() -> void:
	selected_monument_id = -1
	confirm_buy.disabled = true
	monument_info.text = tr("Sélectionner un monument")
	monument_menu.show()

func _on_close_menu_pressed() -> void:
	monument_menu.hide()

func _on_monument_selected(monu_id: int) -> void:
	selected_monument_id = monu_id
	confirm_buy.disabled = false
	
	var data = game.getMonumentData(monu_id)
	monument_info.text = data["name"] + "\n" + tr("Coût: %d Or") % data["cost"]

func _on_confirm_buy_pressed() -> void:
	monument_menu.hide()
	action_selected.emit([Game.CHOICE.Build_MONUMENT, selected_monument_id])

func _on_buy_pressed(card_id: int) -> void:
	action_selected.emit([game.CHOICE.Build_ESTABLISHMENT, card_id])
	
func _on_skip_pressed() -> void:
	action_selected.emit([game.CHOICE.SKIP, 0])




func _on_add_gold_pressed() -> void:
	current_player.receiveGold(5)
	print("\n[+] Added 5 Gold.")
	print_player_stats()

func _on_remove_gold_pressed() -> void:
	current_player.loseGold(2)
	print("\n[-] Lost 2 Gold.")
	print_player_stats()




func update_shop_ui() -> void:
	for child in shop_container.get_children():
		child.queue_free()
		
	const CARD_SCENE = preload("res://scene/table/card_Y_axis.tscn")
		
	for slot in test_shop.shop:
		var card_visual = CARD_SCENE.instantiate()
		var card_data = CardFactory.get_card(slot.id)
		
		if card_data != null:
			var card_name = card_data.get_name()
			var card_color = card_data.get_color()
			var clean_name = get_clean_file_name(card_name, card_color)
			
			var path_basis = "res://assets/Cards/Basis/" + clean_name + "_1.png"
			var path_hover = "res://assets/Cards/Hover/" + clean_name + "_2.png"
			
			var image_node = card_visual.get_node_or_null("Visual")
			if image_node is TextureButton:
				if FileAccess.file_exists(path_basis):
					image_node.texture_normal = load(path_basis)
				
				if FileAccess.file_exists(path_hover):
					image_node.texture_hover = load(path_hover)
				image_node.pressed.connect(_on_shop_card_clicked.bind(slot.id))
				
				card_visual.scale = Vector2(0.5, 0.5) 
				card_visual.custom_minimum_size = Vector2(180, 224) * 0.5
				
				var tooltip_node = card_visual.get_node_or_null("Visual/Tooltip")
				if tooltip_node:
					var tip_path = "res://assets/Tooltips/tooltip_" + clean_name + "_top.png"
					if FileAccess.file_exists(tip_path):
						tooltip_node.texture = load(tip_path)
					tooltip_node.hide()
					tooltip_node.rotation_degrees = 0

		shop_container.add_child(card_visual)

func get_clean_file_name(card_name: String, color: int) -> String:
	var prefix = ""
	match color:
		CardColor.Type.BLUE: prefix = "bleu_"
		CardColor.Type.GREEN: prefix = "vert_"
		CardColor.Type.RED: prefix = "rouge_"
		CardColor.Type.PURPLE: prefix = "violet_"
		
	var clean_name = card_name.to_lower().replace(" ", "_")
	clean_name = clean_name.replace("é", "e").replace("è", "e").replace("à", "a").replace("'", "_")
	
	return prefix + clean_name



func update_deck_ui() -> void:
	var piles = {
		CardColor.Type.BLUE: %BluePileBottom,
		CardColor.Type.GREEN: %GreenPileBottom,
		CardColor.Type.RED: %RedPileBottom,
		CardColor.Type.PURPLE: %PurplePileBottom
	}
	
	const CARD_SCENE = preload("res://scene/table/card_Y_axis.tscn")
	
	for pile in piles.values():
		for child in pile.get_children():
			child.queue_free()
			
	var pile_counts = {
		CardColor.Type.BLUE: 0,
		CardColor.Type.GREEN: 0,
		CardColor.Type.RED: 0,
		CardColor.Type.PURPLE: 0
	}
	
	for instance in current_player.deck:
		if typeof(instance) != TYPE_ARRAY: continue
		
		var card_id = instance[0]
		var quantity = instance[1]
		var card_data = CardFactory.get_card(card_id)
		
		if card_data != null:
			var color = card_data.get_color()
			var target_pile = piles[color]
			
			for i in range(quantity):
				var card_visual = CARD_SCENE.instantiate()
				var card_name = card_data.get_name() 
				var card_color = card_data.get_color()
				
				var clean_name = get_clean_file_name(card_name, card_color)
				
				var path_basis = "res://assets/Cards/Basis/" + clean_name + "_1.png"
				var path_hover = "res://assets/Cards/Hover/" + clean_name + "_2.png"
				
				if FileAccess.file_exists(path_basis):
					var image_node = card_visual.get_node_or_null("Visual")
					if image_node is TextureButton:
						image_node.texture_normal = load(path_basis)
						
						var card_scale = 1
						card_visual.scale = Vector2(card_scale, card_scale)
						
						image_node.ignore_texture_size = true
						image_node.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
						
						if FileAccess.file_exists(path_hover):
							image_node.texture_hover = load(path_hover)
				else:
					print("Warning: Art missing for ", path_basis)
					
				var tooltip_node = card_visual.get_node_or_null("Tooltip")
				if tooltip_node:
					var tip_path = "res://assets/Tooltips/tooltip_" + clean_name + "_top.png"
					if FileAccess.file_exists(tip_path):
						tooltip_node.texture = load(tip_path)
						tooltip_node.hide()
						
				var stack_gap = 25 
				var offset_x = pile_counts[card_color] * stack_gap 
				var push_up_amount = -60 
				
				card_visual.position = Vector2(offset_x, push_up_amount)
					
				target_pile.add_child(card_visual)
				pile_counts[card_color] += 1


func get_texture_path_from_name(card_name: String, color: int) -> String:
	var prefix = ""
	match color:
		0: prefix = "Bleu_"
		1: prefix = "Vert_"
		2: prefix = "Rouge_"
		3: prefix = "violet_"
	
	var clean_name = card_name.to_lower().replace(" ", "_")
	clean_name = clean_name.replace("é", "e").replace("è", "e").replace("à", "a")
	
	return "res://assets/Cards/Basis/" + prefix + clean_name + " 2.png"



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
	var opponent_slots = [
		{ 
			"name": lbl_right_name, "gold": lbl_right_gold, "stats": lbl_right_stats, "parent": right_deck_container,
			"piles": { CardColor.Type.BLUE: %BluePileRight, CardColor.Type.GREEN: %GreenPileRight, CardColor.Type.RED: %RedPileRight, CardColor.Type.PURPLE: %PurplePileRight},
			"axis": "X",
			"rotation": 90
		},
		{ 
			"name": lbl_top_name, "gold": lbl_top_gold, "stats": lbl_top_stats, "parent": top_deck_container,
			"piles": { CardColor.Type.BLUE: %BluePileTop, CardColor.Type.GREEN: %GreenPileTop, CardColor.Type.RED: %RedPileTop, CardColor.Type.PURPLE: %PurplePileTop},
			"axis": "Y",
			"rotation": 180
		},
		{ 
			"name": lbl_left_name, "gold": lbl_left_gold, "stats": lbl_left_stats, "parent": left_deck_container,
			"piles": { CardColor.Type.BLUE: %BluePileLeft, CardColor.Type.GREEN: %GreenPileLeft, CardColor.Type.RED: %RedPileLeft, CardColor.Type.PURPLE: %PurplePileLeft},
			"axis": "X",
			"rotation": 90
		}
	]
	
	const CARD_X_SCENE = preload("res://scene/table/card_X_axis.tscn")
	const CARD_Y_SCENE = preload("res://scene/table/card_Y_axis.tscn")
	
	for slot in opponent_slots:
		slot["name"].text = ""
		slot["gold"].text = ""
		slot["stats"].text = ""
		slot["parent"].get_parent().hide() 
		for pile in slot["piles"].values():
			for child in pile.get_children():
				child.queue_free()
	
	var current_index = game.playerArray.find(current_player)
	
	for i in range(1, game.playerCount):
		var target_index = (current_index + i) % game.playerCount
		var opponent = game.playerArray[target_index]
		
		var active_slot = opponent_slots[1] if game.playerCount == 2 else opponent_slots[i - 1] 
		active_slot["parent"].get_parent().show() 
		
		active_slot["name"].text = opponent.username 
		active_slot["gold"].text = tr("Or: %d") % opponent.balance
		active_slot["stats"].text = tr("Éta: %d\nMonu: %d") % [opponent.establishmentCount, opponent.monumentCount]
		
		var pile_counts = { CardColor.Type.BLUE: 0, CardColor.Type.GREEN: 0, CardColor.Type.RED: 0, CardColor.Type.PURPLE: 0 }

		for instance in opponent.deck: 
			if typeof(instance) != TYPE_ARRAY: continue 
			
			var card_id = instance[0] 
			var quantity = instance[1] 
			var card_data = CardFactory.get_card(card_id) 
			
			if card_data != null:
				var color = card_data.get_color()
				var target_pile = active_slot["piles"][color]
				var card_name = card_data.get_name()
				
				for j in range(quantity):
					var card_visual
					var tex_width = 180 
					var tex_height = 224 
					
					if active_slot["axis"] == "Y":
						card_visual = CARD_Y_SCENE.instantiate()
						card_visual.custom_minimum_size = Vector2(tex_width, tex_height)
						card_visual.size = Vector2(tex_width, tex_height)
					else:
						card_visual = CARD_X_SCENE.instantiate()
						card_visual.custom_minimum_size = Vector2(tex_height, tex_width)
						card_visual.size = Vector2(tex_height, tex_width)

					var clean_name = get_clean_file_name(card_name, color)
					var path_basis = "res://assets/Cards/Basis/" + clean_name + "_1.png"
					var path_hover = "res://assets/Cards/Hover/" + clean_name + "_2.png"
					
					if FileAccess.file_exists(path_basis):
						var image_node = card_visual.get_node_or_null("Visual")
						if image_node != null and image_node is TextureButton:
							image_node.texture_normal = load(path_basis)
							
							image_node.custom_minimum_size = Vector2(tex_width, tex_height)
							image_node.size = Vector2(tex_width, tex_height)
							image_node.ignore_texture_size = true
							image_node.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED 
							
							image_node.pivot_offset = Vector2(tex_width / 2.0, tex_height / 2.0)
							
							if active_slot["axis"] == "Y":
								image_node.position = Vector2(0, 0)
							else:
								image_node.position = Vector2((tex_height - tex_width) / 2.0, (tex_width - tex_height) / 2.0)
							
							image_node.rotation_degrees = active_slot["rotation"]
							
							card_visual.base_pos = image_node.position
							
							if active_slot["name"] == lbl_top_name:
								card_visual.hover_offset = Vector2(0, 50)
							elif active_slot["name"] == lbl_left_name:
								card_visual.hover_offset = Vector2(50, 0)
							elif active_slot["name"] == lbl_right_name:
								card_visual.hover_offset = Vector2(50, 0)
							
							var card_scale = 0.35 
							card_visual.scale = Vector2(card_scale, card_scale)
							
							if FileAccess.file_exists(path_hover):
								image_node.texture_hover = load(path_hover)
					else:
						var placeholder = ColorRect.new()
						placeholder.color = Color(1.0, 0.0, 1.0, 0.5) 
						placeholder.custom_minimum_size = card_visual.custom_minimum_size
						placeholder.scale = Vector2(0.35, 0.35) 
						card_visual.add_child(placeholder)
						
					var stack_gap = 25 
					
					if active_slot["axis"] == "Y":
						var base_x_offset = 100
						
						var offset_x = (pile_counts[color] * stack_gap) + base_x_offset 
						card_visual.position = Vector2(offset_x, 100)
					else:
						var base_y_offset = 120
						var screen_vertical = (pile_counts[color] * stack_gap) + base_y_offset
						
						var screen_horizontal = 0
						
						if active_slot["name"] == lbl_right_name:
							screen_horizontal = 0 
							
						if active_slot["name"] == lbl_left_name:
							screen_horizontal = 0  
							
						card_visual.position = Vector2(screen_vertical, screen_horizontal)
						
					target_pile.add_child(card_visual)
					pile_counts[color] += 1




func ask_choose_player(owner: Player, all_players: Array) -> Player:
	choose_player_panel.show()
	
	for child in player_buttons_container.get_children():
		child.queue_free()

	for p in all_players:
		if p != owner:
			var btn = Button.new()
			btn.text = p.username + " (" + tr("Or: %d") % p.balance + ")"
			btn.custom_minimum_size = Vector2(200, 60)
			
			btn.pressed.connect(func(): _on_player_chosen(p))
			
			player_buttons_container.add_child(btn)
			
	var chosen_target = await player_chosen
	
	choose_player_panel.hide()
	return chosen_target

func _on_player_chosen(target: Player) -> void:
	player_chosen.emit(target)

func ask_trade_cards(owner: Player, all_players: Array) -> Array:
	trade_panel.show()
	btn_confirm_trade.disabled = true
	btn_confirm_trade.text = tr("Sélectionner des cartes à échanger...")
	trade_target = null
	trade_their_card_id = -1
	trade_my_card_id = -1
	
	for c in trade_opponents.get_children(): c.queue_free()
	for c in trade_their_cards.get_children(): c.queue_free()
	for c in trade_my_cards.get_children(): c.queue_free()
	
	for p in all_players:
		if p != owner:
			var btn = Button.new()
			btn.text = p.username
			btn.custom_minimum_size = Vector2(120, 40)
			btn.pressed.connect(func(): _on_trade_opponent_selected(p))
			trade_opponents.add_child(btn)
			
	_populate_trade_deck(owner, trade_my_cards, true)
	
	var result = await trade_completed
	trade_panel.hide()
	return result

func _on_trade_opponent_selected(target: Player) -> void:
	trade_target = target
	for c in trade_their_cards.get_children(): c.queue_free()
	_populate_trade_deck(target, trade_their_cards, false)
	_check_trade_valid()

func _populate_trade_deck(player: Player, container: Container, is_mine: bool) -> void:
	for instance in player.deck:
		if typeof(instance) != TYPE_ARRAY: continue
		var card_id = instance[0]
		var card = CardFactory.get_card(card_id)
		
		if card != null and card.color != CardColor.Type.PURPLE:
			var btn = Button.new()
			btn.text = card.name
			btn.custom_minimum_size = Vector2(80, 110)
			btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			
			var style = StyleBoxFlat.new()
			match card.color:
				CardColor.Type.BLUE: style.bg_color = Color(0.2, 0.4, 0.8)
				CardColor.Type.GREEN: style.bg_color = Color(0.2, 0.6, 0.2)
				CardColor.Type.RED: style.bg_color = Color(0.8, 0.2, 0.2)
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", style)
			btn.add_theme_color_override("font_color", Color.WHITE)
			
			btn.pressed.connect(func():
				if is_mine: trade_my_card_id = card_id
				else: trade_their_card_id = card_id
				_check_trade_valid()
				for child in container.get_children():
					if child == btn:
						child.modulate = Color(1.0, 1.0, 1.0)
					else:
						child.modulate = Color(0.4, 0.4, 0.4)
			)
			container.add_child(btn)

func _check_trade_valid() -> void:
	if trade_target != null and trade_their_card_id != -1 and trade_my_card_id != -1:
		btn_confirm_trade.disabled = false
		btn_confirm_trade.text = tr("Confirmer l'échange !")

func _on_confirm_trade_pressed() -> void:
	trade_completed.emit([trade_my_card_id, trade_target, trade_their_card_id])

func ask_give_card(owner: Player, all_players: Array) -> Array:
	give_panel.show()
	btn_confirm_give.disabled = true
	btn_confirm_give.text = tr("Sélectionner une carte et un adversaire...")
	give_target = null
	give_card_id = -1
	
	for c in give_my_cards.get_children(): c.queue_free()
	for c in give_opponents.get_children(): c.queue_free()
	
	for instance in owner.deck:
		if typeof(instance) != TYPE_ARRAY: continue
		var card_id = instance[0]
		var card = CardFactory.get_card(card_id)
		
		if card != null and card.color != CardColor.Type.PURPLE:
			var btn = Button.new()
			btn.text = card.name
			btn.custom_minimum_size = Vector2(80, 110)
			btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			
			var style = StyleBoxFlat.new()
			match card.color:
				CardColor.Type.BLUE: style.bg_color = Color(0.2, 0.4, 0.8)
				CardColor.Type.GREEN: style.bg_color = Color(0.2, 0.6, 0.2)
				CardColor.Type.RED: style.bg_color = Color(0.8, 0.2, 0.2)
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", style)
			btn.add_theme_color_override("font_color", Color.WHITE)
			
			btn.pressed.connect(func():
				give_card_id = card_id
				_check_give_valid()
				for child in give_my_cards.get_children():
					child.modulate = Color(1.0, 1.0, 1.0) if child == btn else Color(0.4, 0.4, 0.4)
			)
			give_my_cards.add_child(btn)

	for p in all_players:
		if p != owner:
			var btn = Button.new()
			btn.text = p.username
			btn.custom_minimum_size = Vector2(120, 40)
			
			btn.pressed.connect(func():
				give_target = p
				_check_give_valid()
				for child in give_opponents.get_children():
					child.modulate = Color(1.0, 1.0, 1.0) if child == btn else Color(0.4, 0.4, 0.4)
			)
			give_opponents.add_child(btn)

	var result = await give_card_completed
	give_panel.hide()
	return result

func _check_give_valid() -> void:
	if give_target != null and give_card_id != -1:
		btn_confirm_give.disabled = false
		btn_confirm_give.text = tr("Confirmer le don !")

func _on_confirm_give_pressed() -> void:
	give_card_completed.emit([give_card_id, give_target])

func ask_demolish_monument(owner: Player) -> int:
	demolish_panel.show()
	btn_confirm_demolish.disabled = true
	btn_confirm_demolish.text = tr("Sélectionner un monument...")
	demolish_monu_id = -1
	
	for c in demolish_monuments.get_children(): c.queue_free()
	
	var has_built_monuments = false
	
	for monu_id in owner.monumentArray:
		if owner.monumentArray[monu_id] == true:
			has_built_monuments = true
			
			var btn = Button.new()
			var monu_data = game.getMonumentData(monu_id)
			btn.text = monu_data["name"]
			btn.custom_minimum_size = Vector2(120, 80)
			
			var style_normal = StyleBoxFlat.new()
			style_normal.bg_color = Color(0.8, 0.2, 0.2)
			var style_hover = StyleBoxFlat.new()
			style_hover.bg_color = Color(0.8, 0.2, 0.2).lightened(0.2)
			btn.add_theme_stylebox_override("normal", style_normal)
			btn.add_theme_stylebox_override("hover", style_hover)
			
			btn.pressed.connect(func():
				demolish_monu_id = monu_id
				btn_confirm_demolish.disabled = false
				btn_confirm_demolish.text = tr("Confirmer la démolition !")
				
				for child in demolish_monuments.get_children():
					child.modulate = Color(1.0, 1.0, 1.0) if child == btn else Color(0.4, 0.4, 0.4)
			)
			demolish_monuments.add_child(btn)
			
	if not has_built_monuments:
		print("No monuments built to demolish! Skipping effect.")
		demolish_panel.hide()
		return -1

	var result = await demolish_completed
	demolish_panel.hide()
	return result

func _on_confirm_demolish_pressed() -> void:
	demolish_completed.emit(demolish_monu_id)





func _on_shop_card_clicked(card_id: int) -> void:
	selected_shop_card_id = card_id
	var card_data = CardFactory.get_card(card_id)
	
	for child in %CardPreview.get_children():
		child.queue_free()
	
	if card_data != null:
		const CARD_SCENE = preload("res://scene/table/card_Y_axis.tscn")
		var preview_card = CARD_SCENE.instantiate()
		
		var card_name = card_data.get_name()
		var card_color = card_data.get_color()
		var clean_name = get_clean_file_name(card_name, card_color)
		
		var path_basis = "res://assets/Cards/Basis/" + clean_name + "_1.png"
		var image_node = preview_card.get_node_or_null("Visual")
		
		if image_node and image_node is TextureButton:
			if FileAccess.file_exists(path_basis):
				image_node.texture_normal = load(path_basis)
			
			image_node.disabled = true
			image_node.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var tooltip_node = preview_card.get_node_or_null("Visual/Tooltip")
		if tooltip_node:
			tooltip_node.hide()

		%CardPreview.add_child(preview_card)
		
		buy_confirm_panel.show()

func _on_confirm_buy_shop_pressed() -> void:
	buy_confirm_panel.hide()
	action_selected.emit([Game.CHOICE.Build_ESTABLISHMENT, selected_shop_card_id])

func _on_cancel_buy_shop_pressed() -> void:
	selected_shop_card_id = -1
	buy_confirm_panel.hide()




func ask_chalutier_roll() -> int:
	chalutier_panel.show()
	chalutier_roll.disabled = false
	lbl_chalutier_result.text = tr("Lancer pour voir combien d'or vous pêchez.")
	
	await chalutier_roll_pressed
	
	var d1 = (randi() % 6) + 1
	var d2 = (randi() % 6) + 1
	var total = d1 + d2
	
	lbl_chalutier_result.text = tr("Vous avez pêché %d Or !") % total
	chalutier_roll.disabled = true
	
	await get_tree().create_timer(2.0).timeout
	
	chalutier_panel.hide()
	return total




func show_victory_screen(winner_name: String) -> void:
	set_actions_enabled(false)
	set_dice_buttons_enabled(false)
	
	lbl_winner_name.text = tr("🏆 %s GAGNE ! 🏆\n5 Monuments construits !") % winner_name
	victory_screen.show()
	
func _on_quit_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/Prototype/V3/MainMenu.tscn")


func print_player_stats() -> void:
	lbl_active_gold.text = tr("Or actif: %d") % current_player.balance
	lbl_active_stats.text = tr("Éta: %d\nMonu actif: %d") % [current_player.establishmentCount, current_player.monumentCount]
	
	print("--- PLAYER STATS ---")
	print("Current Player: ", current_player.username)
	print("Gold: ", current_player.balance)
	print("Establishments: ", current_player.establishmentCount)
	print("Monuments: ", current_player.monumentCount)
	print("Deck Array: ", current_player.deck)
	print("--------------------")
