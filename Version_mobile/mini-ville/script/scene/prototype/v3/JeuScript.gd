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
signal dice_decision_made(action: String)

var current_player
var test_shop
var game

@onready var middle_area: HBoxContainer = get_node_or_null("CenterBoard")

# --- GESTION DES JOUEURS ---
@onready var table_pivot: Control = $TablePivot
@onready var boards: Array = [
	$TablePivot/BoardJoueurBas,
	$TablePivot/BoardJoueurGauche,
	$TablePivot/BoardJoueurHaut,
	$TablePivot/BoardJoueurDroite
]

# --- GESTION DU SHOP ---
@onready var shop_popup: CanvasLayer = %ShopPopup
@onready var shop_button: TextureButton = %ShopButton

# --- CAMERA ET ANIMATIONS ---
@onready var camera: Camera2D = get_node_or_null("Camera2D")
const CARD_ANIMATION_SCENE = preload("res://scene/table/card_animation.tscn")

var player_angles: Array = [0.0, 0.0, 0.0, 0.0]
var active_boards: Array = []

# --- SECURITE D'ANIMATION ---
var currently_displayed_player = null
var is_game_initialized: bool = false
var is_rotating: bool = false
var pending_shop_animation_index: int = -1
signal rotation_finished
@onready var click_blocker: ColorRect = get_node_or_null("ClickBlocker") 

# Overlays et Menus
@onready var turn_overlay: ColorRect = $TurnOverlay
@onready var lbl_turn_announcement: Label = %LblTurnAnnouncement

@onready var btn_overlay_roll_1: Button = $TurnOverlay/VBoxContainer/HBoxContainer/Roll1Die
@onready var btn_overlay_roll_2: Button = $TurnOverlay/VBoxContainer/HBoxContainer/Roll2Dices

var result_overlay: ColorRect
var die_1: TextureRect
var die_2: TextureRect
var btn_conserver: Button
var btn_relancer: Button
var btn_add_2: Button
var mini_dice_array: Array = []

var dice_textures = [
	preload("res://assets/UI/die_one.png"), preload("res://assets/UI/die_two.png"),
	preload("res://assets/UI/die_three.png"), preload("res://assets/UI/die_four.png"),
	preload("res://assets/UI/die_five.png"), preload("res://assets/UI/die_six.png")
]

@onready var monument_menu: ColorRect = %MonumentOverlay
@onready var close_menu: Button = %CloseButton 
@onready var cards_monuments_container = $MonumentOverlay/MainContainer/CardsMonumentsContainer
@onready var victory_screen: PanelContainer = $VictoryScreen
@onready var lbl_winner_name: Label = %LblWinnerName
@onready var btn_quit: Button = %ReturnToMenu 
@onready var yes_no_panel: ColorRect = %YesNoPanel
@onready var lbl_question: Label = %LblQuestion
@onready var btn_yes: Button = %BtnYes
@onready var btn_no: Button = %BtnNo
@onready var choose_player_panel: PanelContainer = $ChoosePlayerPanel
@onready var player_buttons_container: HBoxContainer = %PlayerButtonsContainer
@onready var trade_panel: PanelContainer = $TradePanel
@onready var trade_opponents: HBoxContainer = %TradeOpponents
@onready var trade_their_cards: HFlowContainer = %TradeTheirCards
@onready var trade_my_cards: HFlowContainer = %TradeMyCards
@onready var btn_confirm_trade: Button = %ConfirmTrade
@onready var give_panel: PanelContainer = $GiveCardPanel
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
@onready var add_gold: Button = %AddGold
@onready var remove_gold: Button = %RemoveGold
@onready var settings_button: TextureButton = %Settings
@onready var settings_overlay: PanelContainer = %SettingsOverlay
@onready var continue_button: Button = %Continuer
@onready var main_menu_button: Button = %MenuPrincipale
@onready var settings_quit_button: Button = %Quitter

var trade_target = null
var trade_their_card_id: int = -1
var trade_my_card_id: int = -1
var give_target = null
var give_card_id: int = -1
var demolish_monu_id: int = -1
var selected_shop_card_id: int = -1

var forced_dice_total: int = -1
var debug_dice_panel: Control = null

const MONUMENT_SLOT_SCENE = preload("res://scene/table/MonumentSlot.tscn")

func get_lang_folder() -> String:
	# Récupère la langue actuelle (ex: "fr", "en", "en_US")
	if TranslationServer.get_locale().begins_with("en"):
		return "English"
	return "French"

# ----------------------------------------------------------------
# UTILITAIRE DÉTECTION ÉCRAN
# Téléphone  : petit côté < 1400 ET ratio > 1.8  (ex: 1280x2856)
# Tablette   : petit côté >= 1400                (ex: 2560x1600)
# ----------------------------------------------------------------
func _is_phone() -> bool:
	var s = get_viewport().get_visible_rect().size
	var small_side = min(s.x, s.y)
	var large_side = max(s.x, s.y)
	return small_side < 1400 and (large_side / small_side) > 1.8

func _ready() -> void:
	shop_button.pressed.connect(_on_shop_button_pressed)
	shop_popup.shop_card_clicked.connect(_on_shop_card_clicked)
	if btn_overlay_roll_1: btn_overlay_roll_1.pressed.connect(_on_roll_1_pressed)
	if btn_overlay_roll_2: btn_overlay_roll_2.pressed.connect(_on_roll_2_pressed)
	# Traduction des boutons définis dans la scène
	if btn_overlay_roll_1: btn_overlay_roll_1.text = tr("LANCER_1_DE")
	if btn_overlay_roll_2: btn_overlay_roll_2.text = tr("LANCER_2_DES")
	if btn_conserver: btn_conserver.text = tr("Conserver le résultat")
	if btn_relancer: btn_relancer.text = tr("Refaire le lancer")
	if btn_add_2: btn_add_2.text = tr("Ajouter 2 au résultat")
	
	if turn_overlay: turn_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		
	_find_dice_ui_nodes()
	_force_overlays_to_front()
	
	get_viewport().size_changed.connect(_on_window_resized)
	_on_window_resized.call_deferred()
	
	for board in boards:
		if is_instance_valid(board):
			board.pass_turn_requested.connect(_on_skip_pressed)
			board.open_monuments_requested.connect(_on_open_monuments_pressed)
	
	close_menu.pressed.connect(_on_close_menu_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)
	btn_yes.pressed.connect(_on_yes_pressed)
	btn_no.pressed.connect(_on_no_pressed)
	%ConfirmTrade.pressed.connect(_on_confirm_trade_pressed)
	%ConfirmGive.pressed.connect(_on_confirm_give_pressed)
	%ConfirmDemolish.pressed.connect(_on_confirm_demolish_pressed)
	%ConfirmCardBuy.pressed.connect(_on_confirm_buy_shop_pressed)
	%CancelCardBuy.pressed.connect(_on_cancel_buy_shop_pressed)
	add_gold.pressed.connect(_on_add_gold_pressed.bind(5))
	remove_gold.pressed.connect(_on_add_gold_pressed.bind(-2))
	
	if btn_conserver: 
		btn_conserver.pressed.connect(func(): dice_decision_made.emit("keep"))
	if btn_relancer: 
		btn_relancer.pressed.connect(func(): dice_decision_made.emit("reroll"))
	if btn_add_2: 
		btn_add_2.pressed.connect(func(): dice_decision_made.emit("add2"))
		
	settings_button.pressed.connect(func(): _on_settings_pressed())
	continue_button.pressed.connect(func(): _on_continue_pressed())
	main_menu_button.pressed.connect(func(): _on_quit_pressed())
	settings_quit_button.pressed.connect(func(): get_tree().quit())
	
	var chal_btn = get_node_or_null("%ChalutierRoll")
	if chal_btn: chal_btn.pressed.connect(func(): chalutier_roll_pressed.emit())
	
	if continue_button: continue_button.text = tr("CONTINUER")
	if main_menu_button: main_menu_button.text = tr("MENU_PRINCIPAL")
	if settings_quit_button: settings_quit_button.text = tr("QUITTER")

func _setup_debug_dice_picker() -> void:
	if not turn_overlay:
		return

	# Wrapper holds toggle button + picker side by side, positioned at left edge
	var wrapper = HBoxContainer.new()
	wrapper.name = "DebugDiceWrapper"
	wrapper.add_theme_constant_override("separation", 6)
	turn_overlay.add_child(wrapper)

	# --- Toggle button ---
	var toggle_btn = Button.new()
	toggle_btn.text = "🎲"
	toggle_btn.tooltip_text = "Choisir valeur forcée"
	toggle_btn.custom_minimum_size = Vector2(64, 64)
	toggle_btn.flat = true
	toggle_btn.add_theme_font_size_override("font_size", 28)
	wrapper.add_child(toggle_btn)

	# --- Picker panel (hidden by default) ---
	var picker = VBoxContainer.new()
	picker.name = "DebugDicePicker"
	picker.hide()
	picker.add_theme_constant_override("separation", 8)
	wrapper.add_child(picker)
	debug_dice_panel = picker

	# Row 1: single die faces 1-6
	var row1 = HBoxContainer.new()
	row1.add_theme_constant_override("separation", 4)
	picker.add_child(row1)

	var die_names = ["die_one", "die_two", "die_three", "die_four", "die_five", "die_six"]
	for i in 6:
		var val = i + 1
		var btn = Button.new()
		btn.flat = true
		btn.custom_minimum_size = Vector2(52, 52)
		var tex = load("res://assets/UI/" + die_names[i] + ".png")
		if tex:
			btn.icon = tex
			btn.expand_icon = true
		else:
			btn.text = str(val)
		btn.tooltip_text = "Forcer " + str(val)
		btn.pressed.connect(func(v = val):
			forced_dice_total = v
			debug_dice_panel.hide()
			dice_amount_chosen.emit(1)
		)
		row1.add_child(btn)

	# Row 2: two-dice values 7-12
	var row2 = HBoxContainer.new()
	row2.add_theme_constant_override("separation", 4)
	picker.add_child(row2)

	var double_tex = load("res://assets/UI/2Dice.png")
	for i in 6:
		var val = i + 7
		var cell = VBoxContainer.new()
		cell.add_theme_constant_override("separation", 2)
		cell.custom_minimum_size = Vector2(52, 0)
		var btn = Button.new()
		btn.flat = true
		btn.custom_minimum_size = Vector2(52, 52)
		if double_tex:
			btn.icon = double_tex
			btn.expand_icon = true
		var lbl = Label.new()
		lbl.text = str(val)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.add_theme_font_size_override("font_size", 13)
		cell.add_child(btn)
		cell.add_child(lbl)
		btn.pressed.connect(func(v = val):
			forced_dice_total = v
			debug_dice_panel.hide()
			dice_amount_chosen.emit(2)
		)
		row2.add_child(cell)

	# Toggle visibility
	toggle_btn.pressed.connect(func():
		if debug_dice_panel:
			debug_dice_panel.visible = not debug_dice_panel.visible
	)

	# Reposition wrapper at the left edge, vertically centered.
	# Must run after layout is done (size unknown at _ready time), so we
	# hook into turn_overlay's resized signal and also fire once next frame.
	var reposition = func():
		if is_instance_valid(wrapper) and is_instance_valid(turn_overlay):
			wrapper.position = Vector2(10, (turn_overlay.size.y - wrapper.size.y) / 2.0)

	turn_overlay.resized.connect(reposition)
	# Also fire once after the first layout pass
	get_tree().process_frame.connect(reposition, CONNECT_ONE_SHOT)


	
