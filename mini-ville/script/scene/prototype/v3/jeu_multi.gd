extends Node

# --- GESTION RESEAU ---
var network_client: GameClient
var my_player_id: int
var latest_players_data: Dictionary = {}
var latest_shop_data: Dictionary = {}
var player_board_map: Dictionary = {}  # {player_id_str: board_node}

signal dice_amount_chosen(amount: int)
signal yes_no_answered(result: bool)
signal player_chosen(target_id: int)
signal trade_completed(trade_data: Array)
signal give_card_completed(give_data: Array)
signal demolish_completed(monu_id: int)
signal dice_decision_made(action: String)
signal rotation_finished

@onready var middle_area: HBoxContainer = $Shop
@onready var table_pivot: Control = $TablePivot
@onready var boards: Array = [$TablePivot/BoardJoueurBas, $TablePivot/BoardJoueurGauche, $TablePivot/BoardJoueurHaut, $TablePivot/BoardJoueurDroite]
@onready var shop_board = %ShopBoard
var active_boards: Array = []

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

# Popups
@onready var monument_menu: ColorRect = %MonumentOverlay
@onready var close_menu: Button = %CloseButton 
@onready var cards_monuments_container = $MonumentOverlay/MainContainer/CardsMonumentsContainer
@onready var victory_screen: ColorRect = $VictoryScreen
@onready var lbl_winner_name: Label = %LblWinnerName
@onready var choose_player_panel: ColorRect = $ChoosePlayerPanel
@onready var player_buttons_container: HBoxContainer = %PlayerButtonsContainer
@onready var trade_panel: ColorRect = $TradePanel
@onready var trade_opponents: HBoxContainer = %TradeOpponents
@onready var trade_their_cards: HFlowContainer = %TradeTheirCards
@onready var trade_my_cards: HFlowContainer = %TradeMyCards
@onready var btn_confirm_trade: Button = %ConfirmTrade
@onready var give_panel: ColorRect = $GiveCardPanel
@onready var give_my_cards: HFlowContainer = %GiveMyCards
@onready var give_opponents: HBoxContainer = %GiveOpponents
@onready var btn_confirm_give: Button = %ConfirmGive
@onready var buy_confirm_panel: ColorRect = %ConfirmCardBuyPanel
@onready var confirm_card_buy: Button = %ConfirmCardBuy
@onready var cancel_card_buy: Button = %CancelCardBuy

@onready var settings_button: Button = %Settings
@onready var settings_overlay: ColorRect = %SettingsOverlay
@onready var continue_button: Button = %Continuer
@onready var main_menu_button: Button = %MenuPrincipale
@onready var settings_quit_button: Button = %Quitter

# Variables de stockage temporaire pour les popups
var trade_target_id: int = -1
var trade_their_card_id: int = -1
var trade_my_card_id: int = -1
var give_target_id: int = -1
var give_card_id: int = -1
var selected_shop_card_id: int = -1

func _ready() -> void:
	print(">>> JeuMulti _ready() called!")
	network_client = get_node("/root/Game_Client")
	network_client.gameplayScreen = self
	
	my_player_id = NetworkManager.get_joueur_id()
	network_client.my_player_id = my_player_id
	
	_find_dice_ui_nodes()
	_force_overlays_to_front()
	
	if btn_overlay_roll_1: btn_overlay_roll_1.pressed.connect(func(): network_client.request_roll_dice(1))
	if btn_overlay_roll_2: btn_overlay_roll_2.pressed.connect(func(): network_client.request_roll_dice(2))
	
	%CancelCardBuy.pressed.connect(func(): buy_confirm_panel.hide())
	close_menu.pressed.connect(func(): monument_menu.hide())
	
	if btn_conserver: btn_conserver.pressed.connect(func(): dice_decision_made.emit("keep"))
	if btn_relancer: btn_relancer.pressed.connect(func(): dice_decision_made.emit("reroll"))
	if btn_add_2: btn_add_2.pressed.connect(func(): dice_decision_made.emit("add2"))
	
	if settings_button: settings_button.pressed.connect(func(): settings_overlay.show())
	if continue_button: continue_button.pressed.connect(func(): settings_overlay.hide())
	if main_menu_button: main_menu_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scene/Ecran principale/accueil.tscn"))
	if settings_quit_button: settings_quit_button.pressed.connect(func(): get_tree().quit())
	
	%ConfirmTrade.pressed.connect(func(): trade_completed.emit([trade_my_card_id, trade_target_id, trade_their_card_id]))
	%ConfirmGive.pressed.connect(func(): give_card_completed.emit([give_card_id, give_target_id]))
	
	for board in boards:
		if is_instance_valid(board):
			board.pass_turn_requested.connect(func(): network_client.request_skip_turn())
			board.open_monuments_requested.connect(_on_open_monuments_pressed)
			
		
	if is_instance_valid(shop_board): shop_board.shop_card_clicked.connect(_on_shop_card_clicked)
	%ConfirmCardBuy.pressed.connect(_on_confirm_buy_shop_pressed)

	get_viewport().size_changed.connect(_on_window_resized)
	_on_window_resized.call_deferred()

	NetworkManager.message_recu.connect(_on_network_message)

	await get_tree().process_frame
	network_client.current_lobby_id = LobbyHandler.get_lobby_id()

	if not network_client.cached_sync_data.is_empty():
		print(">>> DEBUG: Applying cached game state!")
		var cached = network_client.cached_sync_data.duplicate()
		network_client.cached_sync_data.clear()
		_on_network_message(cached)

	if not network_client.cached_turn_data.is_empty():
		var cached_turn = network_client.cached_turn_data.duplicate()
		network_client.cached_turn_data.clear()
		network_client._handle_turn_started(cached_turn)

func set_actions_enabled(can_act: bool) -> void:
	for board in boards:
		if is_instance_valid(board): board.set_actions_enabled(can_act)
	if is_instance_valid(shop_board): shop_board.set_actions_enabled(can_act)

func update_network_boards(players_data: Dictionary):
	print("[JeuMulti] update_network_boards called with ", players_data.size(), " players")
	latest_players_data = players_data

	var player_ids = players_data.keys()
	var my_id_str = str(my_player_id)

	if player_ids.has(my_id_str):
		player_ids.erase(my_id_str)
		player_ids.push_front(my_id_str)

	active_boards.clear()
	var p_count = player_ids.size()
	if p_count == 2:
		active_boards = [boards[0], boards[2]]
	elif p_count == 3:
		active_boards = [boards[0], boards[1], boards[2]]
	else:
		active_boards = boards.duplicate()

	for b in boards:
		b.hide()

	player_board_map.clear()
	for i in range(p_count):
		if i < active_boards.size():
			var board = active_boards[i]
			var p_id = player_ids[i]
			var data = players_data[p_id]

			player_board_map[p_id] = board
			board.show()

			if board.has_method("setup_network"):
				var is_me = (p_id == my_id_str)
				board.setup_network(data, is_me)

	# Use call_deferred instead of await so this function is NOT a coroutine.
	# Awaiting here caused re-entry: a second sync_state arriving during the await
	# would call update_network_boards again, freeing all animating card nodes
	# before they rendered a single frame.
	positionner_plateaux.call_deferred()

