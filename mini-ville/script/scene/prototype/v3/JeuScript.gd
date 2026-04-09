extends Node
class_name Jeu

# --- SIGNAUX ---
signal action_selected(choide_data:Array)
signal dice_amount_chosen(amount: int)
signal yes_no_answered(result: bool)
signal player_chosen(target)
signal trade_completed(trade_data: Array)
signal give_card_completed(give_data: Array)
signal demolish_completed(monu_id: int)
signal chalutier_roll_pressed()

var current_player
var test_shop
var game

@onready var shop_container: GridContainer = %ShopContainer
@onready var middle_area: HBoxContainer = $MiddleArea
@onready var lbl_dice: Label = %LblDice

# --- GESTION DES JOUEURS ---
@onready var table_pivot: Control = $TablePivot
@onready var boards: Array = [
	$TablePivot/BoardJoueurBas,
	$TablePivot/BoardJoueurGauche,
	$TablePivot/BoardJoueurHaut,
	$TablePivot/BoardJoueurDroite
]

var player_angles: Array = [0.0, 0.0, 0.0, 0.0]
var active_boards: Array = []

# --- SECURITE D'ANIMATION ---
var currently_displayed_player = null
var is_game_initialized: bool = false
var is_rotating: bool = false
signal rotation_finished

# Overlays et Menus
@onready var turn_overlay: ColorRect = $TurnOverlay
@onready var lbl_turn_announcement: Label = $TurnOverlay/VBoxContainer/LblTurnAnnouncement
@onready var btn_overlay_roll_1: TextureButton = $TurnOverlay/VBoxContainer/HBoxContainer/BtnOverlayRoll1
@onready var btn_overlay_roll_2: TextureButton = $TurnOverlay/VBoxContainer/HBoxContainer/BtnOverlayRoll2

var result_overlay: ColorRect
var die_1: TextureRect
var die_2: TextureRect
var btn_conserver: TextureButton
var mini_dice_array: Array = []

var dice_textures = [
	preload("res://assets/UI/die_one.png"), preload("res://assets/UI/die_two.png"),
	preload("res://assets/UI/die_three.png"), preload("res://assets/UI/die_four.png"),
	preload("res://assets/UI/die_five.png"), preload("res://assets/UI/die_six.png")
]

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
@onready var buy_confirm_panel: ColorRect = %ConfirmCardBuyPanel
@onready var card_preview: Control = %CardPreview
@onready var confirm_card_buy: Button = %ConfirmCardBuy
@onready var cancel_card_buy: Button = %CancelCardBuy
@onready var chalutier_panel: ColorRect = %ChalutierPanel
@onready var lbl_chalutier_result: Label = %LblChalutierResult
@onready var chalutier_roll: Button = %ChalutierRoll

var trade_target = null
var trade_their_card_id: int = -1
var trade_my_card_id: int = -1
var give_target = null
var give_card_id: int = -1
var demolish_monu_id: int = -1
var selected_monument_id: int = -1
var selected_shop_card_id: int = -1

func _ready() -> void:
	if btn_overlay_roll_1: btn_overlay_roll_1.pressed.connect(_on_roll_1_pressed)
	if btn_overlay_roll_2: btn_overlay_roll_2.pressed.connect(_on_roll_2_pressed)
	
	if turn_overlay: turn_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		
	_find_dice_ui_nodes()
	_force_overlays_to_front()
	
	get_viewport().size_changed.connect(_on_window_resized)
	_on_window_resized() 
	
	for board in boards:
		if is_instance_valid(board):
			board.pass_turn_requested.connect(_on_skip_pressed)
			board.open_monuments_requested.connect(_on_open_monuments_pressed)
	
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
	
	var chal_btn = get_node_or_null("%ChalutierRoll")
	if chal_btn: chal_btn.pressed.connect(func(): chalutier_roll_pressed.emit())
	
	var monuments_to_setup = {
		$MonumentMenu/BuildGare: Monument.MONUMENT_ID.Gare,
		$MonumentMenu/BuildCentreCommercial: Monument.MONUMENT_ID.Centre_Commercial,
		$MonumentMenu/BuildParcAttraction: Monument.MONUMENT_ID.Parc,
		$MonumentMenu/BuildRadio: Monument.MONUMENT_ID.Radio,
		$MonumentMenu/BuildAeroport: Monument.MONUMENT_ID.Aeroport,
		$MonumentMenu/BuildPort: Monument.MONUMENT_ID.Port
	}
	for btn in monuments_to_setup: setup_monument_button(btn, monuments_to_setup[btn])