func _on_settings_pressed() -> void:
	settings_overlay.move_to_front()
	settings_overlay.show()
	
func _on_continue_pressed() -> void:
	settings_overlay.hide()

func _on_add_gold_pressed(amount: int) -> void:
	if current_player != null:
		current_player.balance = max(0, current_player.balance + amount)
		
		var active_idx = game.playerArray.find(current_player)
		if active_idx != -1 and is_instance_valid(active_boards[active_idx]):
			animer_gain_gold(active_boards[active_idx], amount)
			
		update_all_boards()

func _on_window_resized() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	
	if table_pivot:
		table_pivot.set_anchors_preset(Control.PRESET_FULL_RECT)
		table_pivot.size = screen_size
		table_pivot.pivot_offset = screen_size / 2.0
		table_pivot.position = Vector2.ZERO
	
	var is_phone = _is_phone()
	
	# ----------------------------------------------------------------
	# REDIMENSIONNEMENT — FUSIONNÉ TÉLÉPHONE / TABLETTE
	# ----------------------------------------------------------------
	if is_phone:
		# TÉLÉPHONE : scale global proportionnel à la hauteur
		var ref_height = 600.0
		var global_scale = clamp(screen_size.y / ref_height, 0.3, 2.0)
		if table_pivot:
			table_pivot.scale = Vector2(global_scale, global_scale)
		if middle_area:
			middle_area.scale = Vector2(0.7, 0.7)
			middle_area.set_anchors_preset(Control.PRESET_CENTER)
			middle_area.add_theme_constant_override("separation", 20)
			middle_area.reset_size()
			middle_area.pivot_offset = middle_area.size / 2.0
	else:
		# TABLETTE / PC : pas de scale global
		if table_pivot:
			table_pivot.scale = Vector2(1.0, 1.0)
		if middle_area:
			middle_area.set_anchors_preset(Control.PRESET_CENTER)
			middle_area.add_theme_constant_override("separation", 20)
			middle_area.reset_size()
			middle_area.pivot_offset = middle_area.size / 2.0
			middle_area.scale = Vector2(0.8, 0.8)

	var overlays = [turn_overlay, result_overlay, monument_menu, victory_screen, yes_no_panel,
									choose_player_panel, trade_panel, give_panel, demolish_panel, buy_confirm_panel]
	for ov in overlays:
		if is_instance_valid(ov):
			ov.size = screen_size
			ov.position = Vector2.ZERO
			
	if is_game_initialized:
		positionner_plateaux(false)


func _force_overlays_to_front() -> void:
	var overlays = [turn_overlay, result_overlay, monument_menu, victory_screen, yes_no_panel, choose_player_panel, trade_panel, give_panel, demolish_panel, buy_confirm_panel]
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
	
	shop_popup.update_shop(test_shop)
	
	# --- Logique d'illusion pour l'animation de pioche ---
	if pending_shop_animation_index != -1:
		if is_instance_valid(click_blocker):
			click_blocker.show()
			
		await get_tree().process_frame 
		
		var grid = shop_popup.shop_board.grid_container
		if pending_shop_animation_index < grid.get_child_count():
			var new_slot = grid.get_child(pending_shop_animation_index)
			var image_node = new_slot.get_node_or_null("Visual")
			
			if image_node:
				var new_tex = null
				if image_node is TextureButton:
					new_tex = image_node.texture_normal
				elif image_node is TextureRect:
					new_tex = image_node.texture
				
				if new_tex:
					await animer_pioche_vers_shop(new_slot, new_tex)
					await get_tree().create_timer(0.6).timeout
		
		pending_shop_animation_index = -1
		
		if is_instance_valid(click_blocker):
			click_blocker.hide()
			
	update_all_boards()
	
	if not is_game_initialized:
		positionner_plateaux(false) 
		is_game_initialized = true
	elif player_changed and game.playerCount > 0:
		positionner_plateaux(true)  
		
	set_actions_enabled(false) 

func update_all_boards() -> void:
	for b in boards: b.hide()
	for i in range(game.playerCount):
		var board = active_boards[i]
		board.show()
		var p = game.playerArray[i]
		board.setup(p, p == current_player)

func _find_dice_ui_nodes() -> void:
	result_overlay = %ResultOverlay
	die_1 = %Die1
	die_2 = %Die2
	
	btn_conserver = find_child("ConserverLeRésultat", true, false)
	btn_relancer = find_child("RefaireLeLancer", true, false)
	btn_add_2 = find_child("Ajouter2AuRésultat", true, false) 

func positionner_plateaux(animate: bool = true) -> void:
	if not game or game.playerCount == 0: return
	var active_idx = game.playerArray.find(current_player)
	if active_idx == -1: active_idx = 0

	var screen_size = get_viewport().get_visible_rect().size
	var c = screen_size / 2.0
	var is_phone = _is_phone()
	
	var margin = 40
	var scale_factor = 1.0
	if is_phone:
		margin = 80
		scale_factor = clamp(screen_size.y / 600.0, 0.3, 2.0)

	# Scale dynamique tablette/PC
	var board_scale = 1.0
	if not is_phone:
		var base_h = 264.0
		var min_screen = min(screen_size.x, screen_size.y)
		var max_scale = (min_screen * 0.30) / base_h
		board_scale = clamp(max_scale, 1.0, 1.3)

	var tween = null
	
	if animate:
		if is_instance_valid(click_blocker): 
			click_blocker.show()
			
		for board in active_boards:
			if is_instance_valid(board) and board.has_method("set_ui_visible"):
				board.set_ui_visible(false)
				
		is_rotating = true
		set_actions_enabled(false)
		tween = get_tree().create_tween().set_parallel(true)
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	for p_idx in range(game.playerCount):
		var board = active_boards[p_idx]
		if not is_instance_valid(board): continue
		
		board.custom_minimum_size = Vector2(0, 0)
		board.reset_size()
		
		var real_size = board.size
		var b_h = real_size.y 
		
		var rx: float
		var ry: float
		if is_phone:
			rx = ((screen_size.x / 2.0) - (b_h * scale_factor / 2.0) - margin) * 0.60
			ry = (screen_size.y / 2.0) - (b_h * scale_factor / 2.0) - margin
		else:
			rx = (screen_size.x / 2.0) - (b_h * board_scale / 2.0) - margin
			ry = (screen_size.y / 2.0) - (b_h * board_scale / 2.0) - margin
		
		board.pivot_offset = real_size / 2.0

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

		# Scale individuel des boards : téléphone uniquement
		if is_phone:
			board.scale = Vector2(1.0, 1.0) if diff == 0 else Vector2(0.7, 0.7)
		else:
			board.scale = Vector2(board_scale, board_scale)

		if animate:
			var start_angle = player_angles[p_idx]
			var current_rot = board.rotation
			
			var rot_diff = fmod(target_rot - current_rot, 2 * PI)
			if rot_diff > 0.01: rot_diff -= 2 * PI
			elif rot_diff < -2 * PI + 0.01: rot_diff += 2 * PI
			
			var ang_diff = fmod(target_angle - start_angle, 2 * PI)
			if ang_diff > 0.01: ang_diff -= 2 * PI
			elif ang_diff < -2 * PI + 0.01: ang_diff += 2 * PI

			var final_rot = current_rot + rot_diff
			var final_ang = start_angle + ang_diff

			var move_circular = func(t: float, b: Control, s_ang: float, t_ang: float):
				var current_ang = lerp(s_ang, t_ang, t)
				var target_center = c + Vector2(cos(current_ang)*rx, sin(current_ang)*ry)
				b.pivot_offset = b.size / 2.0
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
		if is_instance_valid(click_blocker): 
			click_blocker.hide()
		rotation_finished.emit()

func waitForDiceRoll() -> int:
	for board in active_boards:
		if is_instance_valid(board) and board.has_method("set_ui_visible"):
			board.set_ui_visible(false)

	if is_rotating:
		await rotation_finished

	for d in mini_dice_array:
		if is_instance_valid(d): d.queue_free()
	mini_dice_array.clear()
	
	var nom = current_player.username
	var prefix = tr("Tour de ")
	if ["A","E","I","O","U","Y"].has(nom[0].to_upper()):
		prefix = tr("Tour d' ")
		
	lbl_turn_announcement.text = prefix + nom
	
	var has_gare = false
	if current_player.has_method("monumentIsActive"):
		has_gare = current_player.monumentIsActive(Monument.MONUMENT_ID.Gare)
		
	if btn_overlay_roll_2:
		if has_gare:
			btn_overlay_roll_2.visible = true
			btn_overlay_roll_2.disabled = false
		else:
			btn_overlay_roll_2.visible = false
			btn_overlay_roll_2.disabled = true
			
	turn_overlay.move_to_front()
	turn_overlay.show()
	set_actions_enabled(false) 
	
	var amount = await dice_amount_chosen
	turn_overlay.hide()
	
	return amount

func showResult(d1: int, d2: int, can_reroll: bool = false) -> String:
	var amount = 1 if d2 == 0 else 2
	var action = await play_dice_animation(amount, d1, d2, can_reroll)
	
	if action == "reroll":
		return action
	
	for board in active_boards:
		if is_instance_valid(board) and board.has_method("set_ui_visible"):
			board.set_ui_visible(true)
			board.setup(board.player_data, board.player_data == current_player)
	
	set_actions_enabled(true)
	return action