func update_network_shop(shop_data: Dictionary):
	latest_shop_data = shop_data

	if not is_instance_valid(shop_board): return

	# Smart diff update — returns {new_card_id: target_position} using the
	# removed card's stable pre-free global_position as the animation target.
	var position_map: Dictionary = shop_board.update_network_shop(shop_data)

	for card_id in position_map:
		var target_pos: Vector2 = position_map[card_id]
		var target_slot = shop_board.card_slot_map.get(card_id)
		if not is_instance_valid(target_slot): continue

		# Read the texture that ShopBoard already loaded into the visual node.
		# This avoids duplicating the asset-path logic (which changed after the merge).
		var image_node = target_slot.get_node_or_null("Visual")
		var tex: Texture2D = null
		if image_node is TextureButton:
			tex = image_node.texture_normal

		if tex:
			animer_pioche_vers_shop(target_slot, tex, target_pos)
		else:
			# No texture available — reveal the slot immediately without animation.
			target_slot.modulate.a = 1.0

func show_victory_screen(winner_name: String) -> void:
	set_actions_enabled(false)
	lbl_winner_name.text = "🏆 " + winner_name + " " + tr("GAGNE!")
	victory_screen.move_to_front()
	victory_screen.show()

func _on_shop_card_clicked(card_id: int) -> void:
	selected_shop_card_id = card_id
	var card_data = CardFactory.get_card(card_id)

	for child in %CardPreview.get_children():
		child.queue_free()

	if card_data != null:
		const CARD_SCENE = preload("res://scene/table/card_animation.tscn")
		var preview_card = CARD_SCENE.instantiate()

		var card_name = card_data.get_name()
		var path_basis = ""
		var tip_path = ""

		if card_data is Monument:
			var clean_name = get_clean_file_name(card_name)
			path_basis = "res://assets/Cards/Monuments/monument_" + clean_name + "_active.png"
		else:
			var card_color = card_data.get_color()
			var clean_name = get_clean_file_name(card_name, card_color)
			path_basis = "res://assets/Cards/" + get_lang_folder() + "/Establishments/" + clean_name + "_1.png"
			tip_path = "res://assets/Tooltips/" + get_lang_folder() + "/tooltip_" + clean_name + ".png"

		var image_node = preview_card.get_node_or_null("Visual")
		if image_node and image_node is TextureButton:
			var _tex = load(path_basis)
			if _tex:
				image_node.texture_normal = _tex
			image_node.disabled = true
			image_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
			image_node.ignore_texture_size = true
			image_node.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

		var internal_tooltip = preview_card.get_node_or_null("Visual/Tooltip")
		if internal_tooltip:
			internal_tooltip.hide()

		%CardPreview.add_child(preview_card)
		# Fill the CardPreview TextureRect entirely — overrides the scene's anchor/offset
		# defaults (offset_right=40 → 40px wide) that cause the card to appear undersized.
		preview_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

		if tip_path != "":
			var _tip_tex = load(tip_path)
			if _tip_tex:
				%TooltipImage.texture = _tip_tex
				%TooltipImage.show()
			else:
				%TooltipImage.hide()
		else:
			%TooltipImage.hide()

	buy_confirm_panel.move_to_front()
	buy_confirm_panel.show()
		
		
func _on_confirm_buy_shop_pressed() -> void:
	buy_confirm_panel.hide()
	monument_menu.hide()

	var card_data = CardFactory.get_card(selected_shop_card_id)
	if card_data is Monument:
		network_client.request_build_monument(selected_shop_card_id)
	else:
		# Fire the fly-to-hand animation immediately (optimistic visual).
		# Read quantity from the cached shop data — the badge node name changed
		# after the merge and is no longer a reliable source.
		var qty_in_shop = int(latest_shop_data.get(str(selected_shop_card_id), 1))
		animer_achat_vers_main(selected_shop_card_id, qty_in_shop)
		network_client.request_buy_card(selected_shop_card_id)

func _on_open_monuments_pressed() -> void:
	update_monument_menu()
	monument_menu.move_to_front()
	monument_menu.show()
	
	
func showResult(d1: int, d2: int, can_reroll: bool = false, spectator: bool = false) -> String:
	var amount = 1 if d2 == 0 else 2
	var action = await play_dice_animation_enhanced(amount, d1, d2, can_reroll, spectator)
	return action
	

func play_dice_animation(amount: int, final_d1: int, final_d2: int = 0, can_reroll: bool = false, spectator: bool = false) -> String:
	result_overlay.move_to_front()
	result_overlay.show()
	
	if btn_conserver: btn_conserver.hide()
	if btn_relancer: btn_relancer.hide()
	if btn_add_2: btn_add_2.hide()
	
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
	
	if spectator:
		await get_tree().create_timer(2.0).timeout
		result_overlay.hide()
		return "keep"
	
	var total = final_d1 + final_d2
	if btn_conserver: btn_conserver.show(); btn_conserver.disabled = false
	if btn_relancer: btn_relancer.visible = can_reroll; btn_relancer.disabled = false
	if btn_add_2: btn_add_2.visible = (total >= 10); btn_add_2.disabled = false
	
	var action = await dice_decision_made
	
	if action == "reroll":
		result_overlay.hide()
		return action
	
	result_overlay.hide()
	return action

func ask_choose_player() -> int:
	choose_player_panel.move_to_front()
	choose_player_panel.show()
	for child in player_buttons_container.get_children(): child.queue_free()
	
	for p_id_str in latest_players_data:
		var p_id = int(p_id_str)
		if p_id == my_player_id: continue
		var data = latest_players_data[p_id_str]
		
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
		var _avatar_tex = load("res://assets/UI/profile_picture_player.png")
		if _avatar_tex: profile_tex.texture = _avatar_tex
		vbox.add_child(profile_tex)
		
		var name_label = RichTextLabel.new()
		name_label.bbcode_enabled = true
		name_label.fit_content = true
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_label.custom_minimum_size = Vector2(120, 40)
		var icon_path = "res://assets/UI/coin.png"
		name_label.text = "[center]" + data.get("username", "Joueur " + str(p_id)) + "\n[color=gold]" + str(data.get("balance", 0)) + "[/color] [img=13]" + icon_path + "[/img][/center]"
		vbox.add_child(name_label)
		
		btn.pressed.connect(func(): player_chosen.emit(p_id))
		player_buttons_container.add_child(btn)
	
	var chosen_target_id = await player_chosen
	choose_player_panel.hide()
	return chosen_target_id