func _on_window_resized() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	
	if table_pivot:
		table_pivot.set_anchors_preset(Control.PRESET_FULL_RECT)
		table_pivot.size = screen_size
		table_pivot.pivot_offset = screen_size / 2.0
		table_pivot.position = Vector2.ZERO
	
	if middle_area:
		middle_area.set_anchors_preset(Control.PRESET_CENTER)
		# On s'assure que les boutons Gold sont collés au shop via la séparation de l'HBoxContainer
		middle_area.add_theme_constant_override("separation", 20)
		middle_area.position = (screen_size / 2.0) - (middle_area.size / 2.0)
	
	var overlays = [turn_overlay, result_overlay, monument_menu, victory_screen, yes_no_panel, 
					choose_player_panel, trade_panel, give_panel, demolish_panel, buy_confirm_panel, chalutier_panel]
	for ov in overlays:
		if is_instance_valid(ov):
			ov.size = screen_size
			ov.position = Vector2.ZERO
			
	if is_game_initialized:
		positionner_plateaux(false) 

func _force_overlays_to_front() -> void:
	var overlays = [turn_overlay, result_overlay, monument_menu, victory_screen, yes_no_panel, choose_player_panel, trade_panel, give_panel, demolish_panel, buy_confirm_panel, chalutier_panel]
	for overlay in overlays:
		if is_instance_valid(overlay): overlay.z_index = 100 

func RefreshBasicInfo(current_game) -> void:
	self.game = current_game
	self.current_player = game.getActivePlayer()
	self.test_shop = game.shop
	
	var player_changed = (currently_displayed_player != current_player)
	currently_displayed_player = current_player
	
	active_boards.clear()
	if game.playerCount == 2:
		active_boards.append(boards[0])
		active_boards.append(boards[2])
	elif game.playerCount == 3:
		active_boards.append(boards[0])
		active_boards.append(boards[1])
		active_boards.append(boards[2])
	else:
		active_boards = boards.duplicate()
	
	update_shop_ui()
	update_all_boards()
	updateMonumentColors()
	
	if not is_game_initialized:
		positionner_plateaux(false) 
		is_game_initialized = true
	elif player_changed and game.playerCount > 0:
		positionner_plateaux(true)  
		
	set_actions_enabled(false) 