func play_dice_animation(amount: int, final_d1: int, final_d2: int = 0, can_reroll: bool = false) -> String:
	if die_1 == null or result_overlay == null: return "keep"
	
	result_overlay.move_to_front()
	result_overlay.show()
	
	if btn_conserver: btn_conserver.hide()
	if btn_relancer: btn_relancer.hide()
	if btn_add_2: btn_add_2.hide()
	
	die_1.show()
	if die_2: die_2.visible = (amount == 2)
	
	die_1.pivot_offset = die_1.size / 2.0
	if die_2:
		die_2.pivot_offset = die_2.size / 2.0
	
	var frames = 15
	var delay = 0.05 
	
	for i in range(frames):
		die_1.texture = dice_textures[randi() % 6]
		die_1.rotation_degrees = randf_range(-25, 25)
		
		if amount == 2 and die_2: 
			die_2.texture = dice_textures[randi() % 6]
			die_2.rotation_degrees = randf_range(-25, 25)
			
		await get_tree().create_timer(delay).timeout
		if i > frames - 4: delay += 0.05 
		
	die_1.rotation_degrees = 0.0
	die_1.texture = dice_textures[final_d1 - 1]
	
	if amount == 2 and die_2: 
		die_2.rotation_degrees = 0.0
		die_2.texture = dice_textures[final_d2 - 1]
	
	var total = final_d1 + final_d2
	var has_port = false
	if current_player and current_player.has_method("monumentIsActive"):
		has_port = current_player.monumentIsActive(Monument.MONUMENT_ID.Port)
		
	if btn_conserver: btn_conserver.show(); btn_conserver.disabled = false
	if btn_relancer: btn_relancer.visible = can_reroll; btn_relancer.disabled = false
	if btn_add_2: btn_add_2.visible = (has_port and total >= 10); btn_add_2.disabled = false
		
	var action = await dice_decision_made
	
	if action == "reroll":
		result_overlay.hide()
		return action 
	
	is_rotating = true 
	if is_instance_valid(click_blocker): click_blocker.show()
	
	var start_pos_1 = die_1.global_position
	var start_size_1 = die_1.size
	
	var active_idx = game.playerArray.find(current_player)
	if active_idx == -1: active_idx = 0
	var target_board = active_boards[active_idx]
	
	result_overlay.hide()
	
	var target_btn = target_board.btn_pass
	if not is_instance_valid(target_btn) or not target_btn.is_inside_tree():
		target_btn = target_board 
		
	var dummy_1 = TextureRect.new()
	dummy_1.texture = die_1.texture
	dummy_1.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dummy_1.size = start_size_1
	target_btn.add_child(dummy_1) 
	dummy_1.global_position = start_pos_1 
	dummy_1.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	mini_dice_array.append(dummy_1)
	
	var dummy_2 = null
	if amount == 2 and die_2:
		dummy_2 = TextureRect.new()
		dummy_2.texture = die_2.texture
		dummy_2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		dummy_2.size = die_2.size
		target_btn.add_child(dummy_2) 
		dummy_2.global_position = die_2.global_position
		dummy_2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mini_dice_array.append(dummy_2)
		
	var anim_duration = 0.6 
	var target_scale = Vector2(0.2, 0.2)
	var base_local_pos = Vector2(-105, -2)
	var ecart_entre_des = 45 
	
	var target_local_pos_1 = base_local_pos
	var target_local_pos_2 = Vector2.ZERO 
	
	var addTwo_lbl = Label.new()
	var result_lbl = Label.new()
	
	var espace_a_droite_des_des = 40
		
	result_lbl.add_theme_font_size_override("font_size", 34) 
	addTwo_lbl.add_theme_font_size_override("font_size", 34)
	var _font = load("res://assets/Fonts/Exo_2/static/Exo2-BlackItalic.ttf")
	if _font:
		result_lbl.add_theme_font_override("font", _font)
		addTwo_lbl.add_theme_font_override("font", _font)
	
	if action == "add2":
		total += 2
		base_local_pos += Vector2(-45,0)
		addTwo_lbl.text = " + 2 "
		addTwo_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0)) 

	result_lbl.text += " = " + str(total)
	result_lbl.add_theme_color_override("font_color", Color.WHITE) 
	
	if amount == 2:
		base_local_pos += Vector2(-20,0)
		target_local_pos_1 = base_local_pos - Vector2(ecart_entre_des, 0) 
		target_local_pos_2 = base_local_pos 
	
	var tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property(dummy_1, "position", target_local_pos_1, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(dummy_1, "scale", target_scale, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	if dummy_2:
		tween.tween_property(dummy_2, "position", target_local_pos_2, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(dummy_2, "scale", target_scale, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
	await tween.finished
	
	if action == "add2":
		target_btn.add_child(addTwo_lbl)
		addTwo_lbl.position = base_local_pos + Vector2(espace_a_droite_des_des - 5, -5)
		base_local_pos += Vector2(50, 0)
	
	target_btn.add_child(result_lbl)
	result_lbl.position = base_local_pos + Vector2(espace_a_droite_des_des, -5)
	
	result_lbl.modulate.a = 0.0
	if action == "add2": addTwo_lbl.modulate.a = 0.0
		
	var fade_tween = get_tree().create_tween().set_parallel(true)
	fade_tween.tween_property(result_lbl, "modulate:a", 1.0, 0.2)
	if action == "add2":
		fade_tween.tween_property(addTwo_lbl, "modulate:a", 1.0, 0.2)
	
	await fade_tween.finished
		
	mini_dice_array.append(result_lbl) 
	if action == "add2":
		mini_dice_array.append(addTwo_lbl)
			
	is_rotating = false
	if is_instance_valid(click_blocker): click_blocker.hide()
	
			
	return action

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
	# Safety: ensure click_blocker is never left visible from a prior animation
	if is_instance_valid(click_blocker): click_blocker.hide()
	update_all_boards()
	set_actions_enabled(true)
	var choice = await action_selected
	set_actions_enabled(false)
	return choice

func set_actions_enabled(can_act: bool) -> void:
	for board in boards:
		if is_instance_valid(board): board.set_actions_enabled(can_act)
	
	if is_instance_valid(shop_popup): shop_popup.set_actions_enabled(can_act)

func _on_shop_button_pressed() -> void:
	shop_popup.open(test_shop)

func _on_roll_1_pressed() -> void: dice_amount_chosen.emit(1)
func _on_roll_2_pressed() -> void: dice_amount_chosen.emit(2)

func update_monument_menu(is_demolish_mode: bool = false):
	var target_player = self.current_player
	
	
	# Ajout du coût ("cost") directement dans le mapping pour une sécurité absolue
	var monument_map = {
		Monument.MONUMENT_ID.Port: {"node": "Port", "file": "port", "cost": 2},
		Monument.MONUMENT_ID.Gare: {"node": "Gare", "file": "gare", "cost": 4},
		Monument.MONUMENT_ID.Centre_Commercial: {"node": "Centre commercial", "file": "centre_commercial", "cost": 10},
		Monument.MONUMENT_ID.Parc: {"node": "Parc d'attraction", "file": "parc_dattraction", "cost": 16},
		Monument.MONUMENT_ID.Radio: {"node": "Tour radio", "file": "tour_radio", "cost": 22},
		Monument.MONUMENT_ID.Aeroport: {"node": "Aéroport", "file": "aéroport", "cost": 30}
	}
	
	for m_id in monument_map:
		var data = monument_map[m_id]
		var vbox = cards_monuments_container.get_node_or_null(data["node"])
		if not vbox: continue
		
		var tex_rect: TextureRect = vbox.get_child(0)
		var build_btn: TextureButton = vbox.get_child(1)
		
		var is_built = target_player.monumentIsActive(m_id)
		
		var state = ""
		if data["file"] == data["file"].to_upper():
			state = "RECTO" if is_built else "VERSO"
		else:
			state = "recto" if is_built else "verso"
			
		var tex_path = "res://assets/Cards/" + get_lang_folder() + "/" + "Monuments/" + data["file"] + "_" + state + ".png"
		var _tex = load(tex_path)
		if _tex:
			tex_rect.texture = _tex
		else:
			print("🔴 ERREUR IMAGE : Godot ne trouve pas ce fichier -> ", tex_path)
			
		for conn in build_btn.pressed.get_connections():
			build_btn.pressed.disconnect(conn.callable)
			
		if is_demolish_mode:
			if is_built:
				build_btn.modulate.a = 1.0 
				build_btn.disabled = false
				build_btn.text = tr("DÉMOLIR")
			else:
				build_btn.modulate.a = 0.0 
				build_btn.disabled = true
				build_btn.text = tr("DÉMOLIR")
			build_btn.pressed.connect(func(id=m_id): demolish_completed.emit(id))
		else:
			if is_built:
				build_btn.modulate.a = 0.0 
				build_btn.disabled = true
			else:
				build_btn.modulate.a = 1.0 
				build_btn.disabled = false
			
			# ==========================================
			# ACHAT DIRECT DEPUIS LE BOUTON (Plus de panel d'achat)
			# ==========================================
			build_btn.pressed.connect(func(id=m_id, cost=data["cost"]):
				
				# --- 1. ERREUR : Pas assez d'argent ---
				if current_player.balance < cost:
					monument_menu.hide()
					await get_tree().create_timer(0.15).timeout
					
					var p_idx = game.playerArray.find(current_player)
					if p_idx != -1:
						animer_erreur_argent(active_boards[p_idx])
					return # On arrête tout
					
				# --- 2. SUCCÈS : Achat validé ---
				monument_menu.hide() 
				
				if is_instance_valid(click_blocker):
					click_blocker.z_index = 4096
					click_blocker.show()
					
				var p_idx = game.playerArray.find(current_player)
				var board_visuel = active_boards[p_idx]
				
				# On simule visuellement la perte d'argent
				if board_visuel.get("lbl_gold"):
					board_visuel.lbl_gold.text = str(current_player.balance - cost)
				animer_gain_gold(board_visuel, -cost)
				
				# Pause pour voir l'argent monter, PUIS le shake
				await get_tree().create_timer(0.4).timeout
				animer_shake_ecran(20.0, 0.4) 
				await get_tree().create_timer(0.5).timeout
				
				if is_instance_valid(click_blocker):
					click_blocker.hide()
					
				# On informe le backend (c'est LUI qui va modifier les vraies données et passer le tour)
				action_selected.emit([game.CHOICE.Build_MONUMENT, id]) 
			)
		
func _on_construct_clicked(m_id):
	_on_shop_card_clicked(m_id) 
	%ConfirmCardBuy.text = tr("CONSTRUIRE")

func _on_open_monuments_pressed() -> void:
	update_monument_menu()
	monument_menu.move_to_front()
	monument_menu.show()

func _on_close_menu_pressed() -> void: monument_menu.hide()

func _on_skip_pressed() -> void:
	if game and game.CHOICE: action_selected.emit([game.CHOICE.SKIP, 0])

func get_clean_file_name(card_name: String, color: int = -1) -> String:
	var prefix = ""
	match color:
		CardColor.Type.BLUE: prefix = "bleu_"
		CardColor.Type.GREEN: prefix = "vert_"
		CardColor.Type.RED: prefix = "rouge_"
		CardColor.Type.PURPLE: prefix = "violet_"
	var clean_name = card_name.to_lower().replace(" ", "_").replace("'", "_")
	clean_name = clean_name.replace("é", "e").replace("è", "e").replace("à", "a").replace("ô","o").replace("î","i")
	return prefix + clean_name

func ask_choose_player(owner_player, all_players: Array):
	choose_player_panel.move_to_front()
	choose_player_panel.show()
	for child in player_buttons_container.get_children(): child.queue_free()
	for p in all_players:
		if p != owner_player:
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(130, 180)
			
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.15, 0.15, 0.15, 0.9) 
			style.set_border_width_all(2)
			style.border_color = Color(0.8, 0.8, 0.8, 0.5) 
			style.set_corner_radius_all(8)
			
			var hover_style = style.duplicate()
			hover_style.bg_color = Color(0.25, 0.25, 0.25, 0.9)
			hover_style.border_color = Color(1, 1, 1, 1)
			
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", hover_style)
			btn.add_theme_stylebox_override("pressed", style)
			
			btn.mouse_entered.connect(func():
				var tween = get_tree().create_tween()
				tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1)
			)
			btn.mouse_exited.connect(func():
				var tween = get_tree().create_tween()
				tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
			)
			
			var vbox = VBoxContainer.new()
			vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
			vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			vbox.add_theme_constant_override("separation", 10)
			vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE 
			btn.add_child(vbox)
			
			var profile_tex = TextureRect.new()
			profile_tex.custom_minimum_size = Vector2(90, 90)
			profile_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			profile_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			profile_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
			var avatar_path = "res://assets/UI/profile_picture_player.png"
			var _avatar_tex = load(avatar_path)
			if _avatar_tex:
				profile_tex.texture = _avatar_tex
				
			vbox.add_child(profile_tex)
			
			var name_label = RichTextLabel.new()
			name_label.bbcode_enabled = true
			name_label.fit_content = true
			name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			name_label.custom_minimum_size = Vector2(120, 40)
			
			var icon_path = "res://assets/UI/coin.png" 
			var bbcode_text = "[center]" + p.username + "\n[color=gold]" + str(p.balance) + "[/color] [img=13]" + icon_path + "[/img][/center]"
			
			name_label.text = bbcode_text
			vbox.add_child(name_label)
			
			btn.pressed.connect(func(): _on_player_chosen(p))
			player_buttons_container.add_child(btn)
			
	var chosen_target = await player_chosen
	choose_player_panel.hide()
	return chosen_target

func _on_player_chosen(target) -> void: player_chosen.emit(target)

func ask_trade_cards(owner_player, all_players: Array) -> Array:
	trade_panel.move_to_front()
	trade_panel.show()
	trade_opponents.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	trade_my_cards.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	trade_their_cards.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	btn_confirm_trade.disabled = true
	btn_confirm_trade.text = tr("Sélectionnez les cartes à échanger")
	trade_target = null
	trade_their_card_id = -1
	trade_my_card_id = -1
	
	for c in trade_opponents.get_children(): c.queue_free()
	for c in trade_my_cards.get_children(): c.queue_free()
	for c in trade_their_cards.get_children(): c.queue_free()
	
	for p in all_players:
		if p != owner_player:
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(130, 180)
			btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN 
			btn.pivot_offset = Vector2(65, 90)
			
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.15, 0.15, 0.15, 0.9) 
			style.set_border_width_all(2)
			style.border_color = Color(0.8, 0.8, 0.8, 0.5) 
			style.set_corner_radius_all(8)
			
			var hover_style = style.duplicate()
			hover_style.bg_color = Color(0.25, 0.25, 0.25, 0.9)
			hover_style.border_color = Color(1, 1, 1, 1)
			
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", hover_style)
			btn.add_theme_stylebox_override("pressed", style)
			
			btn.mouse_entered.connect(func():
				if btn.modulate != Color(0.4, 0.4, 0.4): 
					var tween = get_tree().create_tween()
					tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1)
			)
			btn.mouse_exited.connect(func():
				if btn.modulate != Color(0.4, 0.4, 0.4):
					var tween = get_tree().create_tween()
					tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
			)
			
			var vbox = VBoxContainer.new()
			vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
			vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			vbox.add_theme_constant_override("separation", 10)
			vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE 
			btn.add_child(vbox)
			
			var profile_tex = TextureRect.new()
			profile_tex.custom_minimum_size = Vector2(90, 90)
			profile_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			profile_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			profile_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var avatar_path = "res://assets/UI/profile_picture_player.png"
			var _avatar_tex = load(avatar_path)
			if _avatar_tex:
				profile_tex.texture = _avatar_tex
			vbox.add_child(profile_tex)
			
			var name_label = RichTextLabel.new()
			name_label.bbcode_enabled = true
			name_label.fit_content = true
			name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			name_label.custom_minimum_size = Vector2(120, 40)
			var icon_path = "res://assets/UI/coin.png" 
			name_label.text = "[center]" + p.username + "\n[color=gold]" + str(p.balance) + "[/color] [img=13]" + icon_path + "[/img][/center]"
			vbox.add_child(name_label)
			
			btn.pressed.connect(func():
				_on_trade_opponent_selected(p)
				for child in trade_opponents.get_children():
					if child == btn:
						child.modulate = Color(1.0, 1.0, 1.0)
						child.scale = Vector2(1.0, 1.0)
					else:
						child.modulate = Color(0.4, 0.4, 0.4)
						child.scale = Vector2(0.9, 0.9)
			)
			trade_opponents.add_child(btn)

	for c in trade_my_cards.get_children(): c.queue_free()
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
			var card_btn = TextureButton.new()
			card_btn.custom_minimum_size = Vector2(130, 180) 
			card_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			card_btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			card_btn.pivot_offset = Vector2(65, 90)
			
			card_btn.ignore_texture_size = true
			card_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			
			var clean_name = get_clean_file_name(card.name, card.color)
			var path = "res://assets/Cards/" + get_lang_folder() + "/" + "Establishments/" + clean_name + "_1.png"
			var _card_tex = load(path)
			if _card_tex:
				card_btn.texture_normal = _card_tex
			
			var outline = Panel.new()
			outline.set_anchors_preset(Control.PRESET_FULL_RECT)
			outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card_btn.add_child(outline)
			
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0, 0, 0, 0)
			style.set_border_width_all(3)
			style.set_corner_radius_all(8)
			
			match card.color:
				CardColor.Type.BLUE: style.border_color = Color(0.2, 0.4, 0.8, 0.8)
				CardColor.Type.GREEN: style.border_color = Color(0.2, 0.6, 0.2, 0.8)
				CardColor.Type.RED: style.border_color = Color(0.8, 0.2, 0.2, 0.8)
				
			outline.add_theme_stylebox_override("panel", style)
			
			var hover_style = style.duplicate()
			hover_style.border_color = Color(1, 1, 1, 1)
			hover_style.shadow_color = Color(1.0, 1.0, 1.0, 0.6)
			hover_style.shadow_size = 20
			
			card_btn.mouse_entered.connect(func(): 
				outline.add_theme_stylebox_override("panel", hover_style)
				if card_btn.modulate != Color(0.4, 0.4, 0.4):
					var tween = get_tree().create_tween().set_parallel(true)
					tween.tween_property(card_btn, "scale", Vector2(1.05, 1.05), 0.1)
					tween.tween_property(card_btn, "rotation", deg_to_rad(3), 0.1)
			)
			card_btn.mouse_exited.connect(func(): 
				outline.add_theme_stylebox_override("panel", style)
				if card_btn.modulate != Color(0.4, 0.4, 0.4):
					var tween = get_tree().create_tween().set_parallel(true)
					tween.tween_property(card_btn, "scale", Vector2(1.0, 1.0), 0.1)
					tween.tween_property(card_btn, "rotation", 0.0, 0.1)
			)
			
			card_btn.pressed.connect(func():
				if is_mine: trade_my_card_id = card_id
				else: trade_their_card_id = card_id
				
				_check_trade_valid()
				
				for child in container.get_children():
					if child == card_btn:
						child.modulate = Color(1.0, 1.0, 1.0)
						child.scale = Vector2(1.0, 1.0)
					else:
						child.modulate = Color(0.4, 0.4, 0.4)
						child.scale = Vector2(0.9, 0.9)
			)
			
			container.add_child(card_btn)