func ask_trade_cards() -> Array:
	trade_panel.move_to_front()
	trade_panel.show()
	trade_opponents.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	trade_my_cards.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	trade_their_cards.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	btn_confirm_trade.disabled = true
	btn_confirm_trade.text = tr("Sélectionnez les cartes à échanger")
	trade_target_id = -1
	trade_their_card_id = -1
	trade_my_card_id = -1
	
	for c in trade_opponents.get_children(): c.queue_free()
	for c in trade_my_cards.get_children(): c.queue_free()
	for c in trade_their_cards.get_children(): c.queue_free()
	
	for p_id_str in latest_players_data:
		var p_id = int(p_id_str)
		if p_id == my_player_id: continue
		var data = latest_players_data[p_id_str]
		
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
		var _avatar_tex = load("res://assets/UI/profile_picture_player.png")
		if _avatar_tex: profile_tex.texture = _avatar_tex
		vbox.add_child(profile_tex)
		
		var name_label = RichTextLabel.new()
		name_label.bbcode_enabled = true
		name_label.fit_content = true
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_label.custom_minimum_size = Vector2(120, 40)
		var icon_path = "res://assets/UI/coin.png"
		name_label.text = "[center]" + data.get("username", "Joueur " + str(p_id)) + "\n[color=gold]" + str(data.get("balance", 0)) + "[/color] [img=13]" + icon_path + "[/img][/center]"
		vbox.add_child(name_label)
		
		btn.pressed.connect(func():
			_on_trade_opponent_selected(p_id, data)
			for child in trade_opponents.get_children():
				if child == btn:
					child.modulate = Color(0.4, 0.4, 0.4)
					child.scale = Vector2(0.9, 0.9)
				else:
					child.modulate = Color(1.0, 1.0, 1.0)
					child.scale = Vector2(1.0, 1.0)
		)
		trade_opponents.add_child(btn)
	
	_populate_trade_deck(latest_players_data[str(my_player_id)].get("deck", []), trade_my_cards, true)
	
	var result = await trade_completed
	trade_panel.hide()
	return result

func _on_trade_opponent_selected(target_id: int, data: Dictionary) -> void:
	trade_target_id = target_id
	_populate_trade_deck(data.get("deck", []), trade_their_cards, false)

func _populate_trade_deck(deck: Array, container: Container, is_mine: bool) -> void:
	for c in container.get_children(): c.queue_free()
	
	for instance in deck:
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
			var path = "res://assets/Cards/" + get_lang_folder() + "/Establishments/" + clean_name + "_1.png"
			var _card_tex = load(path)
			if _card_tex: card_btn.texture_normal = _card_tex
			
			var outline = Panel.new()
			outline.set_anchors_preset(Control.PRESET_FULL_RECT)
			outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card_btn.add_child(outline)
			
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0, 0, 0, 0)
			style.set_border_width_all(3)
			style.set_corner_radius_all(8)
			match card.color:
				CardColor.Type.BLUE:  style.border_color = Color(0.2, 0.4, 0.8, 0.8)
				CardColor.Type.GREEN: style.border_color = Color(0.2, 0.6, 0.2, 0.8)
				CardColor.Type.RED:   style.border_color = Color(0.8, 0.2, 0.2, 0.8)
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

