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

@onready var middle_area: HBoxContainer = $Shop

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

var player_angles: Array = [0.0, 0.0, 0.0, 0.0]
var active_boards: Array = []

# --- SECURITE D'ANIMATION ---
var currently_displayed_player = null
var is_game_initialized: bool = false
var is_rotating: bool = false
signal rotation_finished

# Overlays et Menus
@onready var turn_overlay: ColorRect = $TurnOverlay
@onready var lbl_turn_announcement: Label = %LblTurnAnnouncement

# On pointe vers les nouveaux noms dans le TurnOverlay
@onready var btn_overlay_roll_1: TextureButton = $TurnOverlay/VBoxContainer/HBoxContainer/Roll1Die
@onready var btn_overlay_roll_2: TextureButton = $TurnOverlay/VBoxContainer/HBoxContainer/Roll2Dices

var result_overlay: ColorRect
var die_1: TextureRect
var die_2: TextureRect
var btn_conserver: TextureButton
var btn_relancer: TextureButton
var btn_add_2: TextureButton # <-- Ajout de la variable pour ton nouveau bouton
var mini_dice_array: Array = []

var dice_textures = [
	preload("res://assets/UI/die_one.png"), preload("res://assets/UI/die_two.png"),
	preload("res://assets/UI/die_three.png"), preload("res://assets/UI/die_four.png"),
	preload("res://assets/UI/die_five.png"), preload("res://assets/UI/die_six.png")
]

@onready var monument_menu: ColorRect = %MonumentOverlay
@onready var close_menu: TextureButton = %closeButton # Utilise l'Unique Name que tu as défini
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
@onready var demolish_mÉpicerieonuments: HBoxContainer = %DemolishMonuments
@onready var btn_confirm_demolish: Button = %ConfirmDemolish
@onready var buy_confirm_panel: ColorRect = %ConfirmCardBuyPanel
@onready var card_preview: Control = %CardPreview
@onready var confirm_card_buy: Button = %ConfirmCardBuy
@onready var cancel_card_buy: Button = %CancelCardBuy
@onready var chalutier_panel: PanelContainer = %ChalutierPanel
@onready var lbl_chalutier_result: RichTextLabel = %LblChalutierResult
@onready var chalutier_roll: Button = %ChalutierRoll
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

const MONUMENT_SLOT_SCENE = preload("res://scene/table/MonumentSlot.tscn")

func _ready() -> void:
	shop_button.pressed.connect(_on_shop_button_pressed)
	shop_popup.shop_card_clicked.connect(_on_shop_card_clicked)
	if btn_overlay_roll_1: btn_overlay_roll_1.pressed.connect(_on_roll_1_pressed)
	if btn_overlay_roll_2: btn_overlay_roll_2.pressed.connect(_on_roll_2_pressed)
	
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
	# On relie les 3 boutons à notre signal texte
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
	
	
func _on_settings_pressed() -> void:
	settings_overlay.move_to_front()
	settings_overlay.show()
	
func _on_continue_pressed() -> void:
	settings_overlay.hide()
	
	

func _on_add_gold_pressed(amount: int) -> void:
	print("Gold button clicked with amount: ", amount)
	if current_player != null:
		current_player.balance = max(0, current_player.balance + amount)
		update_all_boards()

func _on_window_resized() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	
	if table_pivot:
		table_pivot.set_anchors_preset(Control.PRESET_FULL_RECT)
		table_pivot.size = screen_size
		table_pivot.pivot_offset = screen_size / 2.0
		table_pivot.position = Vector2.ZERO

	# Scale global sur mobile
	if OS.has_feature("android") or OS.has_feature("ios"):
		var ref_height = 600.0
		var global_scale = clamp(screen_size.y / ref_height, 0.3, 2.0)
		if table_pivot:
			table_pivot.scale = Vector2(global_scale, global_scale)
		if middle_area:
			middle_area.scale = Vector2(0.7, 0.7)
			middle_area.set_anchors_preset(Control.PRESET_CENTER)
			middle_area.reset_size()
			middle_area.pivot_offset = middle_area.size / 2.0
	else:
		if table_pivot:
			table_pivot.scale = Vector2(1.0, 1.0)

	if middle_area:
		middle_area.set_anchors_preset(Control.PRESET_CENTER)
		middle_area.add_theme_constant_override("separation", 20)
		middle_area.reset_size()
		middle_area.pivot_offset = middle_area.size / 2.0
		if not (OS.has_feature("android") or OS.has_feature("ios")):
			middle_area.scale = Vector2(0.8, 0.8)

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
	
	shop_popup.update_shop(test_shop)
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
	btn_add_2 = find_child("Ajouter2AuRésultat", true, false) # <-- Trouve ton nouveau bouton