func _check_trade_valid() -> void:
	if trade_target != null and trade_their_card_id != -1 and trade_my_card_id != -1:
		btn_confirm_trade.disabled = false
		btn_confirm_trade.text = tr("Confirmer")

func _on_confirm_trade_pressed() -> void: 
	trade_completed.emit([trade_my_card_id, trade_target, trade_their_card_id])

func ask_give_card(owner_player, all_players: Array) -> Array:
	give_panel.move_to_front()
	give_panel.show()
	btn_confirm_give.disabled = true
	btn_confirm_give.text = tr("Sélectionnez une carte et un adversaire")
	give_target = null
	give_card_id = -1
	
	for c in give_my_cards.get_children(): c.queue_free()
	for c in give_opponents.get_children(): c.queue_free()
	for instance in owner_player.deck:
		if typeof(instance) != TYPE_ARRAY: continue
		var card_id = instance[0]
		var card = CardFactory.get_card(card_id)
		
		if card != null and card.color != CardColor.Type.PURPLE:
			var card_btn = TextureButton.new()
			card_btn.custom_minimum_size = Vector2(200, 280)
			card_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			card_btn.pivot_offset = Vector2(100, 140) 
			
			card_btn.ignore_texture_size = true
			card_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			
			var clean_name = get_clean_file_name(card.name, card.color)
			var path = "res://assets/Cards/" + get_lang_folder() + "/" + "Establishments/" + clean_name + "_1.png"
			var _card_tex = load(path)
			if _card_tex:
				card_btn.texture_normal = _card_tex
			
			var outline = Panel.new()
			outline.set_anchors_preset(Control.PRESET_FULL_RECT)
			outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card_btn.add_child(outline)
			
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0, 0, 0, 0)
			style.set_border_width_all(3)
			style.set_corner_radius_all(8)
			
			match card.color:
				CardColor.Type.BLUE: style.border_color = Color(0.2, 0.4, 0.8, 0.8)
				CardColor.Type.GREEN: style.border_color = Color(0.2, 0.6, 0.2, 0.8)
				CardColor.Type.RED: style.border_color = Color(0.8, 0.2, 0.2, 0.8)
				
			outline.add_theme_stylebox_override("panel", style)
			
			var hover_style = style.duplicate()
			hover_style.border_color = Color(1, 1, 1, 1)
			hover_style.shadow_color = Color(1.0, 1.0, 1.0, 0.6)
			hover_style.shadow_size = 20
			
			card_btn.mouse_entered.connect(func(): 
				outline.add_theme_stylebox_override("panel", hover_style)
				if card_btn.modulate != Color(0.4, 0.4, 0.4):
					var tween = get_tree().create_tween().set_parallel(true)
					tween.tween_property(card_btn, "scale", Vector2(1.05, 1.05), 0.1)
					tween.tween_property(card_btn, "rotation", deg_to_rad(3), 0.1)
			)
			card_btn.mouse_exited.connect(func(): 
				outline.add_theme_stylebox_override("panel", style)
				if card_btn.modulate != Color(0.4, 0.4, 0.4):
					var tween = get_tree().create_tween().set_parallel(true)
					tween.tween_property(card_btn, "scale", Vector2(1.0, 1.0), 0.1)
					tween.tween_property(card_btn, "rotation", 0.0, 0.1)
			)
			
			card_btn.pressed.connect(func():
				give_card_id = card_id
				_check_give_valid()
				
				for child in give_my_cards.get_children():
					if child == card_btn:
						child.modulate = Color(1.0, 1.0, 1.0)
						child.scale = Vector2(1.0, 1.0)
					else:
						child.modulate = Color(0.4, 0.4, 0.4)
						child.scale = Vector2(0.9, 0.9)
			)
			
			give_my_cards.add_child(card_btn)

	for p in all_players:
		if p != owner_player:
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(130, 180)
			btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			btn.pivot_offset = Vector2(65, 90)
			
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.15, 0.15, 0.15, 0.9) 
			style.set_border_width_all(2)
			style.border_color = Color(0.8, 0.8, 0.8, 0.5) 
			style.set_corner_radius_all(8)
			
			var hover_style = style.duplicate()
			hover_style.bg_color = Color(0.25, 0.25, 0.25, 0.9)
			hover_style.border_color = Color(1, 1, 1, 1)
			
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", hover_style)
			btn.add_theme_stylebox_override("pressed", style)
			
			btn.mouse_entered.connect(func():
				if btn.modulate != Color(0.4, 0.4, 0.4):
					var tween = get_tree().create_tween()
					tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1)
			)
			btn.mouse_exited.connect(func():
				if btn.modulate != Color(0.4, 0.4, 0.4):
					var tween = get_tree().create_tween()
					tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
			)
			
			var vbox = VBoxContainer.new()
			vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
			vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			vbox.add_theme_constant_override("separation", 10)
			vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE 
			btn.add_child(vbox)
			
			var profile_tex = TextureRect.new()
			profile_tex.custom_minimum_size = Vector2(90, 90)
			profile_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			profile_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			profile_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var avatar_path = "res://assets/UI/profile_picture_player.png"
			var _avatar_tex = load(avatar_path)
			if _avatar_tex:
				profile_tex.texture = _avatar_tex
			vbox.add_child(profile_tex)
			
			var name_label = RichTextLabel.new()
			name_label.bbcode_enabled = true
			name_label.fit_content = true
			name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			name_label.custom_minimum_size = Vector2(120, 40)
			var icon_path = "res://assets/UI/coin.png" 
			name_label.text = "[center]" + p.username + "\n[color=gold]" + str(p.balance) + "[/color] [img=13]" + icon_path + "[/img][/center]"
			vbox.add_child(name_label)
			
			btn.pressed.connect(func():
				give_target = p
				_check_give_valid()
				
				for child in give_opponents.get_children():
					if child == btn:
						child.modulate = Color(1.0, 1.0, 1.0)
						child.scale = Vector2(1.0, 1.0)
					else:
						child.modulate = Color(0.4, 0.4, 0.4)
						child.scale = Vector2(0.9, 0.9)
			)
			give_opponents.add_child(btn)

	var result = await give_card_completed
	give_panel.hide()
	return result