func ask_give_card() -> Array:
	give_panel.move_to_front()
	give_panel.show()
	btn_confirm_give.disabled = true
	btn_confirm_give.text = tr("Sélectionnez une carte et un adversaire")
	give_target_id = -1
	give_card_id = -1
	
	for c in give_my_cards.get_children(): c.queue_free()
	for c in give_opponents.get_children(): c.queue_free()
	
	var my_deck = latest_players_data.get(str(my_player_id), {}).get("deck", [])
	for instance in my_deck:
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
			var path = "res://assets/Cards/" + get_lang_folder() + "/Establishments/" + clean_name + "_1.png"
			var _card_tex = load(path)
			if _card_tex: card_btn.texture_normal = _card_tex
			
			var outline = Panel.new()
			outline.set_anchors_preset(Control.PRESET_FULL_RECT)
			outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card_btn.add_child(outline)
			
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0, 0, 0, 0)
			style.set_border_width_all(3)
			style.set_corner_radius_all(8)
			match card.color:
				CardColor.Type.BLUE:  style.border_color = Color(0.2, 0.4, 0.8, 0.8)
				CardColor.Type.GREEN: style.border_color = Color(0.2, 0.6, 0.2, 0.8)
				CardColor.Type.RED:   style.border_color = Color(0.8, 0.2, 0.2, 0.8)
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
	
	for p_id_str in latest_players_data:
		var p_id = int(p_id_str)
		if p_id == my_player_id: continue
		var data = latest_players_data[p_id_str]
		
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
		var _avatar_tex = load("res://assets/UI/profile_picture_player.png")
		if _avatar_tex: profile_tex.texture = _avatar_tex
		vbox.add_child(profile_tex)
		
		var name_label = RichTextLabel.new()
		name_label.bbcode_enabled = true
		name_label.fit_content = true
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_label.custom_minimum_size = Vector2(120, 40)
		var icon_path = "res://assets/UI/coin.png"
		name_label.text = "[center]" + data.get("username", "Joueur " + str(p_id)) + "\n[color=gold]" + str(data.get("balance", 0)) + "[/color] [img=13]" + icon_path + "[/img][/center]"
		vbox.add_child(name_label)
		
		btn.pressed.connect(func():
			give_target_id = p_id
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
	if give_target_id != -1 and give_card_id != -1:
		btn_confirm_give.disabled = false
		btn_confirm_give.text = tr("Confirmer")

func ask_demolish_monument() -> int:
	monument_menu.move_to_front()
	monument_menu.show()
	var result = await demolish_completed
	monument_menu.hide()
	return result

func _find_dice_ui_nodes() -> void:
	result_overlay = %ResultOverlay
	die_1 = %Die1
	die_2 = %Die2
	btn_conserver = find_child("ConserverLeRésultat", true, false)
	btn_relancer = find_child("RefaireLeLancer", true, false)
	btn_add_2 = find_child("Ajouter2AuRésultat", true, false)

func _force_overlays_to_front() -> void:
	var overlays = [turn_overlay, result_overlay, monument_menu, victory_screen, choose_player_panel, trade_panel, give_panel, buy_confirm_panel]
	for overlay in overlays:
		if is_instance_valid(overlay): overlay.z_index = 100 

func _on_window_resized() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	if table_pivot:
		table_pivot.set_anchors_preset(Control.PRESET_FULL_RECT)
		table_pivot.size = screen_size
		table_pivot.pivot_offset = screen_size / 2.0
		table_pivot.position = Vector2.ZERO
		
func positionner_plateaux() -> void:
	var active_count = latest_players_data.size()
	
	if active_count == 0: 
		return

	var screen_size = get_viewport().get_visible_rect().size
	var c = screen_size / 2.0
	var margin = 40

	for p_idx in range(active_count):
		if p_idx >= active_boards.size(): continue
		
		var board = active_boards[p_idx] 
		
		if not is_instance_valid(board): continue

		var real_size = board.size
		if real_size.x < 10 or real_size.y < 10:
			real_size = Vector2(818, 264)
		var b_h = real_size.y
		
		var rx = (screen_size.x / 2.0) - (b_h / 2.0) - margin
		var ry = (screen_size.y / 2.0) - (b_h / 2.0) - margin
		
		board.pivot_offset = real_size / 2.0

		var target_angle = 0.0 
		var target_rot = 0.0   

		if active_count == 2:
			if p_idx == 0: target_angle = PI/2.0; target_rot = 0.0
			elif p_idx == 1: target_angle = -PI/2.0; target_rot = PI
		elif active_count == 3:
			if p_idx == 0: target_angle = PI/2.0; target_rot = 0.0
			elif p_idx == 1: target_angle = PI; target_rot = PI/2.0
			elif p_idx == 2: target_angle = -PI/2.0; target_rot = PI
		else:
			if p_idx == 0: target_angle = PI/2.0; target_rot = 0.0
			elif p_idx == 1: target_angle = PI; target_rot = PI/2.0
			elif p_idx == 2: target_angle = -PI/2.0; target_rot = PI
			elif p_idx == 3: target_angle = 0.0; target_rot = -PI/2.0

		var target_center = c + Vector2(cos(target_angle)*rx, sin(target_angle)*ry)
		board.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		board.position = target_center - board.pivot_offset
		board.rotation = target_rot
		
		print(">>> Board ", p_idx, " → pos: ", board.position, " rot: ", board.rotation, " size: ", real_size)
		
		
func _on_network_message(data: Dictionary) -> void:
	print("[JeuMulti] _on_network_message: ", data.get("action_reply", "?"))
	var action = data.get("action_reply", "")
	print("[JeuMulti] Message reçu : ", action)
	match action:
		"sync_state":
			print("[JeuMulti] sync_state — ", data.get("players", {}).keys().size(), " joueur(s)")
			var new_players = data.get("players", {})
			_trigger_gold_animations(new_players)     # diff balances BEFORE updating
			_trigger_card_move_animations(new_players) # diff decks BEFORE updating
			update_network_boards(new_players)
			update_network_shop(data.get("shop", {}))
		"buy_error":
			# Server rejected the purchase
			if is_instance_valid(shop_board) and shop_board.get("last_clicked_slot"):
				animer_erreur_carte_shop(shop_board.last_clicked_slot)
			var my_board: PlayerBoard = player_board_map.get(str(my_player_id), null)
			if is_instance_valid(my_board):
				animer_erreur_argent(my_board)
		"game_over":
			show_victory_screen(data.get("winner_name", "Un joueur"))

func get_clean_file_name(card_name: String, color: int = -1) -> String:
	var prefix = ""
	match color:
		CardColor.Type.BLUE: prefix = "bleu_"
		CardColor.Type.GREEN: prefix = "vert_"
		CardColor.Type.RED: prefix = "rouge_"
		CardColor.Type.PURPLE: prefix = "violet_"
	var clean_name = card_name.to_lower().replace(" ", "_").replace("'", "_")
	clean_name = clean_name.replace("é", "e").replace("è", "e").replace("à", "a")
	return prefix + clean_name

func get_lang_folder() -> String:
	if TranslationServer.get_locale().begins_with("en"):
		return "English"
	return "French"

func update_monument_menu():
	var my_data = latest_players_data.get(str(my_player_id), {})
	var my_monuments = my_data.get("monuments", {})

	var monument_map = {
		Monument.MONUMENT_ID.Port:             {"node": "Port",              "file": "PORT"},
		Monument.MONUMENT_ID.Gare:             {"node": "Gare",              "file": "Gare"},
		Monument.MONUMENT_ID.Centre_Commercial:{"node": "Centre commercial", "file": "Centre_commercial"},
		Monument.MONUMENT_ID.Parc:             {"node": "Parc d'attraction", "file": "PARC_DATTRACTION"},
		Monument.MONUMENT_ID.Radio:            {"node": "Tour radio",        "file": "TOUR_RADIO"},
		Monument.MONUMENT_ID.Aeroport:         {"node": "Aéroport",          "file": "Aéroport"}
	}
	
	for m_id in monument_map:
		var data = monument_map[m_id]
		var vbox = cards_monuments_container.get_node_or_null(data["node"])
		if not vbox: continue
		
		var tex_rect: TextureRect = vbox.get_child(0)
		var build_btn: TextureButton = vbox.get_child(1)
		
		var is_built = my_monuments.get(m_id, false) or my_monuments.get(str(m_id), false)
		
		var state = ""
		if data["file"] == data["file"].to_upper():
			state = "RECTO" if is_built else "VERSO"
		else:
			state = "recto" if is_built else "verso"
			
		var tex_path = "res://assets/Cards/Monuments/" + data["file"] + "_" + state + ".png"
		var _tex = load(tex_path)
		if _tex: tex_rect.texture = _tex

		for conn in build_btn.pressed.get_connections():
			build_btn.pressed.disconnect(conn.callable)

		build_btn.visible = not is_built
		build_btn.pressed.connect(func():
			monument_menu.hide()
			network_client.request_build_monument(m_id)
		)

func _check_trade_valid() -> void:
	if trade_target_id != -1 and trade_their_card_id != -1 and trade_my_card_id != -1:
		btn_confirm_trade.disabled = false
		btn_confirm_trade.text = tr("Confirmer")


# ── Animation gate for turn overlay ──────────────────────────────────────────
var _active_fly_animations: int = 0
var pending_turn_data: Dictionary = {}

func _finish_fly_animation() -> void:
	_active_fly_animations = max(0, _active_fly_animations - 1)
	if _active_fly_animations == 0 and not pending_turn_data.is_empty():
		var data = pending_turn_data
		pending_turn_data = {}
		_show_turn_overlay(data)

func try_show_turn_overlay(data: Dictionary) -> void:
	if _active_fly_animations > 0:
		pending_turn_data = data
	else:
		_show_turn_overlay(data)

func _show_turn_overlay(data: Dictionary) -> void:
	var active_id   = data.get("active_player_id", -1)
	var active_name = data.get("player_name", "Inconnu")
	var is_my       = (int(active_id) == int(my_player_id))

	set_actions_enabled(is_my)
	lbl_turn_announcement.text = tr("Tour de ") + active_name

	if turn_overlay:
		turn_overlay.move_to_front()
		turn_overlay.show()
		var btn_box = turn_overlay.get_node_or_null("VBoxContainer/HBoxContainer")
		if btn_box: btn_box.visible = is_my
		if is_my and btn_overlay_roll_2:
			var my_data      = latest_players_data.get(str(my_player_id), {})
			var my_monuments = my_data.get("monuments", {})
			var has_gare     = my_monuments.get("22", false) or my_monuments.get(22, false)
			btn_overlay_roll_2.visible = has_gare

# ─────────────────────────────────────────────────────────────────────────────
func _trigger_gold_animations(new_players: Dictionary) -> void:
	if latest_players_data.is_empty(): return
	var any_change = false
	for p_id_str in new_players:
		var old_balance = int(latest_players_data.get(p_id_str, {}).get("balance", 0))
		var new_balance = int(new_players[p_id_str].get("balance", 0))
		var delta = new_balance - old_balance
		if delta != 0 and player_board_map.has(p_id_str):
			animer_gain_gold(player_board_map[p_id_str], delta)
			any_change = true
	if any_change:
		animer_shake_ecran(8.0, 0.25)

func _trigger_card_move_animations(new_players: Dictionary) -> void:
	if latest_players_data.is_empty(): return

	# Build a snapshot: {card_id: {player_id_str: quantity}}
	var old_snapshot: Dictionary = {}
	var new_snapshot: Dictionary = {}

	for p_id_str in latest_players_data:
		for entry in latest_players_data[p_id_str].get("deck", []):
			if typeof(entry) != TYPE_ARRAY: continue
			var cid = int(entry[0])
			var qty = int(entry[1])
			if not old_snapshot.has(cid): old_snapshot[cid] = {}
			old_snapshot[cid][p_id_str] = qty

	for p_id_str in new_players:
		for entry in new_players[p_id_str].get("deck", []):
			if typeof(entry) != TYPE_ARRAY: continue
			var cid = int(entry[0])
			var qty = int(entry[1])
			if not new_snapshot.has(cid): new_snapshot[cid] = {}
			new_snapshot[cid][p_id_str] = qty

	# Collect all card ids that appear in either snapshot
	var all_card_ids: Array = []
	for cid in old_snapshot: if not all_card_ids.has(cid): all_card_ids.append(cid)
	for cid in new_snapshot: if not all_card_ids.has(cid): all_card_ids.append(cid)

	for cid in all_card_ids:
		var donors:    Array = []  # players whose qty decreased
		var receivers: Array = []  # players whose qty increased

		var all_players: Array = []
		for p in old_snapshot.get(cid, {}): if not all_players.has(p): all_players.append(p)
		for p in new_snapshot.get(cid, {}): if not all_players.has(p): all_players.append(p)

		for p_id_str in all_players:
			var old_qty = int(old_snapshot.get(cid, {}).get(p_id_str, 0))
			var new_qty = int(new_snapshot.get(cid, {}).get(p_id_str, 0))
			var diff = new_qty - old_qty
			if diff < 0: donors.append(p_id_str)
			elif diff > 0: receivers.append(p_id_str)

		# Single card moved between exactly two players
		if donors.size() == 1 and receivers.size() == 1:
			var donor_id   = int(donors[0])
			var receiver_id = int(receivers[0])
			# Check if the receiver simultaneously lost a different card (trade)
			# — that will be handled by the other card's iteration, so only handle the gift here
			animer_don_carte(donor_id, cid, receiver_id)

func animer_gain_gold(cible_node: Control, montant: int) -> void:
	if montant == 0: return

	var float_text = RichTextLabel.new()
	float_text.bbcode_enabled = true
	float_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	float_text.fit_content = true
	float_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	float_text.z_index = 100

	var color_str = "gold" if montant > 0 else "red"
	var sign_str = "+" if montant > 0 else ""
	var icon_path = "res://assets/UI/coin.png"
	float_text.text = "[center][font=res://assets/Fonts/Exo_2/static/Exo2-BlackItalic.ttf][font_size=60][color=" + color_str + "]" + sign_str + str(montant) + "[/color] [img=60]" + icon_path + "[/img][/font_size][/font][/center]"

	add_child(float_text)

	# Anchor to the gold label if available, otherwise board center
	var anchor_pos = cible_node.global_position + (cible_node.size / 2.0)
	if cible_node.get("lbl_gold") and is_instance_valid(cible_node.lbl_gold):
		anchor_pos = cible_node.lbl_gold.global_position

	float_text.global_position = anchor_pos - Vector2(50, 20)
	float_text.scale = Vector2.ZERO
	float_text.rotation = cible_node.rotation

	if not is_inside_tree(): float_text.queue_free(); return
	await get_tree().process_frame
	if not is_instance_valid(float_text): return
	float_text.pivot_offset = float_text.size / 2.0

	var tween = create_tween().set_parallel(true)
	tween.tween_property(float_text, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	var move_offset = Vector2(0, -120).rotated(cible_node.rotation)
	tween.tween_property(float_text, "global_position", float_text.global_position + move_offset, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(float_text, "modulate:a", 0.0, 0.5).set_delay(1.0)

	await tween.finished
	float_text.queue_free()

# ──────────────────────────────────────────────────────────────────────────────
# ANIMATION FUNCTIONS (ported from JeuScript.gd)
# ──────────────────────────────────────────────────────────────────────────────

const CARD_ANIMATION_SCENE = preload("res://scene/table/card_animation.tscn")
var file_animations_activations: Array = []

# Enhances play_dice_animation with rotation wobble + mini-dice fly-to-board.
# Call this instead of the base version when you want full juice.
func play_dice_animation_enhanced(amount: int, final_d1: int, final_d2: int = 0, can_reroll: bool = false, spectator: bool = false) -> String:
	if die_1 == null or result_overlay == null: return "keep"

	result_overlay.move_to_front()
	result_overlay.show()

	if btn_conserver: btn_conserver.hide()
	if btn_relancer: btn_relancer.hide()
	if btn_add_2:    btn_add_2.hide()

	die_1.show()
	if die_2: die_2.visible = (amount == 2)

	die_1.pivot_offset = die_1.size / 2.0
	if die_2: die_2.pivot_offset = die_2.size / 2.0

	var frames = 15
	var delay  = 0.05
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

	if spectator:
		# --- mini-dice fly to active board even for spectators ---
		_launch_mini_dice(amount, final_d1, final_d2)
		await get_tree().create_timer(2.0).timeout
		result_overlay.hide()
		return "keep"

	var total = final_d1 + final_d2
	var has_port = false
	var my_data = latest_players_data.get(str(my_player_id), {})
	has_port = my_data.get("monuments", {}).get("21", false) or my_data.get("monuments", {}).get(21, false)

	if btn_conserver: btn_conserver.show(); btn_conserver.disabled = false
	if btn_relancer: btn_relancer.visible = can_reroll; btn_relancer.disabled = false
	if btn_add_2:    btn_add_2.visible = (has_port and total >= 10); btn_add_2.disabled = false

	var action = await dice_decision_made

	if action == "reroll":
		result_overlay.hide()
		return action

	_launch_mini_dice(amount, final_d1, final_d2)
	result_overlay.hide()
	return action

func _launch_mini_dice(amount: int, final_d1: int, final_d2: int) -> void:
	# Find active player's board to target
	var target_board: Control = player_board_map.get(str(my_player_id), null)
	if not is_instance_valid(target_board): return

	var target_btn = target_board.get("btn_pass")
	if not is_instance_valid(target_btn) or not target_btn.is_inside_tree():
		target_btn = target_board

	var start_pos_1 = die_1.global_position
	var start_size_1 = die_1.size

	var dummy_1 = TextureRect.new()
	dummy_1.texture = die_1.texture
	dummy_1.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dummy_1.size = start_size_1
	dummy_1.pivot_offset = start_size_1 / 2.0
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
		dummy_2.pivot_offset = die_2.size / 2.0
		target_btn.add_child(dummy_2)
		dummy_2.global_position = die_2.global_position
		dummy_2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mini_dice_array.append(dummy_2)

	var anim_duration = 0.6
	var target_scale   = Vector2(0.2, 0.2)
	var base_local_pos = Vector2(-105, -2)
	var ecart = 45

	var t1 = target_btn.create_tween().set_parallel(true)
	t1.tween_property(dummy_1, "scale",          target_scale,     anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	t1.tween_property(dummy_1, "rotation_degrees", 0.0,            anim_duration).set_trans(Tween.TRANS_CUBIC)
	t1.tween_property(dummy_1, "position",        base_local_pos,  anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	if dummy_2:
		var pos2 = base_local_pos + Vector2(ecart, 0)
		t1.tween_property(dummy_2, "scale",          target_scale, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		t1.tween_property(dummy_2, "rotation_degrees", 0.0,        anim_duration).set_trans(Tween.TRANS_CUBIC)
		t1.tween_property(dummy_2, "position",        pos2,        anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func animer_shake_ecran(intensite: float = 15.0, duree: float = 0.3) -> void:
	if not is_instance_valid(table_pivot): return

	var original_pos = table_pivot.position
	var tween =create_tween()
	var steps = int(duree / 0.05)

	for i in range(steps):
		var offset = Vector2(randf_range(-intensite, intensite), randf_range(-intensite, intensite))
		tween.tween_property(table_pivot, "position", original_pos + offset, 0.05).set_trans(Tween.TRANS_SINE)

	tween.tween_property(table_pivot, "position", original_pos, 0.05)

func animer_activation_carte(carte_node: Control) -> void:
	if not is_instance_valid(carte_node): return

	var original_scale = carte_node.scale
	carte_node.pivot_offset = carte_node.size / 2.0

	var tween = create_tween()
	tween.tween_property(carte_node, "scale", original_scale * 1.25, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(carte_node, "scale", original_scale,        0.30).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func animer_pioche_vers_shop(target_slot: Control, texture_recto: Texture2D, target_pos: Vector2 = Vector2.ZERO) -> void:
	var deck_node = get_node_or_null("CenterBoard/Deck")
	if not is_instance_valid(deck_node) or not is_instance_valid(target_slot): return

	target_slot.modulate.a = 0.0
	_active_fly_animations += 1

	var card_size = Vector2(shop_board.shop_card_w, shop_board.shop_card_h)
	var dummy = TextureRect.new()
	dummy.texture = preload("res://assets/UI/dos_card.png")
	dummy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dummy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dummy.size = card_size
	dummy.pivot_offset = card_size / 2.0
	dummy.z_index = 150

	var start_pos = deck_node.global_position + (deck_node.size / 2.0) - dummy.pivot_offset
	dummy.global_position = start_pos
	add_child(dummy)

	# Use the passed-in position (captured before the old slot was freed).
	# If none was passed (legacy call), fall back to the slot's current position.
	if target_pos == Vector2.ZERO:
		target_pos = target_slot.global_position

	var anim_duration = 0.6

	var tween_arc = create_tween().set_parallel(true)
	tween_arc.tween_property(dummy, "global_position:x", target_pos.x, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_arc.tween_property(dummy, "rotation_degrees",  -360.0,       anim_duration).set_trans(Tween.TRANS_CUBIC)

	var drop_offset = 150.0
	var lowest_y    = max(deck_node.global_position.y, target_pos.y) + drop_offset
	var tween_y = create_tween()
	tween_y.tween_property(dummy, "global_position:y", lowest_y,    anim_duration / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_y.tween_property(dummy, "global_position:y", target_pos.y, anim_duration / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await tween_arc.finished

	var flip_tween = create_tween()
	flip_tween.tween_property(dummy, "scale:x", 0.0, 0.15).set_trans(Tween.TRANS_SINE)
	flip_tween.tween_callback(func():
		dummy.texture = texture_recto
		dummy.rotation_degrees = 0.0
	)
	flip_tween.tween_property(dummy, "scale:x", 1.0, 0.15).set_trans(Tween.TRANS_SINE)

	await flip_tween.finished

	if is_instance_valid(target_slot): target_slot.modulate.a = 1.0
	dummy.queue_free()
	_finish_fly_animation()

func animer_achat_vers_main(card_id: int, quantity_in_shop: int = 1) -> void:
	if not is_instance_valid(shop_board) or not is_instance_valid(shop_board.get("last_clicked_slot")): return

	var target_board: PlayerBoard = player_board_map.get(str(my_player_id), null)
	if not is_instance_valid(target_board): return

	var shop_slot   = shop_board.last_clicked_slot
	var visual_node = shop_slot.get_node_or_null("Visual")

	var card_data  = CardFactory.get_card(card_id)
	var color      = card_data.get_color()
	var pile_cible = target_board.piles[color]
	var anchor     = pile_cible.get_node_or_null("Anchor")

	var card_width    = 156
	var stack_gap     = 25
	var current_count = anchor.get_child_count() if anchor else 0

	pile_cible.custom_minimum_size.x = card_width + (current_count * stack_gap)

	var target_pos = pile_cible.global_position
	if is_instance_valid(anchor):
		var offset_local = Vector2(current_count * stack_gap, 0.0).rotated(target_board.rotation)
		target_pos = anchor.global_position + offset_local

	var dummy = CARD_ANIMATION_SCENE.instantiate()
	add_child(dummy)
	dummy.setup_card(card_data, target_board.get_board_tooltip_direction())
	dummy.z_index   = 4000
	dummy.top_level = true
	dummy.global_position = visual_node.global_position if visual_node else shop_slot.global_position
	dummy.scale = Vector2(0.75, 0.75)

	if visual_node and quantity_in_shop <= 1:
		visual_node.modulate.a = 0.0

	_active_fly_animations += 1

	var anim_duration = 0.6
	var tween = create_tween().set_parallel(true)
	tween.tween_property(dummy, "global_position", target_pos,           anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(dummy, "scale",           Vector2(1.0, 1.0),    anim_duration).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(dummy, "rotation",        target_board.rotation, anim_duration).set_trans(Tween.TRANS_CUBIC)

	await tween.finished

	if is_instance_valid(anchor):
		dummy.get_parent().remove_child(dummy)
		anchor.add_child(dummy)
		dummy.top_level = false
		dummy.position  = Vector2(current_count * stack_gap, 0)
		dummy.rotation  = 0

	_finish_fly_animation()

func animer_erreur_carte_shop(slot_node: Control) -> void:
	var visual = slot_node.get_node_or_null("Visual")
	if not visual: return

	var tween    = create_tween()
	var orig_pos = visual.position

	tween.tween_property(visual, "modulate", Color(2.0, 0.3, 0.3), 0.1)
	for i in range(4):
		var side = 5 if i % 2 == 0 else -5
		tween.tween_property(visual, "position:x", orig_pos.x + side, 0.05)
	tween.tween_property(visual, "position:x", orig_pos.x, 0.05)
	tween.tween_property(visual, "modulate", Color.WHITE, 0.3).set_delay(0.2)

	if is_instance_valid(shop_board) and shop_board.has_method("clear_selection"):
		tween.tween_callback(func(): shop_board.clear_selection())

func animer_erreur_argent(board_visuel: PlayerBoard) -> void:
	var label_argent = board_visuel.lbl_gold
	if not label_argent: return

	var tween       = create_tween()
	var original_pos = label_argent.position
	label_argent.modulate = Color.RED

	tween.tween_property(label_argent, "position:x", original_pos.x + 5, 0.05)
	tween.tween_property(label_argent, "position:x", original_pos.x - 5, 0.05)
	tween.tween_property(label_argent, "position:x", original_pos.x,     0.05)
	tween.tween_property(label_argent, "modulate",   Color.WHITE,        0.3).set_delay(0.2)

func animer_echange_cartes(player1_id: int, id_carte1: int, player2_id: int, id_carte2: int) -> void:
	var board1: PlayerBoard = player_board_map.get(str(player1_id), null)
	var board2: PlayerBoard = player_board_map.get(str(player2_id), null)
	if not is_instance_valid(board1) or not is_instance_valid(board2): return

	var noeud1 = board1.get_card_node(id_carte1)
	var noeud2 = board2.get_card_node(id_carte2)
	if not is_instance_valid(noeud1) or not is_instance_valid(noeud2): return

	var card_data1 = CardFactory.get_card(id_carte1)
	var card_data2 = CardFactory.get_card(id_carte2)
	var p1_color   = card_data1.get_color()
	var p2_color   = card_data2.get_color()

	var card_width    = 156
	var stack_gap     = 25
	var anim_duration = 0.8

	var b1_deltas = { CardColor.Type.BLUE: 0, CardColor.Type.GREEN: 0, CardColor.Type.RED: 0, CardColor.Type.PURPLE: 0 }
	var b2_deltas = { CardColor.Type.BLUE: 0, CardColor.Type.GREEN: 0, CardColor.Type.RED: 0, CardColor.Type.PURPLE: 0 }
	b1_deltas[p1_color] -= 1;  b1_deltas[p2_color] += 1
	b2_deltas[p2_color] -= 1;  b2_deltas[p1_color] += 1

	var tween = create_tween().set_parallel(true)

	var animer_fond_pile = func(board: PlayerBoard, color: int, delta: int):
		if delta == 0: return
		var pile    = board.piles[color]
		var anchor  = pile.get_node_or_null("Anchor")
		var count   = anchor.get_child_count() if anchor else 0
		var final_c = max(1, max(0, count + delta))
		tween.tween_property(pile, "custom_minimum_size:x", card_width + ((final_c - 1) * stack_gap), anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	animer_fond_pile.call(board1, p1_color, b1_deltas[p1_color])
	if p1_color != p2_color: animer_fond_pile.call(board1, p2_color, b1_deltas[p2_color])
	animer_fond_pile.call(board2, p1_color, b2_deltas[p1_color])
	if p1_color != p2_color: animer_fond_pile.call(board2, p2_color, b2_deltas[p2_color])

	var glisser = func(noeud_partant: Control):
		var anchor = noeud_partant.get_parent()
		if not is_instance_valid(anchor): return
		var idx = noeud_partant.get_index()
		for i in range(anchor.get_child_count()):
			if i > idx:
				tween.tween_property(anchor.get_child(i), "position:x", anchor.get_child(i).position.x - stack_gap, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	glisser.call(noeud1)
	glisser.call(noeud2)

	var get_target_pos = func(target_board: PlayerBoard, color: int, delta: int) -> Vector2:
		var pile   = target_board.piles[color]
		var anchor = pile.get_node_or_null("Anchor")
		var count  = anchor.get_child_count() if anchor else 0
		var final_c = max(0, count + delta)
		var landing = max(0, final_c - 1)
		var pos = pile.global_position
		if is_instance_valid(anchor):
			pos = anchor.global_position + Vector2(landing * stack_gap, 0.0).rotated(target_board.rotation)
		return pos

	var end_pos1 = get_target_pos.call(board2, p1_color, b2_deltas[p1_color])
	var end_pos2 = get_target_pos.call(board1, p2_color, b1_deltas[p2_color])

	var dummy1 = CARD_ANIMATION_SCENE.instantiate()
	var dummy2 = CARD_ANIMATION_SCENE.instantiate()
	add_child(dummy1); add_child(dummy2)
	dummy1.setup_card(card_data1, board1.get_board_tooltip_direction())
	dummy2.setup_card(card_data2, board2.get_board_tooltip_direction())
	dummy1.z_index = 4000;  dummy1.top_level = true
	dummy2.z_index = 4000;  dummy2.top_level = true
	dummy1.global_position = noeud1.global_position;  dummy1.rotation = board1.rotation
	dummy2.global_position = noeud2.global_position;  dummy2.rotation = board2.rotation
	noeud1.modulate.a = 0.0
	noeud2.modulate.a = 0.0

	tween.tween_property(dummy1, "global_position", end_pos1,        anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(dummy1, "rotation",        board2.rotation, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(dummy2, "global_position", end_pos2,        anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(dummy2, "rotation",        board1.rotation, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(dummy1, "scale", Vector2(1.2, 1.2), anim_duration / 2.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(dummy1, "scale", Vector2(1.0, 1.0), anim_duration / 2.0).set_delay(anim_duration / 2.0)
	tween.tween_property(dummy2, "scale", Vector2(1.2, 1.2), anim_duration / 2.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(dummy2, "scale", Vector2(1.0, 1.0), anim_duration / 2.0).set_delay(anim_duration / 2.0)

	await tween.finished

	var transfer = func(dummy: Control, target_board: PlayerBoard, card_data, delta: int):
		var color  = card_data.get_color()
		var anchor = target_board.piles[color].get_node_or_null("Anchor")
		if is_instance_valid(anchor):
			var count   = anchor.get_child_count()
			var landing = max(0, max(0, count + delta) - 1)
			dummy.get_parent().remove_child(dummy)
			anchor.add_child(dummy)
			dummy.top_level = false
			dummy.position  = Vector2(landing * stack_gap, 0)
			dummy.rotation  = 0
			dummy.setup_card(card_data, target_board.get_board_tooltip_direction())

	transfer.call(dummy1, board2, card_data1, b2_deltas[p1_color])
	transfer.call(dummy2, board1, card_data2, b1_deltas[p2_color])

func animer_don_carte(donor_id: int, id_carte: int, receiver_id: int) -> void:
	var board_source: PlayerBoard = player_board_map.get(str(donor_id),   null)
	var board_cible:  PlayerBoard = player_board_map.get(str(receiver_id), null)
	if not is_instance_valid(board_source) or not is_instance_valid(board_cible): return

	var noeud_carte = board_source.get_card_node(id_carte)
	if not is_instance_valid(noeud_carte): return

	var card_data  = CardFactory.get_card(id_carte)
	var color      = card_data.get_color()
	var card_width = 156
	var stack_gap  = 25
	var anim_duration = 0.8

	var tween = create_tween().set_parallel(true)

	var pile_source   = board_source.piles[color]
	var anchor_source = pile_source.get_node_or_null("Anchor")
	var count_source  = anchor_source.get_child_count() if anchor_source else 0
	var target_w_src  = card_width + ((max(1, max(0, count_source - 1)) - 1) * stack_gap)
	tween.tween_property(pile_source, "custom_minimum_size:x", target_w_src, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	if is_instance_valid(anchor_source):
		var idx = noeud_carte.get_index()
		for i in range(anchor_source.get_child_count()):
			if i > idx:
				tween.tween_property(anchor_source.get_child(i), "position:x", anchor_source.get_child(i).position.x - stack_gap, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	var pile_cible    = board_cible.piles[color]
	var anchor_cible  = pile_cible.get_node_or_null("Anchor")
	var count_cible   = anchor_cible.get_child_count() if anchor_cible else 0
	var target_w_dst  = card_width + (count_cible * stack_gap)
	tween.tween_property(pile_cible, "custom_minimum_size:x", target_w_dst, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	var end_pos = pile_cible.global_position
	if is_instance_valid(anchor_cible):
		end_pos = anchor_cible.global_position + Vector2(count_cible * stack_gap, 0.0).rotated(board_cible.rotation)

	var dummy = CARD_ANIMATION_SCENE.instantiate()
	add_child(dummy)
	dummy.setup_card(card_data, board_source.get_board_tooltip_direction())
	dummy.z_index   = 4000
	dummy.top_level = true
	dummy.global_position = noeud_carte.global_position
	dummy.rotation        = board_source.rotation
	noeud_carte.modulate.a = 0.0

	tween.tween_property(dummy, "global_position", end_pos,              anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(dummy, "rotation",        board_cible.rotation, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

	if is_instance_valid(anchor_cible):
		dummy.get_parent().remove_child(dummy)
		anchor_cible.add_child(dummy)
		dummy.top_level = false
		dummy.position  = Vector2(count_cible * stack_gap, 0)
		dummy.rotation  = 0
		dummy.setup_card(card_data, board_cible.get_board_tooltip_direction())

func declencher_animations_activation(activations: Array) -> void:
	if activations.is_empty(): return

	# Phase 1 — raise all activating cards
	var montee_tweens = []
	for data in activations:
		var c = data.get("carte_visuelle")
		if is_instance_valid(c) and c.has_method("animer_montee"):
			montee_tweens.append(c.animer_montee())

	if not montee_tweens.is_empty():
		await montee_tweens[0].finished

	# Phase 2 — run effect callables (gold floats, etc.)
	for data in activations:
		var effet = data.get("effet_callable")
		if effet is Callable and effet.is_valid():
			effet.call()

	# Juice pause
	await get_tree().create_timer(1.2).timeout

	# Phase 3 — lower all cards
	var descente_tweens = []
	for data in activations:
		var c = data.get("carte_visuelle")
		if is_instance_valid(c) and c.has_method("animer_descente"):
			descente_tweens.append(c.animer_descente())

	if not descente_tweens.is_empty():
		await descente_tweens[0].finished

func executer_animations_collectees() -> void:
	if not file_animations_activations.is_empty():
		await declencher_animations_activation(file_animations_activations)
		file_animations_activations.clear()

# Call this from _on_network_message when you know which card activated and which
# balances changed, so the activation sequence plays before the board refreshes.
func notifier_activation_multi(player_id: int, card_id: int, balance_changes: Dictionary = {}) -> void:
	var board_visuel: PlayerBoard = player_board_map.get(str(player_id), null)
	if not is_instance_valid(board_visuel): return

	var noeud_carte = board_visuel.get_card_node(card_id)

	file_animations_activations.append({
		"carte_visuelle": noeud_carte,
		"effet_callable": func():
			for p_id_str in balance_changes:
				var amount = balance_changes[p_id_str]
				var board  = player_board_map.get(str(p_id_str), null)
				if is_instance_valid(board):
					animer_gain_gold(board, amount)
					board.update_info()
	})