func positionner_plateaux(animate: bool = true) -> void:
	if not game or game.playerCount == 0: return
	var active_idx = game.playerArray.find(current_player)
	if active_idx == -1: active_idx = 0

	var screen_size = get_viewport().get_visible_rect().size
	var c = screen_size / 2.0
	var margin = 40
	if OS.has_feature("android") or OS.has_feature("ios"):
		margin = 80

	var scale_factor = 1.0
	if OS.has_feature("android") or OS.has_feature("ios"):
		scale_factor = clamp(screen_size.y / 600.0, 0.3, 2.0)



	var tween = null
	
	if animate:
		for board in active_boards:
			if is_instance_valid(board) and board.has_method("set_ui_visible"):
				board.set_ui_visible(false)
				
		is_rotating = true
		set_actions_enabled(false)
		tween = get_tree().create_tween().set_parallel(true)
		tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	for p_idx in range(game.playerCount):
		var board = active_boards[p_idx]
		if not is_instance_valid(board): continue
		
		board.custom_minimum_size = Vector2(0, 0)
		board.reset_size()
		
		var real_size = board.size
		var b_h = real_size.y

		var rx = (screen_size.x / 2.0) - (b_h * scale_factor / 2.0) - margin
		var ry = (screen_size.y / 2.0) - (b_h * scale_factor / 2.0) - margin
		
		if OS.has_feature("android") or OS.has_feature("ios"):
			rx = rx * 0.60
		
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

		if OS.has_feature("android") or OS.has_feature("ios"):
			if diff == 0:
				board.scale = Vector2(1.0, 1.0)
			else:
				board.scale = Vector2(0.7, 0.7)

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
		rotation_finished.emit()

func waitForDiceRoll() -> int:
	# Masquage total avant l'annonce 
	for board in active_boards:
		if is_instance_valid(board) and board.has_method("set_ui_visible"):
			board.set_ui_visible(false)

	if is_rotating:
		await rotation_finished

	for d in mini_dice_array:
		if is_instance_valid(d): d.queue_free()
	mini_dice_array.clear()
	
	var nom = current_player.username
	var prefix = "Tour de "
	if ["A","E","I","O","U","Y"].has(nom[0].to_upper()): 
		prefix = "Tour d' "
		
	lbl_turn_announcement.text = prefix + nom
	
	# --- GESTION STRICTE DU BOUTON GARE ---
	var has_gare = false
	if current_player.has_method("monumentIsActive"):
		has_gare = current_player.monumentIsActive(Monument.MONUMENT_ID.Gare)
		
	if btn_overlay_roll_2:
		if has_gare:
			btn_overlay_roll_2.visible = true
			btn_overlay_roll_2.disabled = false
		else:
			# Cache TOTALEMENT le bouton pour ne pas prendre de place
			btn_overlay_roll_2.visible = false
			btn_overlay_roll_2.disabled = true
	# --------------------------------------
	
	turn_overlay.move_to_front()
	turn_overlay.show()
	set_actions_enabled(false) 
	
	var amount = await dice_amount_chosen
	turn_overlay.hide()
	
	# On retourne la valeur, l'UI reste masquée pour le moment (réapparaîtra dans showResult)
	return amount