func _check_give_valid() -> void:
	if give_target != null and give_card_id != -1:
		btn_confirm_give.disabled = false
		btn_confirm_give.text = tr("Confirmer")

func _on_confirm_give_pressed() -> void: give_card_completed.emit([give_card_id, give_target])

func ask_demolish_monument(owner_player) -> int:
	var has_built_monuments = false
	for m_id in owner_player.monumentArray:
		if owner_player.monumentArray[m_id] == true:
			has_built_monuments = true
			break

	update_monument_menu(true) 
	monument_menu.move_to_front()
	monument_menu.show()
	
	if has_built_monuments:
		close_menu.disabled = true
		close_menu.hide()
	else:
		close_menu.disabled = false
		close_menu.show()

	var result = await demolish_completed
	
	close_menu.disabled = false
	close_menu.show()
	monument_menu.hide()
	
	return result

func _on_confirm_demolish_pressed() -> void: demolish_completed.emit(demolish_monu_id)

func _on_shop_card_clicked(card_id: int) -> void:
	selected_shop_card_id = card_id
	var card_data = CardFactory.get_card(card_id)
		
	if card_data != null:
		var card_name = card_data.get_name()
		var clean_name = ""
		var path_basis = ""
		var tip_path = ""		

		var card_color = card_data.get_color()
		clean_name = get_clean_file_name(card_name, card_color)
		path_basis = "res://assets/Cards/" + get_lang_folder() + "/" + "Establishments/" + clean_name + "_1.png"
		tip_path = "res://assets/Tooltips/" + get_lang_folder() + "/tooltip_" + clean_name + ".png"
		
		# Tailles dynamiques basées sur la résolution
		var screen = get_viewport().get_visible_rect().size
		var preview_w = screen.x * 0.18
		var preview_h = preview_w * 1.28
		
		# Nettoyer les anciens enfants de CardPreview
		for child in card_preview.get_children():
			child.queue_free()
		
		# Créer un TextureRect pour afficher la carte
		var tex_rect = TextureRect.new()
		var tex = load(path_basis)
		if tex:
			tex_rect.texture = tex
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		card_preview.add_child(tex_rect)
		
		card_preview.custom_minimum_size = Vector2(preview_w, preview_h)
		card_preview.size = Vector2(preview_w, preview_h)
		%CardPreview.custom_minimum_size = Vector2(preview_w, preview_h)
		%TooltipImage.custom_minimum_size = Vector2(preview_w, preview_w * 0.6)

		var placeholder_path = "res://assets/Tooltips/" + get_lang_folder() + "/tooltip_vert_marché_de_fruits_et_légumes.png"

		if tip_path != "":
			var tip_tex = load(tip_path)
			if tip_tex:
				%TooltipImage.texture = tip_tex
				%TooltipImage.show()
				%TooltipImage.custom_minimum_size = Vector2(preview_w, preview_h * 0.6)
			else:
				var placeholder_tex = load(placeholder_path)
				if placeholder_tex:
					%TooltipImage.texture = placeholder_tex
					%TooltipImage.show()
					%TooltipImage.custom_minimum_size = Vector2(preview_w, preview_h * 0.6)
				else:
					%TooltipImage.hide()
		else:
			%TooltipImage.hide()

		buy_confirm_panel.move_to_front()
		buy_confirm_panel.show()
		shop_popup.close()

func _on_confirm_buy_shop_pressed() -> void:
	if not game or not game.CHOICE: return

	var card_data = CardFactory.get_card(selected_shop_card_id)
	if card_data == null: return
	
	# ==========================================
	# 1. IDENTIFICATION ET COÛT INFAILLIBLES
	# ==========================================
	var is_monument = (selected_shop_card_id >= 22 and selected_shop_card_id <= 27)
	var cost = 0
	
	if is_monument:
		match selected_shop_card_id:
			22: cost = 4
			23: cost = 10
			24: cost = 16
			25: cost = 22
			26: cost = 2
			27: cost = 30
	else:
		if card_data.has_method("get_cost"): 
			cost = card_data.get_cost()
		elif card_data.get("cost") != null:
			cost = card_data.get("cost")
	
	# ==========================================
	# 2. LOGIQUE D'ERREUR (Pas assez d'argent)
	# ==========================================
	if current_player.balance < cost:
		# 1. Le panel se ferme
		buy_confirm_panel.hide()
		
		if is_monument and is_instance_valid(monument_menu):
			monument_menu.hide()
			
		await get_tree().create_timer(0.15).timeout
		
		# 2. L'animation d'erreur d'argent se joue
		var p_idx_err = game.playerArray.find(current_player)
		if p_idx_err != -1:
			animer_erreur_argent(active_boards[p_idx_err])
		
		if not is_monument:
			if is_instance_valid(shop_popup.shop_board) and is_instance_valid(shop_popup.shop_board.last_clicked_slot):
				animer_erreur_carte_shop(shop_popup.shop_board.last_clicked_slot)
		
		# 3. PAS DE SHAKE (le "return" bloque la suite de la fonction)
		return 

	# ==========================================
	# 3. ACHAT RÉUSSI (Le joueur a l'argent)
	# ==========================================
	
	# 1. Le panel se ferme immédiatement
	buy_confirm_panel.hide()
	if is_monument and is_instance_valid(monument_menu):
		monument_menu.hide() 
	
	if is_instance_valid(click_blocker): 
		click_blocker.z_index = 4096 
		click_blocker.show()
		
	var p_idx = game.playerArray.find(current_player)
	var board_visuel = active_boards[p_idx]
	
	if is_monument:
		# A. Mise à jour de la carte en Recto 
		current_player.monumentArray[selected_shop_card_id] = true
		
		# B. On refresh le board AVANT de toucher à l'or visuel !
		update_all_boards() 
		
		# C. On force le texte à baisser (sinon le refresh précédent remet l'ancien prix)
		if board_visuel.get("lbl_gold"):
			board_visuel.lbl_gold.text = str(current_player.balance - cost)
		
		# D. L'animation de perte de gold se joue...
		animer_gain_gold(board_visuel, -cost)
		
		# E. PUIS on attend que la pièce décolle pour lancer le tremblement...
		await get_tree().create_timer(0.5).timeout 
		
		# F. Le shake de l'écran se déclenche !
		animer_shake_ecran(20.0, 0.4) 
		await get_tree().create_timer(0.6).timeout 
		
		if is_instance_valid(click_blocker): click_blocker.hide()
		
		action_selected.emit([game.CHOICE.Build_MONUMENT, selected_shop_card_id])
		
	else:
		# Logique pour les établissements classiques (cartes du centre)
		if board_visuel.get("lbl_gold"):
			board_visuel.lbl_gold.text = str(current_player.balance - cost)
			
		animer_gain_gold(board_visuel, -cost)
		
		var quantity_in_shop = 1
		if is_instance_valid(test_shop):
			var shop_array = test_shop.get("shop")
			if shop_array:
				for slot in shop_array:
					var c_id = int(slot[0]) if typeof(slot) == TYPE_ARRAY else int(slot.get("id"))
					if c_id == selected_shop_card_id:
						quantity_in_shop = int(slot[1]) if typeof(slot) == TYPE_ARRAY else int(slot.get("quantity"))
						break
		
		if is_instance_valid(shop_popup.shop_board):
			if quantity_in_shop > 1:
				pending_shop_animation_index = -1
				var shop_slot = shop_popup.shop_board.last_clicked_slot
				if is_instance_valid(shop_slot) and shop_slot.has_method("set_badge_count"):
					shop_slot.set_badge_count(quantity_in_shop - 1)
			else:
				pending_shop_animation_index = shop_popup.shop_board.last_clicked_index
		
		await animer_achat_vers_main(selected_shop_card_id, quantity_in_shop)
		
		await get_tree().create_timer(0.5).timeout
		if is_instance_valid(click_blocker): click_blocker.hide()
		
		action_selected.emit([game.CHOICE.Build_ESTABLISHMENT, selected_shop_card_id])