func positionner_plateaux(animate: bool = true) -> void:
	if not game or game.playerCount == 0: return
	var active_idx = game.playerArray.find(current_player)
	if active_idx == -1: active_idx = 0

	var screen_size = get_viewport().get_visible_rect().size
	var c = screen_size / 2.0
	var b_w = 750
	var b_h = 260 
	var margin = 35 

	var rx = (screen_size.x / 2.0) - (b_h / 2.0) - margin
	var ry = (screen_size.y / 2.0) - (b_h / 2.0) - margin

	var tween = null
	if animate:
		is_rotating = true
		set_actions_enabled(false)
		tween = get_tree().create_tween().set_parallel(true)
		tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	for p_idx in range(game.playerCount):
		var board = boards[p_idx]
		if not is_instance_valid(board): continue
		board.set_anchors_preset(Control.PRESET_TOP_LEFT, true)
		board.custom_minimum_size = Vector2(b_w, b_h)
		board.size = Vector2(b_w, b_h)
		board.pivot_offset = Vector2(b_w / 2.0, b_h / 2.0)

		var diff = (p_idx - active_idx)
		if diff < 0: diff += game.playerCount
		var target_angle = 0.0 
		var target_rot = 0.0   

		if game.playerCount == 2:
			if diff == 0: target_angle = PI/2.0; target_rot = 0.0
			elif diff == 1: target_angle = -PI/2.0; target_rot = PI
		elif game.playerCount == 3:
			if diff == 0: target_angle = PI/2.0; target_rot = 0.0
			elif diff == 1: target_angle = PI; target_rot = PI/2.0
			elif diff == 2: target_angle = -PI/2.0; target_rot = PI
		else:
			if diff == 0: target_angle = PI/2.0; target_rot = 0.0
			elif diff == 1: target_angle = PI; target_rot = PI/2.0
			elif diff == 2: target_angle = -PI/2.0; target_rot = PI
			elif diff == 3: target_angle = 0.0; target_rot = -PI/2.0

		if animate:
			var start_angle = player_angles[p_idx]
			var current_rot = board.rotation
			var rot_diff = fmod((target_rot - current_rot + PI), 2*PI) - PI
			var final_rot = current_rot + rot_diff
			var ang_diff = fmod((target_angle - start_angle + PI), 2*PI) - PI
			var final_ang = start_angle + ang_diff

			var move_circular = func(t: float, b: Control, s_ang: float, t_ang: float):
				var current_ang = lerp(s_ang, t_ang, t)
				var target_center = c + Vector2(cos(current_ang)*rx, sin(current_ang)*ry)
				b.position = target_center - b.pivot_offset
			
			tween.tween_method(move_circular.bind(board, start_angle, final_ang), 0.0, 1.0, 1.2)
			tween.tween_property(board, "rotation", final_rot, 1.2)
			player_angles[p_idx] = final_ang
		else:
			var target_center = c + Vector2(cos(target_angle)*rx, sin(target_angle)*ry)
			board.position = target_center - board.pivot_offset
			board.rotation = target_rot
			player_angles[p_idx] = target_angle

	if animate:
		await tween.finished
		await get_tree().create_timer(0.2).timeout
		is_rotating = false
		rotation_finished.emit()

func update_all_boards() -> void:
	for b in boards: b.hide()
	for i in range(game.playerCount):
		var board = active_boards[i]
		board.show()
		var p = game.playerArray[i]
		board.setup(p, p == current_player)

func waitForDiceRoll() -> int:
	if is_rotating:
		var timer = get_tree().create_timer(1.5)
		var finished = false
		rotation_finished.connect(func(): finished = true)
		while is_rotating and not finished and timer.time_left > 0:
			await get_tree().process_frame
		is_rotating = false 

	for d in mini_dice_array:
		if is_instance_valid(d): d.queue_free()
	mini_dice_array.clear()
	
	var has_gare = current_player.monumentIsActive(Monument.MONUMENT_ID.Gare)
	var nom = current_player.username
	var prefix = "Tour de "
	if ["A","E","I","O","U","Y"].has(nom[0].to_upper()): prefix = "Tour d' "
	
	lbl_turn_announcement.text = prefix + nom
	btn_overlay_roll_2.disabled = not has_gare
	btn_overlay_roll_2.visible = has_gare 
	
	turn_overlay.move_to_front()
	turn_overlay.show()
	set_actions_enabled(false) # Désactive le bouton pendant le choix du dé
	
	var amount = await dice_amount_chosen
	turn_overlay.hide()
	return amount

func _find_dice_ui_nodes() -> void:
	result_overlay = find_child("ResultOverlay", true, false)
	die_1 = find_child("Die1", true, false)
	die_2 = find_child("Die2", true, false)
	btn_conserver = find_child("BtnConserver", true, false)

func showResult(d1: int, d2: int) -> void:
	var amount = 1 if d2 == 0 else 2
	await play_dice_animation(amount, d1, d2)
	# RÉAPPARITION DU BOUTON ICI
	set_actions_enabled(true)