func showResult(d1: int, d2: int, can_reroll: bool = false) -> String:
	var amount = 1 if d2 == 0 else 2
	
	var action = await play_dice_animation(amount, d1, d2, can_reroll)
	
	# On ne quitte direct que si on relance. "add2" et "keep" affichent le plateau.
	if action == "reroll":
		return action
	
	# --- RÉAPPARITION FINALE ---
	for board in active_boards:
		if is_instance_valid(board) and board.has_method("set_ui_visible"):
			board.set_ui_visible(true)
			board.setup(board.player, board.player == current_player)
	
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
	
	# --- 1. ROULEMENT DES DÉS (Aucun texte n'est affiché) ---
	var frames = 15
	var delay = 0.05 
	for i in range(frames):
		die_1.texture = dice_textures[randi() % 6]
		if amount == 2 and die_2: die_2.texture = dice_textures[randi() % 6]
		await get_tree().create_timer(delay).timeout
		if i > frames - 4: delay += 0.05 
		
	die_1.texture = dice_textures[final_d1 - 1]
	if amount == 2 and die_2: die_2.texture = dice_textures[final_d2 - 1]
	
	var total = final_d1 + final_d2
	var has_port = false
	if current_player and current_player.has_method("monumentIsActive"):
		has_port = current_player.monumentIsActive(Monument.MONUMENT_ID.Port)
		
	# On affiche juste les boutons de décision
	if btn_conserver: btn_conserver.show(); btn_conserver.disabled = false
	if btn_relancer: btn_relancer.visible = can_reroll; btn_relancer.disabled = false
	if btn_add_2: btn_add_2.visible = (has_port and total >= 10); btn_add_2.disabled = false
		
	var action = await dice_decision_made
	
	if action == "reroll":
		result_overlay.hide()
		return action 
	
	# --- 2. DÉCOLLAGE DES DÉS ---
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
	var base_local_pos = Vector2(-105, 7)
	var ecart_entre_des = 45 
	
	var target_local_pos_1 = base_local_pos
	var target_local_pos_2 = Vector2.ZERO 
	
	var addTwo_lbl = Label.new()
	var result_lbl = Label.new()
	
	var espace_a_droite_des_des = 40
		
	result_lbl.add_theme_font_size_override("font_size", 34) 
	addTwo_lbl.add_theme_font_size_override("font_size", 34)
	if FileAccess.file_exists("res://assets/Fonts/Exo_2/static/Exo2-BlackItalic.ttf"):
		result_lbl.add_theme_font_override("font", load("res://assets/Fonts/Exo_2/static/Exo2-BlackItalic.ttf"))
		addTwo_lbl.add_theme_font_override("font", load("res://assets/Fonts/Exo_2/static/Exo2-BlackItalic.ttf"))
	
	if action == "add2":
		total += 2
		base_local_pos += Vector2(-45,0)
		addTwo_lbl.text = " + 2 "
		addTwo_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0)) # Doré pour le bonus

	result_lbl.text += " = " + str(total)
	result_lbl.add_theme_color_override("font_color", Color.WHITE) # Blanc normal
	
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
		
	# On attend sagement que les dés atterrissent
	await tween.finished
	
	# --- 3. APPARITION DU TEXTE ("= X") UNIQUEMENT ICI ---

	if action == "add2":
		target_btn.add_child(addTwo_lbl)
		addTwo_lbl.position = base_local_pos + Vector2(espace_a_droite_des_des-5, -5)
		base_local_pos += Vector2(50, 0)
	
	target_btn.add_child(result_lbl)
	
	# Positionnement : On décale le texte vers la droite en fonction de `espace_a_droite_des_des`

	result_lbl.position = base_local_pos + Vector2(espace_a_droite_des_des, -5)
	
	# Apparition douce en fondu
	result_lbl.modulate.a = 0.0
	var fade_tween = get_tree().create_tween()
	fade_tween.tween_property(result_lbl, "modulate:a", 1.0, 0.2)
	if action == "add2":
		fade_tween.tween_property(addTwo_lbl, "modulate:a", 1.0, 0.2)
		
	
	# On ajoute le texte à l'array pour qu'il soit détruit au tour suivant
	mini_dice_array.append(result_lbl) 
	if action == "add2":
			mini_dice_array.append(addTwo_lbl) 
	
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
	
	# Mapping précis : ID -> Nom du Noeud -> Nom de l'image (sans _verso/_recto)
	var monument_map = {
		Monument.MONUMENT_ID.Port: {"node": "Port", "file": "PORT"},
		Monument.MONUMENT_ID.Gare: {"node": "Gare", "file": "Gare"},
		Monument.MONUMENT_ID.Centre_Commercial: {"node": "Centre commercial", "file": "Centre_commercial"},
		Monument.MONUMENT_ID.Parc: {"node": "Parc d'attraction", "file": "PARC_DATTRACTION"},
		Monument.MONUMENT_ID.Radio: {"node": "Tour radio", "file": "TOUR_RADIO"},
		Monument.MONUMENT_ID.Aeroport: {"node": "Aéroport", "file": "Aéroport"}
	}
	
	for m_id in monument_map:
		var data = monument_map[m_id]
		var vbox = cards_monuments_container.get_node_or_null(data["node"])
		if not vbox: continue
		
		var tex_rect: TextureRect = vbox.get_child(0)
		var build_btn: TextureButton = vbox.get_child(1)
		
		var is_built = target_player.monumentIsActive(m_id)
		
		# --- GESTION DU VISUEL (Recto/Verso) ---
		# Respecte la casse de tes fichiers (ex: PORT_VERSO.png vs Gare_verso.png)
		var state = ""
		if data["file"] == data["file"].to_upper():
			state = "RECTO" if is_built else "VERSO"
		else:
			state = "recto" if is_built else "verso"
			
		var tex_path = "res://assets/Cards/Monuments/" + data["file"] + "_" + state + ".png"
		
		if FileAccess.file_exists(tex_path):
			tex_rect.texture = load(tex_path)
			
		# --- GESTION DU BOUTON (Achat direct) ---
		for conn in build_btn.pressed.get_connections():
			build_btn.pressed.disconnect(conn.callable)
			
		if is_demolish_mode:
			build_btn.visible = is_built
			build_btn.pressed.connect(func(): demolish_completed.emit(m_id))
		else:
			build_btn.visible = not is_built 
			
			# ACHAT DIRECT SANS OVERLAY
			build_btn.pressed.connect(func():
				monument_menu.hide() # Ferme le menu des monuments
				action_selected.emit([game.CHOICE.Build_MONUMENT, m_id]) # Déclenche l'achat dans la logique
			)
		