func _on_cancel_buy_shop_pressed() -> void:
	selected_shop_card_id = -1
	buy_confirm_panel.hide()
	if is_instance_valid(shop_popup.shop_board) and shop_popup.shop_board.has_method("clear_selection"):
		shop_popup.shop_board.clear_selection()

func ask_chalutier_roll(player_name: String) -> int:
	while turn_overlay.visible or result_overlay.visible:
		await get_tree().create_timer(0.1).timeout

	lbl_turn_announcement.text = tr("Chalutier de ") + player_name
	
	if btn_overlay_roll_1: btn_overlay_roll_1.hide()
	if btn_overlay_roll_2: 
		btn_overlay_roll_2.show()
		btn_overlay_roll_2.disabled = false
		
	turn_overlay.move_to_front()
	turn_overlay.show()
	
	await dice_amount_chosen 
	turn_overlay.hide()
	
	if btn_overlay_roll_1: btn_overlay_roll_1.show()
	
	var d1 = (randi() % 6) + 1
	var d2 = (randi() % 6) + 1
	var total = d1 + d2
	
	var result_title = result_overlay.get_node("VBoxContainer/LblResultTitle")
	result_title.text = tr("Prise de ") + player_name + "!"
	result_overlay.move_to_front()
	result_overlay.show()
	
	btn_conserver.hide()
	btn_relancer.hide()
	
	die_1.show()
	die_2.show()
	
	var frames = 15
	var delay = 0.05 
	for i in range(frames):
		die_1.texture = dice_textures[randi() % 6]
		die_2.texture = dice_textures[randi() % 6]
		await get_tree().create_timer(delay).timeout
		if i > frames - 4: delay += 0.05 
		
	die_1.texture = dice_textures[d1 - 1]
	die_2.texture = dice_textures[d2 - 1]
	
	var claim_btn = Button.new()
	claim_btn.custom_minimum_size = Vector2(500, 87)
	claim_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var custom_font = preload("res://assets/Fonts/Exo_2/static/Exo2-BlackItalic.ttf")
	claim_btn.add_theme_font_override("font", custom_font)
	claim_btn.add_theme_font_size_override("font_size", 100)
	
	var tex_normal = load("res://assets/UI/blank_red_button.png")
	var tex_hover = load("res://assets/UI/blank_red_button_hover.png")
	
	var style_normal = StyleBoxTexture.new()
	style_normal.texture = tex_normal
	
	var style_hover = StyleBoxTexture.new()
	style_hover.texture = tex_hover
	
	claim_btn.add_theme_stylebox_override("normal", style_normal)
	claim_btn.add_theme_stylebox_override("hover", style_hover)
	claim_btn.add_theme_stylebox_override("pressed", style_normal)
	
	var btn_vbox = VBoxContainer.new()
	btn_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	claim_btn.add_child(btn_vbox)
	
	var btn_rtlabel = RichTextLabel.new()
	btn_rtlabel.bbcode_enabled = true
	btn_rtlabel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn_rtlabel.fit_content = true
	
	var icon_path = "res://assets/UI/coin.png"
	btn_rtlabel.text ="[center][font=res://assets/Fonts/Exo_2/static/Exo2-BlackItalic.ttf][font_size=48]" + tr("RECUPERER") + " [color=gold]" + str(total) + "[/color] [img=48]" + icon_path + "[/img][/font_size][/font][/center]"
	
	btn_vbox.add_child(btn_rtlabel)
	
	var result_vbox = result_overlay.get_node("VBoxContainer")
	result_vbox.add_child(claim_btn)
	
	await claim_btn.pressed
	
	claim_btn.queue_free() 
	result_overlay.hide()
	result_title.text = tr("Résultat du lancer")
	
	return total

func show_victory_screen(winner_name: String) -> void:
	set_actions_enabled(false)
	lbl_winner_name.text = "🏆 " + winner_name + " " + tr("GAGNE!")
	victory_screen.move_to_front()
	victory_screen.show()
	
func _on_quit_pressed() -> void: get_tree().change_scene_to_file("res://scene/Ecran principale/accueil.tscn")

func _unhandled_key_input(event: InputEvent) -> void:
	if is_rotating: return 
	
	if event is InputEventKey and event.pressed and not event.echo:
		
		if event.keycode == KEY_1:
			if turn_overlay and turn_overlay.visible and btn_overlay_roll_1 and not btn_overlay_roll_1.disabled:
				btn_overlay_roll_1.pressed.emit()
				get_viewport().set_input_as_handled()
				
		elif event.keycode == KEY_2:
			if turn_overlay and turn_overlay.visible and btn_overlay_roll_2 and btn_overlay_roll_2.visible and not btn_overlay_roll_2.disabled:
				btn_overlay_roll_2.pressed.emit()
				get_viewport().set_input_as_handled()
				
		elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			if result_overlay and result_overlay.visible and btn_conserver and btn_conserver.visible and not btn_conserver.disabled:
				btn_conserver.pressed.emit()
				get_viewport().set_input_as_handled()
				
			if turn_overlay and turn_overlay.visible and btn_overlay_roll_1 and not btn_overlay_roll_1.disabled:
				btn_overlay_roll_1.pressed.emit()
				get_viewport().set_input_as_handled()
				
			if game and current_player:
				var active_idx = game.playerArray.find(current_player)
				if active_idx != -1 and active_boards.size() > active_idx:
					var target_board = active_boards[active_idx]
					
					if not turn_overlay.visible and not result_overlay.visible:
						_on_skip_pressed()
						get_viewport().set_input_as_handled()
				
		elif event.keycode == KEY_R:
			if result_overlay and result_overlay.visible and btn_relancer and btn_relancer.visible and not btn_relancer.disabled:
				btn_relancer.pressed.emit()
				get_viewport().set_input_as_handled()
				
		elif event.keycode == KEY_P:
			if game and current_player:
				var active_idx = game.playerArray.find(current_player)
				if active_idx != -1 and active_boards.size() > active_idx:
					var target_board = active_boards[active_idx]
					
					if not turn_overlay.visible and not result_overlay.visible:
						_on_skip_pressed()
						get_viewport().set_input_as_handled()

# ==============================================================================
# ======================== BOÎTE À OUTILS: ANIMATIONS JUICY ====================
# ==============================================================================

func _setup_tooltip_glows() -> void:
	var tooltip = get_node_or_null("%TooltipImage")
	if tooltip: appliquer_halo_tooltip(tooltip)
	
	var preview = get_node_or_null("%CardPreview")
	if preview: preview.mouse_filter = Control.MOUSE_FILTER_IGNORE

func appliquer_halo_tooltip(node: Control) -> void:
	if not node or node.has_node("TooltipGlow"): return
	var p = Panel.new()
	p.name = "TooltipGlow"
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.show_behind_parent = true
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0,0,0,0)
	style.shadow_color = Color(1.0, 0.84, 0.0, 0.5)
	style.shadow_size = 40
	style.set_corner_radius_all(10)
	p.add_theme_stylebox_override("panel", style)
	node.add_child(p)