func play_dice_animation(amount: int, final_d1: int, final_d2: int = 0) -> void:
	if die_1 == null or result_overlay == null: return
	
	result_overlay.move_to_front()
	result_overlay.show()
	if btn_conserver: btn_conserver.hide() 
	die_1.show()
	if die_2: die_2.visible = (amount == 2)
	
	var frames = 15
	var delay = 0.05 
	for i in range(frames):
		die_1.texture = dice_textures[randi() % 6]
		if amount == 2 and die_2: die_2.texture = dice_textures[randi() % 6]
		await get_tree().create_timer(delay).timeout
		if i > frames - 4: delay += 0.05 
		
	die_1.texture = dice_textures[final_d1 - 1]
	if amount == 2 and die_2: die_2.texture = dice_textures[final_d2 - 1]
	
	if btn_conserver:
		btn_conserver.show()
		await btn_conserver.pressed
		
	var start_pos_1 = die_1.global_position
	var start_size_1 = die_1.size
	
	result_overlay.hide()
	var dummy_1 = TextureRect.new()
	dummy_1.texture = die_1.texture
	dummy_1.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dummy_1.size = start_size_1
	dummy_1.global_position = start_pos_1
	dummy_1.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	add_child(dummy_1)
	mini_dice_array.append(dummy_1)
	
	var dummy_2 = null
	if amount == 2 and die_2:
		dummy_2 = TextureRect.new()
		dummy_2.texture = die_2.texture
		dummy_2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		dummy_2.size = die_2.size
		dummy_2.global_position = die_2.global_position
		dummy_2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dummy_2)
		mini_dice_array.append(dummy_2)
		
	var active_idx = game.playerArray.find(current_player)
	if active_idx == -1: active_idx = 0
	var target_board = active_boards[active_idx]
	
	# PLACEMENT MIEUX ÉTUDIÉ : au dessus de la zone de cartes du joueur
	var target_pos = target_board.global_position + Vector2(250, 20)
	if is_instance_valid(target_board.btn_pass) and target_board.btn_pass.is_inside_tree():
		target_pos = target_board.btn_pass.global_position + Vector2(-80, -20)
		
	var anim_duration = 0.6 
	var target_scale = Vector2(0.4, 0.4) 
	
	var tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property(dummy_1, "global_position", target_pos, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(dummy_1, "scale", target_scale, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	if dummy_2:
		var target_pos_2 = target_pos + Vector2(50, 0)
		tween.tween_property(dummy_2, "global_position", target_pos_2, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(dummy_2, "scale", target_scale, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	await tween.finished

func ask_yes_no(question: String) -> bool:
	lbl_question.text = question
	yes_no_panel.move_to_front()
	yes_no_panel.show()
	var result = await yes_no_answered
	yes_no_panel.hide()
	return result

func _on_yes_pressed() -> void: yes_no_answered.emit(true)
func _on_no_pressed() -> void: yes_no_answered.emit(false)

func pause() -> Array:
	update_all_boards()
	set_actions_enabled(true)
	var choice = await action_selected
	set_actions_enabled(false)
	return choice

func set_actions_enabled(can_act: bool) -> void:
	for board in boards:
		if is_instance_valid(board): board.set_actions_enabled(can_act)
	for card_visual in shop_container.get_children():
		var button = card_visual.get_node_or_null("Visual")
		if button and button is TextureButton: button.disabled = !can_act	

func _on_roll_1_pressed() -> void: dice_amount_chosen.emit(1)
func _on_roll_2_pressed() -> void: dice_amount_chosen.emit(2)

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
	monument_info.text = "Select a monument to view details."
	monument_menu.move_to_front()
	monument_menu.show()

func _on_close_menu_pressed() -> void: monument_menu.hide()

func _on_monument_selected(monu_id: int) -> void:
	selected_monument_id = monu_id
	confirm_buy.disabled = false
	var data = game.getMonumentData(monu_id)
	monument_info.text = data["name"] + "\nCost: " + str(data["cost"]) + " Gold"

func _on_confirm_buy_pressed() -> void:
	monument_menu.hide()
	if game and game.CHOICE: action_selected.emit([game.CHOICE.Build_MONUMENT, selected_monument_id])

func _on_skip_pressed() -> void:
	if game and game.CHOICE: action_selected.emit([game.CHOICE.SKIP, 0])

func update_shop_ui() -> void:
	for child in shop_container.get_children(): child.queue_free()
	const CARD_SCENE = preload("res://scene/table/card_Y_axis.tscn")
	
	for slot in test_shop.shop:
		var card_visual
		var card_data = CardFactory.get_card(slot.id)
		if card_data != null:
			var card_name = card_data.get_name()
			var card_color = card_data.get_color()
			var clean_name = get_clean_file_name(card_name, card_color)
			var path_basis = "res://assets/Cards/Basis/" + clean_name + "_1.png"
			var path_hover = "res://assets/Cards/Hover/" + clean_name + "_2.png"
			
			if FileAccess.file_exists(path_basis):
				card_visual = CARD_SCENE.instantiate()
				var image_node = card_visual.get_node_or_null("Visual")
				if image_node is TextureButton:
					image_node.texture_normal = load(path_basis)
					if FileAccess.file_exists(path_hover): image_node.texture_hover = load(path_hover)
					image_node.pressed.connect(_on_shop_card_clicked.bind(slot.id))
				card_visual.scale = Vector2(0.5, 0.5) 
				card_visual.custom_minimum_size = Vector2(180, 224) * 0.5
				
				var tooltip_node = card_visual.get_node_or_null("Visual/Tooltip")
				if tooltip_node:
					var tip_path = "res://assets/Tooltips/tooltip_" + clean_name + "_top.png"
					if FileAccess.file_exists(tip_path): tooltip_node.texture = load(tip_path)
					tooltip_node.hide()
					tooltip_node.rotation_degrees = 0
			else:
				card_visual = Button.new()
				card_visual.text = str(card_data.get_activation_num()) + "\n" + card_name
				card_visual.custom_minimum_size = Vector2(90, 112)
				card_visual.pressed.connect(_on_shop_card_clicked.bind(slot.id))
				var style = StyleBoxFlat.new()
				match card_color:
					CardColor.Type.BLUE: style.bg_color = Color(0.2, 0.4, 0.8)
					CardColor.Type.GREEN: style.bg_color = Color(0.2, 0.6, 0.2)
					CardColor.Type.RED: style.bg_color = Color(0.8, 0.2, 0.2)
					CardColor.Type.PURPLE: style.bg_color = Color(0.6, 0.2, 0.8)
				card_visual.add_theme_stylebox_override("normal", style)
		shop_container.add_child(card_visual)

func get_clean_file_name(card_name: String, color: int) -> String:
	var prefix = ""
	match color:
		CardColor.Type.BLUE: prefix = "bleu_"
		CardColor.Type.GREEN: prefix = "vert_"
		CardColor.Type.RED: prefix = "rouge_"
		CardColor.Type.PURPLE: prefix = "violet_"
	var clean_name = card_name.to_lower().replace(" ", "_").replace("'", "_")
	clean_name = clean_name.replace("é", "e").replace("è", "e").replace("à", "a")
	return prefix + clean_name

func updateMonumentColors() -> void:
	var monuments_to_check = {
		$MonumentMenu/BuildGare: Monument.MONUMENT_ID.Gare,
		$MonumentMenu/BuildCentreCommercial: Monument.MONUMENT_ID.Centre_Commercial,
		$MonumentMenu/BuildParcAttraction: Monument.MONUMENT_ID.Parc,
		$MonumentMenu/BuildRadio: Monument.MONUMENT_ID.Radio,
		$MonumentMenu/BuildAeroport: Monument.MONUMENT_ID.Aeroport,
		$MonumentMenu/BuildPort: Monument.MONUMENT_ID.Port
	}
	for btn in monuments_to_check: check_and_color_monument(btn, monuments_to_check[btn])

func check_and_color_monument(btn: Button, monu_id: int) -> void:
	var style = StyleBoxFlat.new()
	if current_player.monumentIsActive(monu_id): style.bg_color = Color(0.1, 0.6, 0.1)
	else: style.bg_color = Color(0.6, 0.1, 0.1)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)

func ask_choose_player(owner_player, all_players: Array):
	choose_player_panel.move_to_front()
	choose_player_panel.show()
	for child in player_buttons_container.get_children(): child.queue_free()
	for p in all_players:
		if p != owner_player:
			var btn = Button.new()
			btn.text = p.username + " (" + str(p.balance) + " Gold)"
			btn.custom_minimum_size = Vector2(200, 60)
			btn.pressed.connect(func(): _on_player_chosen(p))
			player_buttons_container.add_child(btn)
	var chosen_target = await player_chosen
	choose_player_panel.hide()
	return chosen_target

func _on_player_chosen(target) -> void: player_chosen.emit(target)

func ask_trade_cards(owner_player, all_players: Array) -> Array:
	trade_panel.move_to_front()
	trade_panel.show()
	btn_confirm_trade.disabled = true
	btn_confirm_trade.text = "Select cards to trade..."
	trade_target = null; trade_their_card_id = -1; trade_my_card_id = -1
	for c in trade_opponents.get_children(): c.queue_free()
	for p in all_players:
		if p != owner_player:
			var btn = Button.new()
			btn.text = p.username
			btn.custom_minimum_size = Vector2(120, 40)
			btn.pressed.connect(func(): _on_trade_opponent_selected(p))
			trade_opponents.add_child(btn)
	_populate_trade_deck(owner_player, trade_my_cards, true)
	var result = await trade_completed
	trade_panel.hide()
	return result

func _on_trade_opponent_selected(target) -> void:
	trade_target = target
	for c in trade_their_cards.get_children(): c.queue_free()
	_populate_trade_deck(target, trade_their_cards, false)
	_check_trade_valid()

func _populate_trade_deck(player, container: Container, is_mine: bool) -> void:
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
					child.modulate = Color(1.0, 1.0, 1.0) if child == btn else Color(0.4, 0.4, 0.4)
			)
			container.add_child(btn)

func _check_trade_valid() -> void:
	if trade_target != null and trade_their_card_id != -1 and trade_my_card_id != -1:
		btn_confirm_trade.disabled = false
		btn_confirm_trade.text = "Confirm Trade!"

func _on_confirm_trade_pressed() -> void: trade_completed.emit([trade_my_card_id, trade_target, trade_their_card_id])

func ask_give_card(owner_player, all_players: Array) -> Array:
	give_panel.move_to_front()
	give_panel.show()
	btn_confirm_give.disabled = true
	btn_confirm_give.text = "Select a card and an opponent..."
	give_target = null; give_card_id = -1
	for c in give_my_cards.get_children(): c.queue_free()
	for instance in owner_player.deck:
		if typeof(instance) != TYPE_ARRAY: continue
		var card_id = instance[0]
		var card = CardFactory.get_card(card_id)
		if card != null and card.color != CardColor.Type.PURPLE:
			var btn = Button.new()
			btn.text = card.name
			btn.custom_minimum_size = Vector2(80, 110)
			var style = StyleBoxFlat.new()
			match card.color:
				CardColor.Type.BLUE: style.bg_color = Color(0.2, 0.4, 0.8)
				CardColor.Type.GREEN: style.bg_color = Color(0.2, 0.6, 0.2)
				CardColor.Type.RED: style.bg_color = Color(0.8, 0.2, 0.2)
			btn.add_theme_stylebox_override("normal", style)
			btn.pressed.connect(func():
				give_card_id = card_id
				_check_give_valid()
				for child in give_my_cards.get_children(): child.modulate = Color(1.0, 1.0, 1.0) if child == btn else Color(0.4, 0.4, 0.4)
			)
			give_my_cards.add_child(btn)
	for p in all_players:
		if p != owner_player:
			var btn = Button.new()
			btn.text = p.username
			btn.custom_minimum_size = Vector2(120, 40)
			btn.pressed.connect(func():
				give_target = p
				_check_give_valid()
				for child in give_opponents.get_children(): child.modulate = Color(1.0, 1.0, 1.0) if child == btn else Color(0.4, 0.4, 0.4)
			)
			give_opponents.add_child(btn)
	var result = await give_card_completed
	give_panel.hide()
	return result

func _check_give_valid() -> void:
	if give_target != null and give_card_id != -1:
		btn_confirm_give.disabled = false
		btn_confirm_give.text = "Confirm Gift!"

func _on_confirm_give_pressed() -> void: give_card_completed.emit([give_card_id, give_target])

func ask_demolish_monument(owner_player) -> int:
	demolish_panel.move_to_front()
	demolish_panel.show()
	btn_confirm_demolish.disabled = true
	demolish_monu_id = -1
	for c in demolish_monuments.get_children(): c.queue_free()
	var has_built_monuments = false
	for monu_id in owner_player.monumentArray:
		if owner_player.monumentArray[monu_id] == true:
			has_built_monuments = true
			var btn = Button.new()
			var monu_data = game.getMonumentData(monu_id)
			btn.text = monu_data["name"]
			btn.custom_minimum_size = Vector2(120, 80)
			var style_normal = StyleBoxFlat.new()
			style_normal.bg_color = Color(0.8, 0.2, 0.2)
			btn.add_theme_stylebox_override("normal", style_normal)
			btn.pressed.connect(func():
				demolish_monu_id = monu_id
				btn_confirm_demolish.disabled = false
				btn_confirm_demolish.text = "Demolish " + monu_data["name"] + "!"
				for child in demolish_monuments.get_children(): child.modulate = Color(1.0, 1.0, 1.0) if child == btn else Color(0.4, 0.4, 0.4)
			)
			demolish_monuments.add_child(btn)
	if not has_built_monuments: return -1
	var result = await demolish_completed
	demolish_panel.hide()
	return result

func _on_confirm_demolish_pressed() -> void: demolish_completed.emit(demolish_monu_id)

func _on_shop_card_clicked(card_id: int) -> void:
	selected_shop_card_id = card_id
	var card_data = CardFactory.get_card(card_id)
	for child in %CardPreview.get_children(): child.queue_free()
	if card_data != null:
		const CARD_SCENE = preload("res://scene/table/card_Y_axis.tscn")
		var preview_card = CARD_SCENE.instantiate()
		var card_name = card_data.get_name()
		var card_color = card_data.get_color()
		var clean_name = get_clean_file_name(card_name, card_color)
		var path_basis = "res://assets/Cards/Basis/" + clean_name + "_1.png"
		var image_node = preview_card.get_node_or_null("Visual")
		if image_node and image_node is TextureButton:
			if FileAccess.file_exists(path_basis): image_node.texture_normal = load(path_basis)
			image_node.disabled = true
			image_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tooltip_node = preview_card.get_node_or_null("Visual/Tooltip")
		if tooltip_node: tooltip_node.hide()
		%CardPreview.add_child(preview_card)
		buy_confirm_panel.move_to_front()
		buy_confirm_panel.show()

func _on_confirm_buy_shop_pressed() -> void:
	buy_confirm_panel.hide()
	if game and game.CHOICE: action_selected.emit([game.CHOICE.Build_ESTABLISHMENT, selected_shop_card_id])

func _on_cancel_buy_shop_pressed() -> void:
	selected_shop_card_id = -1
	buy_confirm_panel.hide()

func ask_chalutier_roll() -> int:
	chalutier_panel.move_to_front()
	chalutier_panel.show()
	chalutier_roll.disabled = false
	lbl_chalutier_result.text = "Roll to see how much gold you catch."
	await chalutier_roll_pressed
	var d1 = (randi() % 6) + 1
	var d2 = (randi() % 6) + 1
	var total = d1 + d2
	lbl_chalutier_result.text = "You caught " + str(total) + " Gold!"
	chalutier_roll.disabled = true
	await get_tree().create_timer(2.0).timeout
	chalutier_panel.hide()
	return total

func show_victory_screen(winner_name: String) -> void:
	set_actions_enabled(false)
	lbl_winner_name.text = "🏆 " + winner_name + " WINS!\nAll 5 Monuments Built!"
	victory_screen.move_to_front()
	victory_screen.show()
	
func _on_quit_pressed() -> void: get_tree().change_scene_to_file("res://scene/Prototype/V3/MainMenu.tscn")