func _on_construct_clicked(m_id):
	_on_shop_card_clicked(m_id) 
	
	%ConfirmCardBuy.text = "CONSTRUIRE"

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
			if FileAccess.file_exists(avatar_path):
				profile_tex.texture = load(avatar_path)
				
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
	btn_confirm_trade.text = "Sélectionnez les cartes à échanger"
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
			btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN # <--- ADD THIS
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
			if FileAccess.file_exists(avatar_path):
				profile_tex.texture = load(avatar_path)
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
						child.modulate = Color(0.4, 0.4, 0.4)
						child.scale = Vector2(0.9, 0.9)
					else:
						child.modulate = Color(1.0, 1.0, 1.0)
						child.scale = Vector2(1.0, 1.0)
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
			card_btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN # <--- ADD THIS
			card_btn.pivot_offset = Vector2(65, 90)
			
			card_btn.ignore_texture_size = true
			card_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			
			var clean_name = get_clean_file_name(card.name, card.color)
			var path = "res://assets/Cards/Basis/" + clean_name + "_1.png"
			if FileAccess.file_exists(path):
				card_btn.texture_normal = load(path)
			
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
			
			card_btn.mouse_entered.connect(func(): outline.add_theme_stylebox_override("panel", hover_style))
			card_btn.mouse_exited.connect(func(): outline.add_theme_stylebox_override("panel", style))
			
			card_btn.pressed.connect(func():
				if is_mine: trade_my_card_id = card_id
				else: trade_their_card_id = card_id
				
				_check_trade_valid()
				
				for child in container.get_children():
					if child == card_btn:
						child.modulate = Color(0.4, 0.4, 0.4)
						child.scale = Vector2(0.9, 0.9)
					else:
						child.modulate = Color(1.0, 1.0, 1.0)
						child.scale = Vector2(1.0, 1.0)
			)
			
			container.add_child(card_btn)

func _check_trade_valid() -> void:
	if trade_target != null and trade_their_card_id != -1 and trade_my_card_id != -1:
		btn_confirm_trade.disabled = false
		btn_confirm_trade.text = "Confirmer!"

func _on_confirm_trade_pressed() -> void: trade_completed.emit([trade_my_card_id, trade_target, trade_their_card_id])

func ask_give_card(owner_player, all_players: Array) -> Array:
	give_panel.move_to_front()
	give_panel.show()
	btn_confirm_give.disabled = true
	btn_confirm_give.text = "Sélectionnez une carte et un adversaire"
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
			var path = "res://assets/Cards/Basis/" + clean_name + "_1.png"
			if FileAccess.file_exists(path):
				card_btn.texture_normal = load(path)
			
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
			
			card_btn.mouse_entered.connect(func(): outline.add_theme_stylebox_override("panel", hover_style))
			card_btn.mouse_exited.connect(func(): outline.add_theme_stylebox_override("panel", style))
			
			card_btn.pressed.connect(func():
				give_card_id = card_id
				_check_give_valid()
				
				for child in give_my_cards.get_children():
					if child == card_btn:
						child.modulate = Color(0.4, 0.4, 0.4)
						child.scale = Vector2(0.9, 0.9)
					else:
						child.modulate = Color(1.0, 1.0, 1.0)
						child.scale = Vector2(1.0, 1.0)
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
			if FileAccess.file_exists(avatar_path):
				profile_tex.texture = load(avatar_path)
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
						child.modulate = Color(0.4, 0.4, 0.4)
						child.scale = Vector2(0.9, 0.9)
					else:
						child.modulate = Color(1.0, 1.0, 1.0)
						child.scale = Vector2(1.0, 1.0)
			)
			give_opponents.add_child(btn)

	var result = await give_card_completed
	give_panel.hide()
	return result