func animer_gain_gold(cible_node: Control, montant: int) -> void:
	if montant == 0: return
	
	var float_text = RichTextLabel.new()
	float_text.bbcode_enabled = true
	float_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	float_text.fit_content = true
	float_text.autowrap_mode = TextServer.AUTOWRAP_OFF # CRUCIAL : empêche l'étirement
	float_text.z_index = 100 
	
	var color = "gold" if montant > 0 else "red"
	var sign_str = "+" if montant > 0 else ""
	var icon_path = "res://assets/UI/coin.png"
	
	float_text.text = "[center][font=res://assets/Fonts/Exo_2/static/Exo2-BlackItalic.ttf][font_size=60][color=" + color + "]" + sign_str + str(montant) + "[/color] [img=60]" + icon_path + "[/img][/font_size][/font][/center]"
	
	add_child(float_text) 
	
	# On cible spécifiquement le Label de l'or (%PlayerMoney) du board plutôt que le centre global
	var anchor_pos = cible_node.global_position + (cible_node.size / 2.0)
	if cible_node.get("lbl_gold"):
		anchor_pos = cible_node.lbl_gold.global_position
		
	float_text.global_position = anchor_pos - Vector2(50, 20)
	float_text.scale = Vector2.ZERO
	float_text.pivot_offset = float_text.size / 2.0 # On utilise la taille réelle calculée
	
	# On garde la rotation du board cible pour que le texte soit lisible pour le joueur !
	float_text.rotation = cible_node.rotation
	
	var tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property(float_text, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	# Mouvement vers le HAUT relatif à la rotation
	var move_offset = Vector2(0, -120).rotated(cible_node.rotation)
	tween.tween_property(float_text, "global_position", float_text.global_position + move_offset, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(float_text, "modulate:a", 0.0, 0.5).set_delay(1.0)
	
	await tween.finished
	float_text.queue_free()

func animer_shake_ecran(intensite: float = 15.0, duree: float = 0.3) -> void:
	if not is_instance_valid(camera): return 
	
	var original_offset = camera.offset 
	var tween = get_tree().create_tween()
	var steps = int(duree / 0.05)
	
	for i in range(steps):
		var offset = Vector2(randf_range(-intensite, intensite), randf_range(-intensite, intensite))
		tween.tween_property(camera, "offset", offset, 0.05).set_trans(Tween.TRANS_SINE)
		
	tween.tween_property(camera, "offset", original_offset, 0.05)

func animer_activation_carte(carte_node: Control) -> void:
	if not is_instance_valid(carte_node): return
	
	var original_scale = carte_node.scale
	carte_node.pivot_offset = carte_node.size / 2.0
	
	var tween = get_tree().create_tween()
	tween.tween_property(carte_node, "scale", original_scale * 1.25, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(carte_node, "scale", original_scale, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func animer_pioche_vers_shop(target_slot: Control, texture_recto: Texture2D) -> void:
	var deck_node = get_node_or_null("CenterBoard/Deck")
	if not is_instance_valid(deck_node) or not is_instance_valid(target_slot): 
		return
		
	target_slot.modulate.a = 0.0
	
	var visual_node = target_slot.get_node_or_null("Visual")
	if not is_instance_valid(visual_node):
		visual_node = target_slot # Sécurité au cas où

	var dummy = TextureRect.new()
	dummy.texture = preload("res://assets/UI/dos_card.png")
	dummy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dummy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED 
	
	# Dimensions exactes de la carte finale
	dummy.size = visual_node.size 
	dummy.pivot_offset = dummy.size / 2.0
	dummy.z_index = 150 
	
	# Point de départ centré sur le deck
	var start_pos = deck_node.global_position + (deck_node.size / 2.0) - dummy.pivot_offset
	dummy.global_position = start_pos
	add_child(dummy)
	
	var anim_duration = 0.6
	# Cible exacte : la position globale du visuel
	var target_pos = visual_node.global_position
	
	var tween_arc = get_tree().create_tween().set_parallel(true)
	tween_arc.tween_property(dummy, "global_position:x", target_pos.x, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	var drop_offset = 150.0
	var lowest_y = max(deck_node.global_position.y, target_pos.y) + drop_offset
	
	var tween_y = get_tree().create_tween()
	tween_y.tween_property(dummy, "global_position:y", lowest_y, anim_duration / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_y.tween_property(dummy, "global_position:y", target_pos.y, anim_duration / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	tween_arc.tween_property(dummy, "rotation_degrees", -360.0, anim_duration).set_trans(Tween.TRANS_CUBIC)
	
	await tween_arc.finished
	
	var flip_tween = get_tree().create_tween()
	flip_tween.tween_property(dummy, "scale:x", 0.0, 0.15).set_trans(Tween.TRANS_SINE)
	flip_tween.tween_callback(func(): 
		dummy.texture = texture_recto 
		dummy.rotation_degrees = 0.0
	)
	flip_tween.tween_property(dummy, "scale:x", 1.0, 0.15).set_trans(Tween.TRANS_SINE)
	
	await flip_tween.finished
	
	if is_instance_valid(target_slot):
		target_slot.modulate.a = 1.0
	dummy.queue_free()
	
func animer_achat_vers_main(card_id: int, quantity_in_shop: int = 1) -> void:
	if not is_instance_valid(shop_popup.shop_board.last_clicked_slot): return
	
	var p_idx = game.playerArray.find(current_player)
	var target_board = active_boards[p_idx] 
	
	var shop_slot = shop_popup.shop_board.last_clicked_slot
	var visual_node = shop_slot.get_node_or_null("Visual")
	
	var card_data = CardFactory.get_card(card_id)
	var color = card_data.get_color()
	var pile_cible = target_board.piles[color]
	var anchor = pile_cible.get_node_or_null("Anchor")
	
	var card_width = 156 
	var stack_gap = 25
	var current_count = anchor.get_child_count() if anchor else 0
	
	pile_cible.custom_minimum_size.x = card_width + (current_count * stack_gap)
	
	var target_pos = pile_cible.global_position
	if is_instance_valid(anchor):
		var offset_local = Vector2(current_count * stack_gap, 0.0).rotated(target_board.rotation)
		target_pos = anchor.global_position + offset_local
	
	var dummy = CARD_ANIMATION_SCENE.instantiate()
	add_child(dummy) 
	dummy.setup_card(card_data, target_board.get_board_tooltip_direction())
	dummy.z_index = 4000
	dummy.top_level = true 
	
	dummy.global_position = visual_node.global_position if visual_node else shop_slot.global_position
	dummy.scale = Vector2(0.75, 0.75)
	
	# --- MODIFICATION ICI ---
	# On ne cache la vraie carte du shop QUE si c'est le dernier exemplaire !
	if visual_node and quantity_in_shop <= 1: 
		visual_node.modulate.a = 0.0
	
	var anim_duration = 0.6
	var tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property(dummy, "global_position", target_pos, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(dummy, "scale", Vector2(1.0, 1.0), anim_duration).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(dummy, "rotation", target_board.rotation, anim_duration).set_trans(Tween.TRANS_CUBIC)
	
	await tween.finished
	
	if is_instance_valid(anchor):
		dummy.get_parent().remove_child(dummy)
		anchor.add_child(dummy)
		dummy.top_level = false
		dummy.position = Vector2(current_count * stack_gap, 0)
		dummy.rotation = 0
		
func declencher_animations_activation(activations: Array) -> void:
	if activations.is_empty(): return
	
	# 1. BLOCAGE TOTAL des interactions pour la durée du spectacle
	if is_instance_valid(click_blocker):
		click_blocker.z_index = 4096
		click_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
		click_blocker.show() 
		
	# 2. PHASE DE MONTÉE : Toutes les cartes s'élèvent ensemble
	var has_valid_cards = false
	for data in activations:
		var c = data.get("carte_visuelle")
		if is_instance_valid(c) and c.has_method("animer_montee"):
			c.animer_montee()
			has_valid_cards = true

	# Always use a timer instead of awaiting tween.finished:
	# if card nodes are queue_free()'d while a tween runs, Godot kills the
	# tween and never emits finished — causing a permanent hang.
	if has_valid_cards:
		await get_tree().create_timer(0.35).timeout # matches animer_montee duration

		
	# 3. PHASE D'EFFETS : On exécute les fonctions de gain (or, vol, etc.)
	for data in activations:
		var effet = data.get("effet_callable")
		if effet is Callable and effet.is_valid():
			effet.call()
			
	# Pause de "Juice" : on laisse le temps de voir les gains s'envoler
	await get_tree().create_timer(1.2).timeout 
	
	# 4. PHASE DE DESCENTE : Tout le monde redescend
	var has_valid_cards_descente = false
	for data in activations:
		var c = data.get("carte_visuelle")
		if is_instance_valid(c) and c.has_method("animer_descente"):
			c.animer_descente()
			has_valid_cards_descente = true

	if has_valid_cards_descente:
		await get_tree().create_timer(0.35).timeout # matches animer_descente duration

		
	# 5. LIBÉRATION : Le jeu peut reprendre
	if is_instance_valid(click_blocker):
		click_blocker.hide()
		
# À ajouter en haut avec les autres variables
var file_animations_activations : Array = []

func notifier_activation(joueur, card_id: int, balance_changes: Dictionary = {}):
	var p_idx = game.playerArray.find(joueur) 
	if p_idx == -1: return 
	
	var board_visuel = active_boards[p_idx] 
	var noeud_carte = board_visuel.get_card_node(card_id) 
	
	# On stocke l'animation pour plus tard 
	file_animations_activations.append({ 
		"carte_visuelle": noeud_carte, 
		"effet_callable": func(): 
			
			# 1. Lancer les animations de texte volant pour tous les joueurs touchés
			for p in balance_changes:
				var amount = balance_changes[p]
				var target_idx = game.playerArray.find(p)
				if target_idx != -1 and is_instance_valid(active_boards[target_idx]):
					animer_gain_gold(active_boards[target_idx], amount)
					
					# 2. Rafraîchir UNIQUEMENT l'étiquette d'argent du plateau touché
					# (On utilise update_info() et surtout pas update_all_boards() pour ne pas casser la carte actuellement en train de léviter !)
					active_boards[target_idx].update_info() 
	})

# Cette fonction lance le spectacle (appelée par Game.gd)
func executer_animations_collectees():
	if not file_animations_activations.is_empty():
		await declencher_animations_activation(file_animations_activations)
		file_animations_activations.clear() # On vide la file après
		
func animer_erreur_carte_shop(slot_node: Control) -> void:
	# On cherche le visuel ou le halo dans le slot du shop
	var visual = slot_node.get_node_or_null("Visual")
	if not visual: return
	
	var tween = create_tween()
	
	# On passe en rouge vif
	tween.tween_property(visual, "modulate", Color(2.0, 0.3, 0.3), 0.1)
	
	# Petite vibration de la carte de gauche à droite
	var orig_pos = visual.position
	for i in range(4):
		var side = 5 if i % 2 == 0 else -5
		tween.tween_property(visual, "position:x", orig_pos.x + side, 0.05)
	
	tween.tween_property(visual, "position:x", orig_pos.x, 0.05)
	
	# Retour à la normale (blanc/transparent)
	tween.tween_property(visual, "modulate", Color.WHITE, 0.3).set_delay(0.2)
	
	# Nettoyage de la sélection
	if is_instance_valid(shop_popup.shop_board) and shop_popup.shop_board.has_method("clear_selection"):
		tween.tween_callback(func(): shop_popup.shop_board.clear_selection())
	
func animer_erreur_argent(board_visuel: PlayerBoard) -> void:
	var label_argent = board_visuel.lbl_gold
	if not label_argent: return
	
	# On crée un clignotement rapide en rouge
	var tween = create_tween()
	label_argent.modulate = Color.RED
	
	# Tremblement léger du texte (Optionnel mais sympa)
	var original_pos = label_argent.position
	tween.tween_property(label_argent, "position:x", original_pos.x + 5, 0.05)
	tween.tween_property(label_argent, "position:x", original_pos.x - 5, 0.05)
	tween.tween_property(label_argent, "position:x", original_pos.x, 0.05)
	
	# Retour à la couleur normale (Blanc)
	tween.tween_property(label_argent, "modulate", Color.WHITE, 0.3).set_delay(0.2)
	
func animer_echange_cartes(joueur1, id_carte1: int, joueur2, id_carte2: int) -> void:
	var p1_idx = game.playerArray.find(joueur1)
	var p2_idx = game.playerArray.find(joueur2)
	
	if p1_idx == -1 or p2_idx == -1: return
	
	var board1 = active_boards[p1_idx]
	var board2 = active_boards[p2_idx]
	
	var noeud1 = board1.get_card_node(id_carte1)
	var noeud2 = board2.get_card_node(id_carte2)
	
	if not is_instance_valid(noeud1) or not is_instance_valid(noeud2): return
	
	var card_data1 = CardFactory.get_card(id_carte1)
	var card_data2 = CardFactory.get_card(id_carte2)
	
	var p1_color = card_data1.get_color()
	var p2_color = card_data2.get_color()
	
	var card_width = 156
	var stack_gap = 25
	var anim_duration = 0.8
	
	# --- 1. CALCUL DES DELTAS ---
	var b1_deltas = { CardColor.Type.BLUE: 0, CardColor.Type.GREEN: 0, CardColor.Type.RED: 0, CardColor.Type.PURPLE: 0 }
	var b2_deltas = { CardColor.Type.BLUE: 0, CardColor.Type.GREEN: 0, CardColor.Type.RED: 0, CardColor.Type.PURPLE: 0 }
	
	b1_deltas[p1_color] -= 1
	b1_deltas[p2_color] += 1
	b2_deltas[p2_color] -= 1
	b2_deltas[p1_color] += 1
	
	var tween = get_tree().create_tween().set_parallel(true)
	
	# --- 2. ANIMATION FLUIDE DES FONDS DE COULEUR ---
	var animer_fond_pile = func(board: PlayerBoard, color: int, delta: int):
		if delta == 0: return 
		
		var pile = board.piles[color]
		var anchor = pile.get_node_or_null("Anchor")
		var current_count = anchor.get_child_count() if anchor else 0
		
		var final_count = max(0, current_count + delta)
		var visual_count = max(1, final_count)
		
		var target_width = card_width + ((visual_count - 1) * stack_gap)
		tween.tween_property(pile, "custom_minimum_size:x", target_width, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	animer_fond_pile.call(board1, p1_color, b1_deltas[p1_color])
	if p1_color != p2_color: animer_fond_pile.call(board1, p2_color, b1_deltas[p2_color])
	
	animer_fond_pile.call(board2, p1_color, b2_deltas[p1_color])
	if p1_color != p2_color: animer_fond_pile.call(board2, p2_color, b2_deltas[p2_color])

	# --- 2.5 GLISSEMENT DES CARTES RESTANTES (Correction du clipping !) ---
	var glisser_cartes_restantes = func(noeud_carte_partante):
		var anchor = noeud_carte_partante.get_parent()
		if is_instance_valid(anchor):
			var index_partant = noeud_carte_partante.get_index()
			for i in range(anchor.get_child_count()):
				var child = anchor.get_child(i)
				# Toutes les cartes visuellement "derrière" celle qui part reculent d'un cran
				if i > index_partant:
					var nouvelle_pos_x = child.position.x - stack_gap
					tween.tween_property(child, "position:x", nouvelle_pos_x, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	glisser_cartes_restantes.call(noeud1)
	glisser_cartes_restantes.call(noeud2)

	# --- 3. CALCUL DES POSITIONS D'ARRIVÉE ---
	var get_target_pos = func(target_board: PlayerBoard, color: int, delta: int):
		var pile = target_board.piles[color]
		var anchor = pile.get_node_or_null("Anchor")
		var current_count = anchor.get_child_count() if anchor else 0
		
		var final_count = max(0, current_count + delta)
		var landing_index = max(0, final_count - 1)
		
		var target_pos = pile.global_position
		if is_instance_valid(anchor):
			var offset_local = Vector2(landing_index * stack_gap, 0.0).rotated(target_board.rotation)
			target_pos = anchor.global_position + offset_local
		return target_pos
		
	var end_pos1 = get_target_pos.call(board2, p1_color, b2_deltas[p1_color])
	var end_pos2 = get_target_pos.call(board1, p2_color, b1_deltas[p2_color])

	# --- 4. CRÉATION DES DUMMIES ET DÉPART ---
	var start_pos1 = noeud1.global_position
	var start_pos2 = noeud2.global_position
	var rot1 = board1.rotation
	var rot2 = board2.rotation
	
	var dummy1 = CARD_ANIMATION_SCENE.instantiate()
	var dummy2 = CARD_ANIMATION_SCENE.instantiate()
	add_child(dummy1)
	add_child(dummy2)
	
	dummy1.setup_card(card_data1, board1.get_board_tooltip_direction())
	dummy2.setup_card(card_data2, board2.get_board_tooltip_direction())
	
	dummy1.z_index = 4000
	dummy2.z_index = 4000
	dummy1.top_level = true
	dummy2.top_level = true
	
	dummy1.global_position = start_pos1
	dummy1.rotation = rot1
	dummy2.global_position = start_pos2
	dummy2.rotation = rot2
	
	noeud1.modulate.a = 0.0
	noeud2.modulate.a = 0.0
	
	if is_instance_valid(click_blocker): click_blocker.show()
	
	# --- 5. ANIMATION DE VOL ---
	tween.tween_property(dummy1, "global_position", end_pos1, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(dummy1, "rotation", rot2, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(dummy2, "global_position", end_pos2, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(dummy2, "rotation", rot1, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(dummy1, "scale", Vector2(1.2, 1.2), anim_duration / 2.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(dummy1, "scale", Vector2(1.0, 1.0), anim_duration / 2.0).set_delay(anim_duration / 2.0)
	tween.tween_property(dummy2, "scale", Vector2(1.2, 1.2), anim_duration / 2.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(dummy2, "scale", Vector2(1.0, 1.0), anim_duration / 2.0).set_delay(anim_duration / 2.0)
	
	await tween.finished
	
	# --- 6. TRANSFERT ET NETTOYAGE ---
	var transfer_to_board = func(dummy: Control, target_board: PlayerBoard, card_data, delta: int):
		var color = card_data.get_color()
		var anchor = target_board.piles[color].get_node_or_null("Anchor")
		if is_instance_valid(anchor):
			var current_count = anchor.get_child_count()
			var final_count = max(0, current_count + delta)
			var landing_index = max(0, final_count - 1)

			dummy.get_parent().remove_child(dummy)
			anchor.add_child(dummy)
			dummy.top_level = false
			dummy.position = Vector2(landing_index * stack_gap, 0)
			dummy.rotation = 0
			dummy.setup_card(card_data, target_board.get_board_tooltip_direction())

	transfer_to_board.call(dummy1, board2, card_data1, b2_deltas[p1_color])
	transfer_to_board.call(dummy2, board1, card_data2, b1_deltas[p2_color])
	
	if is_instance_valid(click_blocker): click_blocker.hide()
	
func animer_don_carte(donneur, id_carte: int, receveur) -> void:
	var p1_idx = game.playerArray.find(donneur)
	var p2_idx = game.playerArray.find(receveur)
	
	if p1_idx == -1 or p2_idx == -1: return
	
	var board_source = active_boards[p1_idx]
	var board_cible = active_boards[p2_idx]
	
	var noeud_carte = board_source.get_card_node(id_carte)
	if not is_instance_valid(noeud_carte): return
	
	var card_data = CardFactory.get_card(id_carte)
	var color = card_data.get_color()
	
	var card_width = 156
	var stack_gap = 25
	var anim_duration = 0.8
	
	var tween = get_tree().create_tween().set_parallel(true)
	
	# --- 1. RÉTRÉCIR LA ZONE SOURCE ET GLISSER LES CARTES ---
	var pile_source = board_source.piles[color]
	var anchor_source = pile_source.get_node_or_null("Anchor")
	var count_source = anchor_source.get_child_count() if anchor_source else 0
	
	var target_w_source = card_width + ((max(1, max(0, count_source - 1)) - 1) * stack_gap)
	tween.tween_property(pile_source, "custom_minimum_size:x", target_w_source, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	if is_instance_valid(anchor_source):
		var index_partant = noeud_carte.get_index()
		for i in range(anchor_source.get_child_count()):
			var child = anchor_source.get_child(i)
			if i > index_partant:
				tween.tween_property(child, "position:x", child.position.x - stack_gap, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	# --- 2. AGRANDIR LA ZONE CIBLE ---
	var pile_cible = board_cible.piles[color]
	var anchor_cible = pile_cible.get_node_or_null("Anchor")
	var count_cible = anchor_cible.get_child_count() if anchor_cible else 0
	
	var target_w_cible = card_width + (count_cible * stack_gap)
	tween.tween_property(pile_cible, "custom_minimum_size:x", target_w_cible, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	# --- 3. CALCUL DE LA POSITION D'ARRIVÉE ---
	var end_pos = pile_cible.global_position
	if is_instance_valid(anchor_cible):
		var offset_local = Vector2(count_cible * stack_gap, 0.0).rotated(board_cible.rotation)
		end_pos = anchor_cible.global_position + offset_local

	# --- 4. CRÉATION DU DUMMY ---
	var dummy = CARD_ANIMATION_SCENE.instantiate()
	add_child(dummy)
	dummy.setup_card(card_data, board_source.get_board_tooltip_direction())
	dummy.z_index = 4000
	dummy.top_level = true
	dummy.global_position = noeud_carte.global_position
	dummy.rotation = board_source.rotation
	
	noeud_carte.modulate.a = 0.0
	if is_instance_valid(click_blocker): click_blocker.show()

	# --- 5. ANIMATION DE VOL ---
	tween.tween_property(dummy, "global_position", end_pos, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(dummy, "rotation", board_cible.rotation, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(dummy, "scale", Vector2(1.2, 1.2), anim_duration / 2.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(dummy, "scale", Vector2(1.0, 1.0), anim_duration / 2.0).set_delay(anim_duration / 2.0)

	await tween.finished

	# --- 6. INTÉGRATION CIBLE ---
	if is_instance_valid(anchor_cible):
		dummy.get_parent().remove_child(dummy)
		anchor_cible.add_child(dummy)
		dummy.top_level = false
		dummy.position = Vector2(count_cible * stack_gap, 0)
		dummy.rotation = 0
		dummy.setup_card(card_data, board_cible.get_board_tooltip_direction())

	if is_instance_valid(click_blocker): click_blocker.hide()