func _check_give_valid() -> void:
	if give_target != null and give_card_id != -1:
		btn_confirm_give.disabled = false
		btn_confirm_give.text = "Confirmer"

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
	
	for child in %CardPreview.get_children(): 
		child.queue_free()
		
	if card_data != null:
		const CARD_SCENE = preload("res://scene/table/card_animation.tscn")
		var preview_card = CARD_SCENE.instantiate()
		
		var card_name = card_data.get_name()
		var clean_name = ""
		var path_basis = ""
		var tip_path = ""
		
		if card_data is Monument:
			clean_name = get_clean_file_name(card_name)
			path_basis = "res://assets/Cards/Monuments/monument_" + clean_name + "_active.png"
		else:
			var card_color = card_data.get_color()
			clean_name = get_clean_file_name(card_name, card_color)
			path_basis = "res://assets/Cards/Basis/" + clean_name + "_1.png"
			tip_path = "res://assets/Tooltips/tooltip_" + clean_name + "_top.png"
		
		var image_node = preview_card.get_node_or_null("Visual")
		
		if image_node and image_node is TextureButton:
			var tex = load(path_basis)
			if tex:
				image_node.texture_normal = tex
		
			image_node.disabled = true
			image_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
			image_node.ignore_texture_size = false
			image_node.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

		var screen = get_viewport().get_visible_rect().size
		var preview_w = screen.x * 0.18
		var preview_h = preview_w * 1.28
		preview_card.custom_minimum_size = Vector2(preview_w, preview_h)
		preview_card.size = Vector2(preview_w, preview_h)
		%CardPreview.custom_minimum_size = Vector2(preview_w, preview_h)
		%TooltipImage.custom_minimum_size = Vector2(preview_w, preview_w * 0.6)

		var internal_tooltip = preview_card.get_node_or_null("Visual/Tooltip")
		if internal_tooltip:
			internal_tooltip.hide()

		%CardPreview.add_child(preview_card)

		var placeholder_path = "res://assets/Tooltips/tooltip_vert_marché_fruit_et_légume_top.png"

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
	buy_confirm_panel.hide()
	
	if game and game.CHOICE:
		var card_data = CardFactory.get_card(selected_shop_card_id)
		
		if card_data is Monument:
			monument_menu.hide() 
			
			action_selected.emit([game.CHOICE.Build_MONUMENT, selected_shop_card_id])
		else:
			action_selected.emit([game.CHOICE.Build_ESTABLISHMENT, selected_shop_card_id])

func _on_cancel_buy_shop_pressed() -> void:
	selected_shop_card_id = -1
	buy_confirm_panel.hide()

func ask_chalutier_roll(player_name: String) -> int:
	while turn_overlay.visible or result_overlay.visible:
		await get_tree().create_timer(0.1).timeout

	lbl_turn_announcement.text = "Chalutier de " + player_name
	
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
	result_title.text = "Prise de " + player_name + "!"
	
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
	btn_rtlabel.text ="[center][font=res://assets/Fonts/Exo_2/static/Exo2-BlackItalic.ttf][font_size=48]Récupérer [color=gold]" + str(total) + "[/color] [img=48]" + icon_path + "[/img][/font_size][/font][/center]"
	
	btn_vbox.add_child(btn_rtlabel)
	
	var result_vbox = result_overlay.get_node("VBoxContainer")
	result_vbox.add_child(claim_btn)
	
	await claim_btn.pressed
	
	claim_btn.queue_free() 
	result_overlay.hide()
	result_title.text = "Résultat du lancer" 
	
	return total

func show_victory_screen(winner_name: String) -> void:
	set_actions_enabled(false)
	lbl_winner_name.text = "🏆 " + winner_name + " GAGNE!"
	victory_screen.move_to_front()
	victory_screen.show()
	
func _on_quit_pressed() -> void: get_tree().change_scene_to_file("res://scene/Ecran principale/accueil.tscn")



func _unhandled_key_input(event: InputEvent) -> void:
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
