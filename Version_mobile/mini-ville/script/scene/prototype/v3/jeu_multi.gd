extends Node

# --- GESTION RESEAU ---
var network_client: GameClient
var my_player_id: int
var latest_players_data: Dictionary = {}
var latest_shop_data: Dictionary = {}
var player_board_map: Dictionary = {}  # {player_id_str: board_node}
var _pending_dice_action: String = ""
var _is_animating_dice: bool = false
var _pending_sync_data: Dictionary = {}
var file_attente_messages: Array = []
var traitement_en_cours: bool = false
var est_premier_tour: bool = true
var pending_shop_animation_index: int = -1
var current_active_player_id: int = -1
var _dice_anim_counter: int = 0

signal dice_amount_chosen(amount: int)
signal yes_no_answered(result: bool)
signal player_chosen(target_id: int)
signal trade_completed(trade_data: Array)
signal give_card_completed(give_data: Array)
signal demolish_completed(monu_id: int)
signal dice_decision_made(action: String)
signal rotation_finished

@onready var middle_area: HBoxContainer = $CenterBoard
@onready var table_pivot: Control = $TablePivot
@onready var boards: Array = [$TablePivot/BoardJoueurBas, $TablePivot/BoardJoueurGauche, $TablePivot/BoardJoueurHaut, $TablePivot/BoardJoueurDroite]
@onready var shop_popup: CanvasLayer = %ShopPopup
@onready var shop_button: TextureButton = %ShopButton
var active_boards: Array = []

# --- CAMERA ET ANIMATIONS (Juice) ---
@onready var camera: Camera2D = $Camera2D
@onready var click_blocker: ColorRect = get_node_or_null("ClickBlocker")

var player_angles: Array = [0.0, 0.0, 0.0, 0.0]
var is_rotating: bool = false
var _active_fly_animations: int = 0

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
@onready var main_menu_button: Button = %MenuPrincipal
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
	
	# --- CORRECTION : Cacher les plateaux au lancement ---
	# Empêche de voir l'écran en vrac avant de recevoir les données du serveur
	if is_instance_valid(table_pivot): table_pivot.hide()
	if is_instance_valid(middle_area): middle_area.hide()
	for b in boards:
		if is_instance_valid(b): 
			b.hide()
			
	_find_dice_ui_nodes()
	_force_overlays_to_front()
	_setup_tooltip_glows()
	
	if btn_overlay_roll_1:
		btn_overlay_roll_1.pressed.connect(func():
			if btn_overlay_roll_1: btn_overlay_roll_1.disabled = true
			if btn_overlay_roll_2: btn_overlay_roll_2.disabled = true
			if turn_overlay: turn_overlay.hide()
			
			# --- NOUVEAU : On bloque TOUT l'écran ---
			if is_instance_valid(click_blocker):
				click_blocker.z_index = 4096
				click_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
				click_blocker.show()
			
			network_client.request_roll_dice(1)
		)
	if btn_overlay_roll_2:
		btn_overlay_roll_2.pressed.connect(func():
			if btn_overlay_roll_1: btn_overlay_roll_1.disabled = true
			if btn_overlay_roll_2: btn_overlay_roll_2.disabled = true
			if turn_overlay: turn_overlay.hide()
			
			# --- NOUVEAU : On bloque TOUT l'écran ---
			if is_instance_valid(click_blocker):
				click_blocker.z_index = 4096
				click_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
				click_blocker.show()
			
			network_client.request_roll_dice(2)
		)
	
	%CancelCardBuy.pressed.connect(func(): 
		buy_confirm_panel.hide()
		shop_popup.open_network(latest_shop_data)
		send_ui_interaction("close_shop_preview")
	)

	buy_confirm_panel.z_index = 200
	close_menu.pressed.connect(func(): 
		monument_menu.hide()
		send_ui_interaction("close_monuments")
	)
	
	if btn_conserver: btn_conserver.pressed.connect(func(): 
		_disable_result_buttons()
		dice_decision_made.emit("keep")
	)
	if btn_relancer: btn_relancer.pressed.connect(func(): 
		_disable_result_buttons()
		dice_decision_made.emit("reroll")
	)
	if btn_add_2: btn_add_2.pressed.connect(func(): 
		_disable_result_buttons()
		dice_decision_made.emit("add2")
	)

	
	if settings_button: 
		settings_button.pressed.connect(func(): 
			settings_overlay.z_index = 4096 # S'assure qu'il passe au-dessus de TOUT
			settings_overlay.show()
		)
	if continue_button: continue_button.pressed.connect(func(): settings_overlay.hide())
	if main_menu_button: main_menu_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scene/Ecran principale/accueil.tscn"))
	if settings_quit_button: settings_quit_button.pressed.connect(func(): get_tree().quit())
	
	%ConfirmTrade.pressed.connect(func(): trade_completed.emit([trade_my_card_id, trade_target_id, trade_their_card_id]))
	%ConfirmGive.pressed.connect(func(): give_card_completed.emit([give_card_id, give_target_id]))
	
	for board in boards:
		if is_instance_valid(board):
			board.pass_turn_requested.connect(func(): 
				# NOUVEAU : On verrouille le plateau instantanément
				set_actions_enabled(false) 
				if is_instance_valid(click_blocker): click_blocker.show()
				network_client.request_skip_turn()
			)
			board.open_monuments_requested.connect(_on_open_monuments_pressed)
			
		
	shop_button.pressed.connect(_on_shop_button_pressed)
	shop_popup.shop_card_clicked.connect(_on_shop_card_clicked)
	%ConfirmCardBuy.pressed.connect(_on_confirm_buy_shop_pressed)

	get_viewport().size_changed.connect(_on_window_resized)
	await get_tree().process_frame
	_on_window_resized()

	NetworkManager.message_recu.connect(_on_network_message)

	await get_tree().process_frame
	network_client.current_lobby_id = LobbyHandler.get_lobby_id()

	if not network_client.cached_sync_data.is_empty():
		var cached = network_client.cached_sync_data.duplicate()
		network_client.cached_sync_data.clear()
		_on_network_message(cached)

	if not network_client.cached_turn_data.is_empty():
		var cached_turn = network_client.cached_turn_data.duplicate()
		network_client.cached_turn_data.clear()
		network_client._handle_turn_started(cached_turn)

# Ajoute cette petite fonction juste au-dessus de _ready()
func _disable_result_buttons() -> void:
	if btn_conserver: btn_conserver.disabled = true
	if btn_relancer: btn_relancer.disabled = true
	if btn_add_2: btn_add_2.disabled = true
	
	# --- NOUVEAU : On re-bloque l'écran en attendant la réponse ---
	if is_instance_valid(click_blocker):
		click_blocker.z_index = 4096
		click_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
		click_blocker.show()


# Et dans _ready(), remplace les 3 lignes btn_conserver, etc. par :
	if btn_conserver: btn_conserver.pressed.connect(func(): 
		_disable_result_buttons()
		dice_decision_made.emit("keep")
	)
	if btn_relancer: btn_relancer.pressed.connect(func(): 
		_disable_result_buttons()
		dice_decision_made.emit("reroll")
	)
	if btn_add_2: btn_add_2.pressed.connect(func(): 
		_disable_result_buttons()
		dice_decision_made.emit("add2")
	)

func set_actions_enabled(can_act: bool) -> void:
	# --- SÉCURITÉ : On débloque toujours les clics si on active les actions ---
	if can_act and is_instance_valid(click_blocker):
		click_blocker.hide()

	for board in boards:
		if is_instance_valid(board): 
			if board.has_method("set_actions_enabled"):
				board.set_actions_enabled(can_act)
				
			# CORRECTION : Le bouton "End Turn" n'est visible QUE si c'est
			# notre tour ET que ce plateau est bien le nôtre (joueur en bas)
			var btn_pass = board.get("btn_pass")
			if is_instance_valid(btn_pass):
				btn_pass.visible = can_act and (board == player_board_map.get(str(my_player_id), null))

	if is_instance_valid(shop_popup): shop_popup.set_actions_enabled(can_act)

func update_network_boards(players_data: Dictionary, animate_rotation: bool = false):
	latest_players_data = players_data

	var player_ids = players_data.keys()
	var my_id_str = str(my_player_id)

	# --- ON DÉFINIT SI ON EST SPECTATEUR ICI ---
	var is_spectator = not players_data.has(my_id_str)

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

	if is_instance_valid(table_pivot): table_pivot.show()
	if is_instance_valid(middle_area): 
		middle_area.show()
		# AJOUT : On force le recalcul de la fenêtre maintenant que le shop est visible !
		_on_window_resized.call_deferred()
	
	positionner_plateaux.call_deferred(animate_rotation)
	
	positionner_plateaux.call_deferred(animate_rotation)

	# --- CORRECTION : NETTOYAGE BRUTAL DES BOUTONS 'END TURN' ---
	for board in boards:
		if is_instance_valid(board):
			var btn_pass = board.get("btn_pass")
			if is_instance_valid(btn_pass):
				# On utilise la variable is_spectator que l'on vient de créer
				if is_spectator or board != player_board_map.get(my_id_str, null):
					btn_pass.hide() 
					btn_pass.mouse_filter = Control.MOUSE_FILTER_IGNORE 
					btn_pass.button_pressed = false
					
	hook_all_hovers.call_deferred()
					 
func send_ui_interaction(type: String, metadata: Dictionary = {}) -> void:
	if current_active_player_id != my_player_id: return
	NetworkManager.envoyer({
		"action": "game_action",
		"game_action": "ui_interaction",
		"interaction_type": type,
		"metadata": metadata
	})


func update_network_shop(shop_data: Dictionary):
	latest_shop_data = shop_data

	if not is_instance_valid(shop_popup.shop_board): return
	
	# On se contente d'actualiser les données, l'animation sera gérée après.
	shop_popup.shop_board.update_network_shop(shop_data)
	hook_all_hovers.call_deferred()


func show_victory_screen(winner_name: String) -> void:
	set_actions_enabled(false)
	lbl_winner_name.text = "🏆 " + winner_name + " " + tr("GAGNE!")
	victory_screen.move_to_front()
	victory_screen.show()

func _on_shop_card_clicked(card_id: int, is_spectator: bool = false) -> void:
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
			var clean_name = ""
			if shop_popup.shop_board.has_method("get_clean_file_name"):
				clean_name = shop_popup.shop_board.get_clean_file_name(card_name, card_color)
			else:
				clean_name = get_clean_file_name(card_name, card_color)
			path_basis = "res://assets/Cards/" + get_lang_folder() + "/Establishments/" + clean_name + "_1.png"
			tip_path = "res://assets/Tooltips/" + get_lang_folder() + "/tooltip_" + clean_name + ".png"

		var image_node = preview_card.get_node_or_null("Visual")
		if image_node and image_node is TextureButton:
			var _tex = load(path_basis)
			if _tex: image_node.texture_normal = _tex
			image_node.disabled = true
			image_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
			image_node.ignore_texture_size = true
			image_node.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

		var internal_tooltip = preview_card.get_node_or_null("Visual/Tooltip")
		if internal_tooltip:
			internal_tooltip.hide()

		%CardPreview.add_child(preview_card)
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

	await shop_popup.close()
	buy_confirm_panel.move_to_front()
	buy_confirm_panel.show()
	 
	%ConfirmCardBuy.visible = not is_spectator
	if not is_spectator:
		send_ui_interaction("open_shop_preview", {"card_id": card_id})
		
	buy_confirm_panel.move_to_front()
	buy_confirm_panel.show()

		
func _on_confirm_buy_shop_pressed() -> void:
	var card_data = CardFactory.get_card(selected_shop_card_id)
	if card_data == null: return
	
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
		if card_data.has_method("get_cost"): cost = card_data.get_cost()
		elif card_data.get("cost") != null: cost = card_data.get("cost")
		
	var my_balance = int(latest_players_data.get(str(my_player_id), {}).get("balance", 0))
	
	# --- VERIFICATION LOCALE (Stoppe les bugs d'animation) ---
	if my_balance < cost:
		buy_confirm_panel.hide()
		if is_monument and is_instance_valid(monument_menu): monument_menu.hide()
		send_ui_interaction("buy_error", {"card_id": selected_shop_card_id, "is_monument": is_monument})
		await get_tree().create_timer(0.15).timeout
		var my_board = player_board_map.get(str(my_player_id), null)
		if is_instance_valid(my_board): animer_erreur_argent(my_board)
		if not is_monument and is_instance_valid(shop_popup.shop_board) and is_instance_valid(shop_popup.shop_board.get("last_clicked_slot")):
			animer_erreur_carte_shop(shop_popup.shop_board.last_clicked_slot)
		return

	# L'ACHAT EST VALIDE, on lance la machine :
	send_ui_interaction("close_shop_preview")
	buy_confirm_panel.hide()
	monument_menu.hide()

	if is_monument:
		network_client.request_build_monument(selected_shop_card_id)
		animer_shake_ecran()
	else:
		var qty_in_shop = int(latest_shop_data.get(str(selected_shop_card_id), 1))
		var new_qty = qty_in_shop - 1
		set_actions_enabled(false)
		
		# --- GESTION LOCALE --- 
		# Evite les clignotements pour celui qui vient de cliquer
		if new_qty > 0 and is_instance_valid(shop_popup.shop_board) and shop_popup.shop_board.get("last_clicked_slot"):
			if shop_popup.shop_board.last_clicked_slot.has_method("set_badge_count"):
				shop_popup.shop_board.last_clicked_slot.set_badge_count(new_qty)

		animer_achat_vers_main(selected_shop_card_id, new_qty, my_player_id)

		network_client.request_buy_card(selected_shop_card_id)

func _on_open_monuments_pressed() -> void:
	send_ui_interaction("open_monuments")
	update_monument_menu()
	monument_menu.move_to_front()
	monument_menu.show()
	
	

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
		
		# Effet Hover
		btn.mouse_entered.connect(func():
			var tween = create_tween()
			tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1)
		)
		btn.mouse_exited.connect(func():
			var tween = create_tween()
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
					child.modulate = Color(1.0, 1.0, 1.0)
					child.scale = Vector2(1.0, 1.0)
				else:
					child.modulate = Color(0.4, 0.4, 0.4)
					child.scale = Vector2(0.9, 0.9)
		)
		trade_opponents.add_child(btn)
	
	_populate_trade_deck(latest_players_data[str(my_player_id)].get("deck", []), trade_my_cards, true)
	
	var result = await trade_completed
	trade_panel.hide()
	return result

func _on_trade_opponent_selected(target_id: int, data: Dictionary) -> void:
	trade_target_id = target_id
	_populate_trade_deck(data.get("deck", []), trade_their_cards, false)
	_check_trade_valid()

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
			hover_style.shadow_color = Color(1.0, 1.0, 1.0, 0.6)
			hover_style.shadow_size = 20
			
			card_btn.mouse_entered.connect(func(): 
				outline.add_theme_stylebox_override("panel", hover_style)
				if card_btn.modulate != Color(0.4, 0.4, 0.4):
					var tween = create_tween().set_parallel(true)
					tween.tween_property(card_btn, "scale", Vector2(1.05, 1.05), 0.1)
					tween.tween_property(card_btn, "rotation", deg_to_rad(3), 0.1)
			)
			card_btn.mouse_exited.connect(func(): 
				outline.add_theme_stylebox_override("panel", style)
				if card_btn.modulate != Color(0.4, 0.4, 0.4):
					var tween = create_tween().set_parallel(true)
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
		
		btn.mouse_entered.connect(func():
			if btn.modulate != Color(0.4, 0.4, 0.4):
				var tween = create_tween()
				tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1)
		)
		btn.mouse_exited.connect(func():
			if btn.modulate != Color(0.4, 0.4, 0.4):
				var tween = create_tween()
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
	var overlays = [turn_overlay, result_overlay, monument_menu, victory_screen, choose_player_panel, trade_panel, give_panel, buy_confirm_panel, settings_overlay]
	for overlay in overlays:
		if is_instance_valid(overlay): overlay.z_index = 100 

func _on_window_resized() -> void:
	var screen_size = get_viewport().get_visible_rect().size
	
	if table_pivot:
		table_pivot.set_anchors_preset(Control.PRESET_FULL_RECT)
		table_pivot.size = screen_size
		table_pivot.pivot_offset = screen_size / 2.0
		table_pivot.position = Vector2.ZERO
	
	if middle_area:
		# 1. On utilise l'ancre native de Godot pour le centrage absolu
		middle_area.set_anchors_preset(Control.PRESET_CENTER)
		
		# 2. On met à jour la taille et l'échelle
		middle_area.reset_size()
		middle_area.pivot_offset = middle_area.size / 2.0
		middle_area.scale = Vector2(0.8, 0.8)
		# (ON SUPPRIME LA LIGNE "middle_area.position = ...")
		
	if latest_players_data.size() > 0:
		positionner_plateaux(false)

func is_tablet() -> bool:
	var dpi = DisplayServer.screen_get_dpi()
	var screen_size_px = DisplayServer.screen_get_size()
	var screen_inch_w = screen_size_px.x / float(dpi)
	var screen_inch_h = screen_size_px.y / float(dpi)
	var diag = sqrt(screen_inch_w * screen_inch_w + screen_inch_h * screen_inch_h)
	return diag >= 7.0

func positionner_plateaux(animate: bool = false) -> void:
	if not is_inside_tree() or get_viewport() == null:
		return

	var active_count = latest_players_data.size()
	
	if active_count == 0: 
		return

	var screen_size = get_viewport().get_visible_rect().size
	var c = screen_size / 2.0
	var margin = 40
	# Scale dynamique selon taille écran et nb joueurs
	# base_h = 264 (dimension courte du board, celle qui "empiète" sur l'espace)
	# On veut que chaque board ne dépasse pas ~45% de la dimension la plus courte de l'écran
	var board_scale = 1.0
	
	var tween = null
	if is_tablet():
		var base_h = 264.0
		# Chaque board (dimension courte = base_h) doit tenir dans ~30% de la dimension
		# la plus courte de l'écran pour que 4 boards autour ne se chevauchent pas
		var min_screen = min(screen_size.x, screen_size.y)
		var max_scale = (min_screen * 0.30) / base_h
		board_scale = clamp(max_scale, 1.0, 1.3)

	for p_idx in range(active_count):
		if p_idx >= active_boards.size(): continue
		
		var board = active_boards[p_idx] 
		
		if not is_instance_valid(board): continue

		var base_size = board.size
		if base_size.x < 10 or base_size.y < 10:
			base_size = Vector2(818, 264)
		var real_size = base_size * board_scale
		board.scale = Vector2(board_scale, board_scale)
		# pivot_offset en coordonnées locales (avant scale)
		board.pivot_offset = base_size / 2.0
		var b_h = real_size.y  # hauteur (dimension courte)
		var b_w = real_size.x  # largeur (dimension longue)
		var rx = (screen_size.x / 2.0) - (b_h / 2.0) - margin
		var ry = (screen_size.y / 2.0) - (b_h / 2.0) - margin

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

		var ry_used = ry
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
			board.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
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

		
		
func _on_network_message(data: Dictionary) -> void:
	print("[JeuMulti] Réception réseau (mis en file d'attente) : ", data.get("action_reply", "?"))
	ajouter_message_file_attente(data)

func ajouter_message_file_attente(data: Dictionary) -> void:
	file_attente_messages.append(data)
	if not traitement_en_cours:
		_traiter_prochain_message()

func _traiter_prochain_message() -> void:
	traitement_en_cours = true

	while file_attente_messages.size() > 0:
		var data = file_attente_messages.pop_front()
		var action = data.get("action_reply", data.get("action", ""))

		match action:
			"sync_state":
				if _is_animating_dice:
					_pending_sync_data = data
				else:
					# ⏳ L'AWAIT MAGIQUE EST ICI : on fige la file le temps de l'animation !
					await _apply_sync_state(data)
					
			"turn_start":
				# 1. On attend quand même que les éléments techniques soient prêts/positionnés
				while _active_fly_animations > 0 or _is_animating_dice or is_rotating or not file_animations_activations.is_empty():
					await get_tree().process_frame
					
				# 2. Si c'est le lancement du jeu, on passe DIRECTEMENT
				if est_premier_tour:
					est_premier_tour = false  # On désactive pour les prochains tours
				else:
					if is_instance_valid(click_blocker): click_blocker.show()
					# La pause ne s'appliquera que durant la partie
					await get_tree().create_timer(1).timeout
					if is_instance_valid(click_blocker): click_blocker.hide()

				# 3. On lance l'affichage immédiat
				_show_turn_overlay(data)
					
			"buy_error":
				# 👇 SÉCURITÉ : Fermer les fenêtres d'achat globales quoi qu'il arrive
				if is_instance_valid(buy_confirm_panel): buy_confirm_panel.hide()
				if is_instance_valid(monument_menu): monument_menu.hide()

				var target_id = current_active_player_id if current_active_player_id != -1 else my_player_id
				var target_board: PlayerBoard = player_board_map.get(str(target_id), null)
				if is_instance_valid(target_board): 
					animer_erreur_argent(target_board)
				
				# Le secouement de carte du shop n'est joué que pour l'acheteur local
				if target_id == my_player_id and is_instance_valid(shop_popup.shop_board) and shop_popup.shop_board.get("last_clicked_slot"):

					animer_erreur_carte_shop(shop_popup.shop_board.last_clicked_slot)

			"request_purple_choice":
				# --- AJOUT : BARRAGE VISUEL ---
				# On force la file d'attente à patienter tant qu'une carte vole, 
				# qu'un dé roule ou qu'une activation est en cours.
				while _active_fly_animations > 0 or _is_animating_dice or is_rotating or not file_animations_activations.is_empty():
					await get_tree().process_frame
					
				var choice_type = data.get("choice_type", "")
				var active_id = int(data.get("active_player_id", -1))
				
				# Si c'est à nous de faire le choix (joueur actif)
				if active_id == my_player_id:
					if is_instance_valid(click_blocker): click_blocker.hide() # On libère l'écran pour cliquer
					
					var result = null
					match choice_type:
						"choose_player": result = await ask_choose_player() # Chaîne Télé
						"trade_cards": result = await ask_trade_cards()     # Centre d'affaires
						"give_card": result = await ask_give_card()         # Entreprise de Déménagement
						"demolish_monument": result = await ask_demolish_monument() # Travaux Publics
						
					# On renvoie la décision finale au serveur
					NetworkManager.envoyer({
						"action": "game_action",
						"game_action": "purple_card_choice",
						"result": result
					})

			"game_over":
				show_victory_screen(data.get("winner_name", "Un joueur"))
				
			"spectator_ui":
				var active_id = int(data.get("active_player_id", -1))
				# On ignore le message si c'est nous qui l'avons envoyé
				if active_id != my_player_id:
					if has_method("_handle_spectator_ui"):
						_handle_spectator_ui(data.get("interaction_type", ""), data.get("metadata", {}), active_id)

	# --- ANIMATION DE REMPLACEMENT DU SHOP ---
	if pending_shop_animation_index != -1 and is_instance_valid(shop_popup.shop_board):
		if is_instance_valid(click_blocker):
			click_blocker.show()

		await get_tree().process_frame

		var grid = shop_popup.shop_board.get("grid_container")
		if grid and pending_shop_animation_index < grid.get_child_count():
			var new_slot = grid.get_child(pending_shop_animation_index)
			var image_node = new_slot.get_node_or_null("Visual")

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
			


	traitement_en_cours = false


func _apply_sync_state(data: Dictionary) -> void:
	print("[JeuMulti] sync_state appliqué !")
	var new_players = data.get("players", {})
	var new_shop = data.get("shop", {})
	var activations = data.get("activations", [])
	
	_trigger_monument_animations(new_players)

	if activations.size() > 0:
		for act in activations:
			notifier_activation_multi(int(act["player_id"]), int(act["card_id"]), act.get("balance_changes", {}))

		await executer_animations_collectees()
		
		_trigger_card_move_animations(new_players)
		update_network_boards(new_players, false)
		update_network_shop(new_shop)
	else:
		_trigger_gold_animations(new_players)
		_trigger_card_move_animations(new_players)
		update_network_boards(new_players, false)
		update_network_shop(new_shop)

	# --- CORRECTION : Lancer l'animation une fois le shop mis à jour ---
	if pending_shop_animation_index != -1 and is_instance_valid(shop_popup.shop_board):
		if is_instance_valid(click_blocker):
			click_blocker.show()

		await get_tree().process_frame

		var grid = shop_popup.shop_board.get("grid_container")
		if grid and pending_shop_animation_index < grid.get_child_count():
			var new_slot = grid.get_child(pending_shop_animation_index)
			var image_node = new_slot.get_node_or_null("Visual")

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


func get_clean_file_name(card_name: String, color: int = -1) -> String:
	var prefix = ""
	match color:
		CardColor.Type.BLUE: prefix = "bleu_"
		CardColor.Type.GREEN: prefix = "vert_"
		CardColor.Type.RED: prefix = "rouge_"
		CardColor.Type.PURPLE: prefix = "violet_"
	var clean_name = card_name.to_lower().replace(" ", "_").replace("'", "_")
	# --- CORRECTION : Ajout du remplacement de ô et î ---
	clean_name = clean_name.replace("é", "e").replace("è", "e").replace("à", "a").replace("ô","o").replace("î","i")
	return prefix + clean_name

func get_lang_folder() -> String:
	if TranslationServer.get_locale().begins_with("en"):
		return "English"
	return "French"

func update_monument_menu(target_id: int = -1):
	if target_id == -1: target_id = my_player_id
	var is_mine = (target_id == my_player_id)
	
	var target_data = latest_players_data.get(str(target_id), {})
	var target_monuments = target_data.get("monuments", {})

	var monument_map = {
		Monument.MONUMENT_ID.Port:              {"node": "Port",              "file": "port"},
		Monument.MONUMENT_ID.Gare:              {"node": "Gare",              "file": "gare"},
		Monument.MONUMENT_ID.Centre_Commercial: {"node": "Centre commercial", "file": "centre_commercial"},
		Monument.MONUMENT_ID.Parc:              {"node": "Parc d'attraction", "file": "parc_dattraction"},
		Monument.MONUMENT_ID.Radio:             {"node": "Tour radio",        "file": "tour_radio"},
		Monument.MONUMENT_ID.Aeroport:          {"node": "Aéroport",          "file": "aéroport"}
	}
	
	for m_id in monument_map:
		var data = monument_map[m_id]
		var vbox = cards_monuments_container.get_node_or_null(data["node"])
		if not vbox: continue
		
		var tex_rect: TextureRect = vbox.get_child(0)
		var build_btn: TextureButton = vbox.get_child(1)
		
		var is_built = target_monuments.get(m_id, false) or target_monuments.get(str(m_id), false)
		
		var state = ""
		if data["file"] == data["file"].to_upper():
			state = "RECTO" if is_built else "VERSO"
		else:
			state = "recto" if is_built else "verso"
			
		var tex_path = "res://assets/Cards/" + get_lang_folder() + "/Monuments/" + data["file"] + "_" + state + ".png"
		var _tex = load(tex_path)
		if _tex: 
			tex_rect.texture = _tex
			
		for conn in build_btn.pressed.get_connections():
			build_btn.pressed.disconnect(conn.callable)

		build_btn.visible = not is_built and is_mine
		build_btn.pressed.connect(func(id=m_id, cost=data["cost"]):
			var current_balance = int(latest_players_data.get(str(my_player_id), {}).get("balance", 0))
			if current_balance < cost:
				monument_menu.hide()
				send_ui_interaction("buy_error", {"card_id": id, "is_monument": true})
				await get_tree().create_timer(0.15).timeout
				var my_board = player_board_map.get(str(my_player_id), null)
				if is_instance_valid(my_board): animer_erreur_argent(my_board)
				return
			monument_menu.hide()
			set_actions_enabled(false)
			network_client.request_build_monument(id)
			animer_shake_ecran()
		)

func _check_trade_valid() -> void:
	if trade_target_id != -1 and trade_their_card_id != -1 and trade_my_card_id != -1:
		btn_confirm_trade.disabled = false
		btn_confirm_trade.text = tr("Confirmer")

func _finish_fly_animation() -> void:
	_active_fly_animations = max(0, _active_fly_animations - 1)

func try_show_turn_overlay(data: Dictionary) -> void:
	# Au lieu d'afficher le tour, on le force à faire la queue avec les autres messages !
	data["action_reply"] = "turn_start"
	ajouter_message_file_attente(data)

func _show_turn_overlay(data: Dictionary) -> void:
	var active_id   = data.get("active_player_id", -1)
	current_active_player_id = int(active_id)
	var active_name = data.get("player_name", "Inconnu")
	var is_my       = (int(active_id) == int(my_player_id))

	set_actions_enabled(is_my)
	lbl_turn_announcement.text = tr("Tour de ") + active_name

	if turn_overlay:
		turn_overlay.move_to_front()
		turn_overlay.show()
		var btn_box = turn_overlay.get_node_or_null("VBoxContainer/HBoxContainer")
		if btn_box: btn_box.visible = is_my
		
		# --- NOUVEAU : On réactive la possibilité de cliquer sur les dés ---
		if btn_overlay_roll_1: btn_overlay_roll_1.disabled = false
		if btn_overlay_roll_2: btn_overlay_roll_2.disabled = true # Sécurité par défaut
		
		if is_my and btn_overlay_roll_2:
			var my_data      = latest_players_data.get(str(my_player_id), {})
			var my_monuments = my_data.get("monuments", {})
			
			# --- CORRECTION GARE ---
			var gare_id      = Monument.MONUMENT_ID.Gare
			var has_gare     = my_monuments.get(str(gare_id), false) or my_monuments.get(gare_id, false)
			
			btn_overlay_roll_2.visible = has_gare
			btn_overlay_roll_2.disabled = not has_gare

func _trigger_gold_animations(new_players: Dictionary) -> void:
	if latest_players_data.is_empty(): return
	for p_id_str in new_players:
		var old_balance = int(latest_players_data.get(p_id_str, {}).get("balance", 0))
		var new_balance = int(new_players[p_id_str].get("balance", 0))
		var delta = new_balance - old_balance
		if delta != 0 and player_board_map.has(p_id_str):
			animer_gain_gold(player_board_map[p_id_str], delta)

func _trigger_monument_animations(new_players: Dictionary) -> void:
	if latest_players_data.is_empty(): return

	for p_id_str in new_players:
		var old_monuments = latest_players_data.get(p_id_str, {}).get("monuments", {})
		var new_monuments = new_players.get(p_id_str, {}).get("monuments", {})

		for m_id in new_monuments:
			# On vérifie l'ancien et le nouvel état (en gérant les clés string/int)
			var was_built = old_monuments.get(m_id, false) or old_monuments.get(str(m_id), false)
			var is_built = new_monuments.get(m_id, false) or new_monuments.get(str(m_id), false)

			if is_built and not was_built:
				# 🔥 UN MONUMENT VIENT D'ÊTRE CONSTRUIT !
				
				# 1. On ferme les fenêtres pour tout le monde pour forcer l'attention sur le plateau
				if is_instance_valid(monument_menu): monument_menu.hide()
				if is_instance_valid(buy_confirm_panel): buy_confirm_panel.hide()
				
				# 2. On joue le tremblement chez les spectateurs 
				# (L'acheteur local a déjà lancé sa propre animation au moment du clic)
				if int(p_id_str) != my_player_id:
					animer_shake_ecran(20.0, 0.4)

func _trigger_card_move_animations(new_players: Dictionary) -> void:
	if latest_players_data.is_empty(): return

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

	var all_card_ids: Array = []
	for cid in old_snapshot: if not all_card_ids.has(cid): all_card_ids.append(cid)
	for cid in new_snapshot: if not all_card_ids.has(cid): all_card_ids.append(cid)

	for cid in all_card_ids:
		var donors:    Array = []
		var receivers: Array = []

		var all_players: Array = []
		for p in old_snapshot.get(cid, {}): if not all_players.has(p): all_players.append(p)
		for p in new_snapshot.get(cid, {}): if not all_players.has(p): all_players.append(p)

		for p_id_str in all_players:
			var old_qty = int(old_snapshot.get(cid, {}).get(p_id_str, 0))
			var new_qty = int(new_snapshot.get(cid, {}).get(p_id_str, 0))
			var diff = new_qty - old_qty
			if diff < 0: donors.append(p_id_str)
			elif diff > 0: receivers.append(p_id_str)

		if donors.size() == 1 and receivers.size() == 1:
			var donor_id   = int(donors[0])
			var receiver_id = int(receivers[0])
			animer_don_carte(donor_id, cid, receiver_id)
		
		# --- CORRECTION SPECTATEURS ---
		# Si quelqu'un gagne une carte sans qu'un autre joueur la perde = ACHAT AU SHOP !
		elif donors.size() == 0 and receivers.size() == 1:
			var receiver_id = int(receivers[0])
			var old_shop_qty = int(latest_shop_data.get(str(cid), 0))
			var new_shop_qty = old_shop_qty - 1
			
			if receiver_id != my_player_id:
				# On lance l'animation chez les spectateurs
				animer_achat_vers_main(cid, new_shop_qty, receiver_id)
				
			# Si la pile du shop tombe à zéro, on mémorise son index 
			# pour préparer le vol de la nouvelle carte (pour TOUT LE MONDE)
			if new_shop_qty <= 0 and is_instance_valid(shop_popup.shop_board):
				var slot = shop_popup.shop_board.card_slot_map.get(cid)
				if is_instance_valid(slot):
					pending_shop_animation_index = slot.get_index()

# ──────────────────────────────────────────────────────────────────────────────
# BOÎTE À OUTILS : ANIMATIONS JUICY
# ──────────────────────────────────────────────────────────────────────────────

const CARD_ANIMATION_SCENE = preload("res://scene/table/card_animation.tscn")
var file_animations_activations: Array = []

func _setup_tooltip_glows() -> void:
	var tooltip = get_node_or_null("%TooltipImage")
	
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
	float_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	float_text.z_index = 100

	var color_str = "gold" if montant > 0 else "red"
	var sign_str = "+" if montant > 0 else ""
	var icon_path = "res://assets/UI/coin.png"
	float_text.text = "[center][font=res://assets/Fonts/Exo_2/static/Exo2-BlackItalic.ttf][font_size=60][color=" + color_str + "]" + sign_str + str(montant) + "[/color] [img=60]" + icon_path + "[/img][/font_size][/font][/center]"

	add_child(float_text)

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

func force_dice_decision(action: String) -> void:
	_pending_dice_action = action
	dice_decision_made.emit(action)

func showResult(d1: int, d2: int, can_reroll: bool = false, spectator: bool = false, active_player_id: int = -1) -> String:
	var amount = 1 if d2 == 0 else 2
	var action = await play_dice_animation_enhanced(amount, d1, d2, can_reroll, spectator, active_player_id)
	return action

func play_dice_animation_enhanced(amount: int, final_d1: int, final_d2: int = 0, can_reroll: bool = false, spectator: bool = false, active_player_id: int = -1) -> String:
	
	# --- BARRAGE RÉSEAU : Le spectateur attend que l'écran soit libre ---
	while traitement_en_cours or not file_attente_messages.is_empty():
		await get_tree().process_frame

	# --- SÉCURITÉ ANTI-DOUBLONS : On génère un ID unique pour cette animation ---
	_dice_anim_counter += 1
	var my_anim_id = _dice_anim_counter

	if turn_overlay: turn_overlay.hide()

	if die_1 == null or result_overlay == null: return "keep"

	_is_animating_dice = true
	_pending_dice_action = "" 
	
	for d in mini_dice_array:
		if is_instance_valid(d): d.queue_free()
	mini_dice_array.clear()

	result_overlay.move_to_front()
	result_overlay.show()
	
	var btn_container = result_overlay.get_node_or_null("VBoxContainer/ButtonContainer")
	if btn_container:
		btn_container.visible = not spectator

	if btn_conserver: btn_conserver.hide()
	if btn_relancer: btn_relancer.hide()
	if btn_add_2:    btn_add_2.hide()

	die_1.show()
	if die_2: die_2.visible = (amount == 2)
	die_1.pivot_offset = die_1.size / 2.0
	if die_2: die_2.pivot_offset = die_2.size / 2.0

	var frames = 15
	var delay  = 0.05
	
	# --- ANIMATION ROULEMENT ---
	for i in range(frames):
		# --- TUEUR FANTÔME : Si une nouvelle animation a commencé, on tue celle-ci immédiatement ! ---
		if my_anim_id != _dice_anim_counter: 
			return "interrupted"

		if spectator and _pending_dice_action != "":
			break
			
		die_1.texture = dice_textures[randi() % 6]
		die_1.rotation_degrees = randf_range(-25, 25)
		if amount == 2 and die_2:
			die_2.texture = dice_textures[randi() % 6]
			die_2.rotation_degrees = randf_range(-25, 25)
		await get_tree().create_timer(delay).timeout
		if i > frames - 4: delay += 0.05

	# --- DERNIÈRE VÉRIFICATION AVANT LE RÉSULTAT FINAL ---
	if my_anim_id != _dice_anim_counter: 
		return "interrupted"

	# On assigne la vraie valeur (Le 5 du serveur ne sera plus jamais écrasé par un 1 aléatoire)
	die_1.rotation_degrees = 0.0
	die_1.texture = dice_textures[final_d1 - 1]
	if amount == 2 and die_2:
		die_2.rotation_degrees = 0.0
		die_2.texture = dice_textures[final_d2 - 1]

	var total = final_d1 + final_d2
	
	if is_instance_valid(click_blocker): 
		click_blocker.hide()

	if not spectator:
		var my_data = latest_players_data.get(str(my_player_id), {})
		
		# --- CORRECTION PORT ---
		var port_id = Monument.MONUMENT_ID.Port
		var has_port = my_data.get("monuments", {}).get(str(port_id), false) or my_data.get("monuments", {}).get(port_id, false)

		if btn_conserver: btn_conserver.show(); btn_conserver.disabled = false
		if btn_relancer: btn_relancer.visible = can_reroll; btn_relancer.disabled = false
		if btn_add_2:    btn_add_2.visible = (has_port and total >= 10); btn_add_2.disabled = false

	var action = ""
	if _pending_dice_action != "":
		action = _pending_dice_action
		_pending_dice_action = ""
	else:
		action = await dice_decision_made
		_pending_dice_action = ""

	if action == "reroll":
		result_overlay.hide()
		if not _pending_sync_data.is_empty():
			var data_to_apply = _pending_sync_data.duplicate()
			_pending_sync_data.clear()
			await _apply_sync_state(data_to_apply) # <--- AWAIT AJOUTÉ
			
		_is_animating_dice = false # <--- DÉPLACÉ APRÈS LE AWAIT
		return action

	is_rotating = true
	if is_instance_valid(click_blocker): click_blocker.show()
	
	var start_pos_1 = die_1.global_position
	var start_size_1 = die_1.size
	var start_pos_2 = die_2.global_position if (amount == 2 and die_2) else Vector2.ZERO
	var start_size_2 = die_2.size if (amount == 2 and die_2) else Vector2.ZERO

	result_overlay.hide()

	var target_board = player_board_map.get(str(active_player_id), null)
	if not is_instance_valid(target_board): 
		target_board = player_board_map.get(str(my_player_id), null)
		if not is_instance_valid(target_board):
			target_board = boards[0] 

# ====================================================================
	# --- L'ANCRE HBOX (Orientée selon le plateau, Sans Débordement) ---
	# ====================================================================
	var dice_anchor = HBoxContainer.new()
	dice_anchor.add_theme_constant_override("separation", 10)
	dice_anchor.z_index = 5
	dice_anchor.z_as_relative = false
	mini_dice_array.append(dice_anchor)

	var target_btn = target_board.get("btn_pass")

	if not spectator and is_instance_valid(target_btn) and target_btn.is_inside_tree() and target_btn.is_visible_in_tree():
		# JOUEUR ACTIF LOCAL (En bas)
		dice_anchor.grow_horizontal = Control.GROW_DIRECTION_END
		target_btn.add_child(dice_anchor)
		var vec_dir = Vector2(-110,-5)
		if total >= 10: vec_dir += Vector2(-30,0)
		if amount == 2: vec_dir += Vector2(-50,0)
		if action == "add2": vec_dir += Vector2(-50,0)
		dice_anchor.position = vec_dir
	else:
		# SPECTATEUR
		var ui_root = result_overlay.get_parent()
		if not is_instance_valid(ui_root): ui_root = self
		ui_root.add_child(dice_anchor)
		
		# On stocke TA logique exacte de calcul dans une fonction (Callable)
		var align_dice = func():
			if not is_instance_valid(dice_anchor) or not is_instance_valid(target_board): return
			var board_center = target_board.get_global_transform() * (target_board.size / 2.0)
			var rot = target_board.rotation
			
			var is_top = abs(rot) > 3.0
			var is_left = rot > 1.0 and rot < 2.0
			var is_right = rot < -1.0 and rot > -2.0

			if is_top:
				dice_anchor.rotation = 0
				dice_anchor.grow_horizontal = Control.GROW_DIRECTION_END
				dice_anchor.global_position = board_center + Vector2(-180, 160)
			elif is_left:
				dice_anchor.rotation = PI / 2.0 
				dice_anchor.grow_horizontal = Control.GROW_DIRECTION_END
				
				var vec_dir = Vector2(140,150)
				if total >= 10: vec_dir += Vector2(0,-30)
				if amount == 2: vec_dir += Vector2(0,-50)
				if action == "add2": vec_dir += Vector2(0,-50)
				dice_anchor.global_position = board_center + vec_dir
			elif is_right:
				dice_anchor.rotation = -PI / 2.0 
				dice_anchor.grow_horizontal = Control.GROW_DIRECTION_END
				var vec_dir = Vector2(-140,-130)
				if total >= 10: vec_dir += Vector2(0,30)
				if amount == 2: vec_dir += Vector2(0,50)
				if action == "add2": vec_dir += Vector2(0,50)
				dice_anchor.global_position = board_center + vec_dir
			else:
				dice_anchor.rotation = 0
				dice_anchor.grow_horizontal = Control.GROW_DIRECTION_BEGIN
				dice_anchor.global_position = board_center + Vector2(180, -180)

		# 1. On applique le placement initial
		align_dice.call()

		# 2. On connecte cette fonction au redimensionnement de l'écran
		var resize_sig = get_viewport().size_changed
		resize_sig.connect(align_dice)
		
		# 3. Très important : On déconnecte le signal quand le dé est détruit (queue_free) 
		# pour éviter les erreurs de "dangling Callable" en arrière-plan.
		dice_anchor.tree_exiting.connect(func(): 
			if resize_sig.is_connected(align_dice): 
				resize_sig.disconnect(align_dice)
		)

	# --- AJOUT DES ÉLÉMENTS DANS LA HBOX (Rendus invisibles temporairement) ---
	var dummy_1 = TextureRect.new()
	dummy_1.texture = die_1.texture
	dummy_1.custom_minimum_size = Vector2(40, 40)
	dummy_1.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dummy_1.size_flags_vertical = Control.SIZE_SHRINK_CENTER 
	dummy_1.modulate.a = 0.0 # On le cache !
	dice_anchor.add_child(dummy_1)

	var dummy_2 = null
	if amount == 2 and die_2:
		dummy_2 = TextureRect.new()
		dummy_2.texture = die_2.texture
		dummy_2.custom_minimum_size = Vector2(40, 40)
		dummy_2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		dummy_2.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dummy_2.modulate.a = 0.0 # On le cache !
		dice_anchor.add_child(dummy_2)

	var _font = load("res://assets/Fonts/Exo_2/static/Exo2-BlackItalic.ttf")
	var addTwo_lbl = null

	if action == "add2":
		total += 2
		addTwo_lbl = Label.new()
		addTwo_lbl.text = "+ 2"
		addTwo_lbl.add_theme_font_size_override("font_size", 34)
		addTwo_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		addTwo_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		addTwo_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER 
		addTwo_lbl.modulate.a = 0.0 # On le cache !
		if _font: addTwo_lbl.add_theme_font_override("font", _font)
		dice_anchor.add_child(addTwo_lbl)

	var result_lbl = Label.new()
	result_lbl.text = "= " + str(total)
	result_lbl.add_theme_font_size_override("font_size", 34)
	result_lbl.add_theme_color_override("font_color", Color.WHITE)
	result_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER 
	result_lbl.modulate.a = 0.0 # On le cache !
	if _font: result_lbl.add_theme_font_override("font", _font)
	dice_anchor.add_child(result_lbl)


	# ====================================================================
	# --- L'ASTUCE MAGIQUE : LE VOL DES CLONES ---
	# ====================================================================
	
	# 1. On attend une micro-seconde que Godot place la boîte pour avoir les coordonnées exactes !
	await get_tree().process_frame 

	var ui_root_anim = result_overlay.get_parent()
	if not is_instance_valid(ui_root_anim): ui_root_anim = self

	# 2. On crée des "Clones" volants hors de la boîte
	var fly_1 = TextureRect.new()
	fly_1.texture = die_1.texture
	fly_1.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fly_1.size = start_size_1
	fly_1.global_position = start_pos_1
	fly_1.z_index = 95
	ui_root_anim.add_child(fly_1)
	mini_dice_array.append(fly_1)

	var fly_2 = null
	if amount == 2 and die_2:
		fly_2 = TextureRect.new()
		fly_2.texture = die_2.texture
		fly_2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fly_2.size = start_size_2
		fly_2.global_position = start_pos_2
		fly_2.z_index = 95
		ui_root_anim.add_child(fly_2)
		mini_dice_array.append(fly_2)

	# 3. L'Animation de Vol de l'écran vers les cibles dans la boîte
	var anim_duration = 0.6
	var tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property(fly_1, "global_position", dummy_1.global_position, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(fly_1, "size", Vector2(40, 40), anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# --- AJOUT : Le dé pivote en volant pour s'aligner avec le plateau ---
	tween.tween_property(fly_1, "rotation", dice_anchor.rotation, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	if fly_2 and dummy_2:
		tween.tween_property(fly_2, "global_position", dummy_2.global_position, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(fly_2, "size", Vector2(40, 40), anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		# --- AJOUT : Le dé pivote en volant pour s'aligner avec le plateau ---
		tween.tween_property(fly_2, "rotation", dice_anchor.rotation, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	await tween.finished
	
	# 4. L'Atterrissage : On supprime les clones et on affiche les vrais dés instantanément
	if is_instance_valid(fly_1): fly_1.queue_free()
	if is_instance_valid(fly_2): fly_2.queue_free()

	dummy_1.modulate.a = 1.0
	if dummy_2: dummy_2.modulate.a = 1.0

	# 5. On fait apparaître le texte doucement
	var fade_tween = get_tree().create_tween().set_parallel(true)
	fade_tween.tween_property(result_lbl, "modulate:a", 1.0, 0.2)
	if addTwo_lbl: fade_tween.tween_property(addTwo_lbl, "modulate:a", 1.0, 0.2)

	await fade_tween.finished

	# --- NETTOYAGE ---
	is_rotating = false
	if is_instance_valid(click_blocker): click_blocker.hide()

	if not _pending_sync_data.is_empty():
		var data_to_apply = _pending_sync_data.duplicate()
		_pending_sync_data.clear()
		await _apply_sync_state(data_to_apply) # <--- AWAIT AJOUTÉ
		
	_is_animating_dice = false # <--- DÉPLACÉ APRÈS LE AWAIT


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
	# 1. SÉCURITÉ : On vérifie que le script est bien actif dans la scène
	if not is_inside_tree(): 
		return
		
	# 2. On vérifie que la caméra existe bien
	if not is_instance_valid(camera): 
		return 
	
	var original_offset = camera.offset 
	
	# 3. CORRECTION : On utilise le create_tween() du Node courant, pas celui du get_tree()
	var tween = create_tween()
	
	# Double sécurité au cas où le tween échoue à se créer
	if not tween: 
		return
		
	var steps = int(duree / 0.05)
	
	for i in range(steps):
		var offset = Vector2(randf_range(-intensite, intensite), randf_range(-intensite, intensite))
		tween.tween_property(camera, "offset", offset, 0.05).set_trans(Tween.TRANS_SINE)
		
	tween.tween_property(camera, "offset", original_offset, 0.05)

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

	var card_size = Vector2(shop_popup.shop_board.shop_card_w, shop_popup.shop_board.shop_card_h)
	var dummy = TextureRect.new()
	dummy.texture = preload("res://assets/UI/dos_card.png")
	dummy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dummy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dummy.size = card_size
	dummy.pivot_offset = card_size / 2.0
	dummy.z_index = 90

	var start_pos = deck_node.global_position + (deck_node.size / 2.0) - dummy.pivot_offset
	dummy.global_position = start_pos
	add_child(dummy)

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

func animer_achat_vers_main(card_id: int, quantity_in_shop: int = 1, target_player_id: int = -1) -> void:
	if target_player_id == -1: target_player_id = my_player_id

	var target_board: PlayerBoard = player_board_map.get(str(target_player_id), null)

	var shop_slot = null
	# Si c'est notre propre achat, on utilise le slot cliqué
	if target_player_id == my_player_id and is_instance_valid(shop_popup.shop_board) and is_instance_valid(shop_popup.shop_board.get("last_clicked_slot")):
		shop_slot = shop_popup.shop_board.last_clicked_slot
	else:
		# Pour les spectateurs, on retrouve le slot via son ID
		if is_instance_valid(shop_popup.shop_board) and shop_popup.shop_board.get("card_slot_map"):
			shop_slot = shop_popup.shop_board.card_slot_map.get(card_id)

	if not is_instance_valid(shop_slot): return

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
	dummy.z_index   = 90
	dummy.top_level = true
	dummy.global_position = visual_node.global_position if visual_node else shop_slot.global_position
	dummy.scale = Vector2(0.75, 0.75)

	# --- CORRECTION : On cache la carte seulement s'il n'en reste plus
	if visual_node and quantity_in_shop <= 0:
		visual_node.modulate.a = 0.0

	_active_fly_animations += 1
	if is_instance_valid(click_blocker): click_blocker.show()

	var anim_duration = 0.6
	var tween = create_tween().set_parallel(true)
	tween.tween_property(dummy, "global_position", target_pos, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(dummy, "scale",           Vector2(1.0, 1.0),    anim_duration).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(dummy, "rotation",        target_board.rotation, anim_duration).set_trans(Tween.TRANS_CUBIC)

	await tween.finished

	if is_instance_valid(anchor):
		dummy.get_parent().remove_child(dummy)
		anchor.add_child(dummy)
		dummy.top_level = false
		dummy.position  = Vector2(current_count * stack_gap, 0)
		dummy.rotation  = 0

	if is_instance_valid(click_blocker): click_blocker.hide()
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

	if is_instance_valid(shop_popup.shop_board) and shop_popup.shop_board.has_method("clear_selection"):
		tween.tween_callback(func(): shop_popup.shop_board.clear_selection())

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
	b1_deltas[p1_color] -= 1; b1_deltas[p2_color] += 1
	b2_deltas[p2_color] -= 1; b2_deltas[p1_color] += 1

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
	dummy1.z_index = 10;  dummy1.top_level = true
	dummy2.z_index = 10;  dummy2.top_level = true
	dummy1.global_position = noeud1.global_position;  dummy1.rotation = board1.rotation
	dummy2.global_position = noeud2.global_position; dummy2.rotation = board2.rotation
	noeud1.modulate.a = 0.0
	noeud2.modulate.a = 0.0

	if is_instance_valid(click_blocker): click_blocker.show()

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
	
	if is_instance_valid(click_blocker): click_blocker.hide()

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
	dummy.z_index   = 10
	dummy.top_level = true
	dummy.global_position = noeud_carte.global_position
	dummy.rotation        = board_source.rotation
	noeud_carte.modulate.a = 0.0

	if is_instance_valid(click_blocker): click_blocker.show()

	tween.tween_property(dummy, "global_position", end_pos,              anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(dummy, "rotation",        board_cible.rotation, anim_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(dummy, "scale",           Vector2(1.2, 1.2),    anim_duration / 2.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(dummy, "scale",           Vector2(1.0, 1.0),    anim_duration / 2.0).set_delay(anim_duration / 2.0)

	await tween.finished

	if is_instance_valid(anchor_cible):
		dummy.get_parent().remove_child(dummy)
		anchor_cible.add_child(dummy)
		dummy.top_level = false
		dummy.position  = Vector2(count_cible * stack_gap, 0)
		dummy.rotation  = 0
		dummy.setup_card(card_data, board_cible.get_board_tooltip_direction())

	if is_instance_valid(click_blocker): click_blocker.hide()

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

	if has_valid_cards:
		await get_tree().create_timer(0.35).timeout # Durée de l'animation de montée

	# 3. PHASE D'EFFETS : On exécute les fonctions de gain (or, vol, etc.)
	for data in activations:
		var effet = data.get("effet_callable")
		if effet is Callable and effet.is_valid():
			effet.call()

	# Pause de "Juice" : on laisse le temps de voir les pièces voler et les textes clignoter
	await get_tree().create_timer(1.2).timeout

	# 4. PHASE DE DESCENTE : Tout le monde redescend
	var has_valid_cards_descente = false
	for data in activations:
		var c = data.get("carte_visuelle")
		if is_instance_valid(c) and c.has_method("animer_descente"):
			c.animer_descente()
			has_valid_cards_descente = true

	if has_valid_cards_descente:
		await get_tree().create_timer(0.35).timeout # Durée de l'animation de descente

	# 5. LIBÉRATION : Le jeu peut reprendre
	if is_instance_valid(click_blocker):
		click_blocker.hide()

func executer_animations_collectees() -> void:
	if not file_animations_activations.is_empty():
		await declencher_animations_activation(file_animations_activations)
		file_animations_activations.clear()

func notifier_activation_multi(player_id: int, card_id: int, balance_changes: Dictionary = {}) -> void:
	var board_visuel: PlayerBoard = player_board_map.get(str(player_id), null)
	if not is_instance_valid(board_visuel): return

	var noeud_carte = board_visuel.get_card_node(card_id)
	var card_data = CardFactory.get_card(card_id)

	file_animations_activations.append({
		"carte_visuelle": noeud_carte,
		"couleur": card_data.get_color() if card_data else -1,
		"effet_callable": func():
			for p_id_str in balance_changes:
				var amount = int(balance_changes[p_id_str])
				var board = player_board_map.get(str(p_id_str), null)
				if is_instance_valid(board):
					animer_gain_gold(board, amount)
					if board.get("lbl_gold"):
						board.lbl_gold.text = str(int(board.lbl_gold.text) + amount)
	})

func hook_all_hovers() -> void:
	# 1. Cartes du Shop
	if is_instance_valid(shop_popup.shop_board) and shop_popup.shop_board.get("card_slot_map"):
		for cid in shop_popup.shop_board.card_slot_map:
			var slot = shop_popup.shop_board.card_slot_map[cid]
			_attach_hover_signals(slot, cid, -1)
			
	# 2. Cartes des Joueurs
	for p_id_str in player_board_map:
		var board = player_board_map[p_id_str]
		if not is_instance_valid(board): continue
		var deck = latest_players_data.get(p_id_str, {}).get("deck", [])
		for entry in deck:
			if typeof(entry) == TYPE_ARRAY:
				var cid = int(entry[0])
				var c_node = board.get_card_node(cid)
				_attach_hover_signals(c_node, cid, int(p_id_str))

func _attach_hover_signals(node: Control, cid: int, owner_id: int) -> void:
	if not is_instance_valid(node): return
	var target = node.get_node_or_null("Visual")
	if not is_instance_valid(target): target = node
	
	# Empêche de connecter les signaux plusieurs fois
	if target.has_meta("hover_hooked"): return
	target.set_meta("hover_hooked", true)
	
	if target.has_signal("mouse_entered"):
		target.mouse_entered.connect(_on_card_hovered.bind(cid, owner_id))
		target.mouse_exited.connect(_on_card_unhovered.bind(cid, owner_id))

func _on_card_hovered(cid: int, owner_id: int) -> void:
	if current_active_player_id == my_player_id:
		send_ui_interaction("hover_card", {"card_id": cid, "owner_id": owner_id})
		
func _on_card_unhovered(cid: int, owner_id: int) -> void:
	if current_active_player_id == my_player_id:
		send_ui_interaction("unhover_card", {"card_id": cid, "owner_id": owner_id})
		 
func _handle_spectator_ui(type: String, meta: Dictionary, active_id: int) -> void:
	match type:
		"open_monuments":
			update_monument_menu(active_id)
			monument_menu.move_to_front()
			monument_menu.show()
		"close_monuments":
			monument_menu.hide()
		"open_shop_preview":
			var cid = int(meta.get("card_id", -1))
			_on_shop_card_clicked(cid, true) # true = mode spectateur (sans bouton Acheter)
		"close_shop_preview":
			buy_confirm_panel.hide()
		"hover_card":
			_apply_spectator_hover(int(meta.get("card_id", -1)), int(meta.get("owner_id", -1)), true)
		"unhover_card":
			_apply_spectator_hover(int(meta.get("card_id", -1)), int(meta.get("owner_id", -1)), false)
		"buy_error":
			var cid = int(meta.get("card_id", -1))
			var is_monument = meta.get("is_monument", false)
			
			# 👇 AJOUT : On ferme immédiatement le panel correspondant chez le spectateur
			if is_monument and is_instance_valid(monument_menu):
				monument_menu.hide()
			elif not is_monument and is_instance_valid(buy_confirm_panel):
				buy_confirm_panel.hide()
			
			# 1. On secoue l'argent du joueur qui a essayé d'acheter
			var board = player_board_map.get(str(active_id), null)
			if is_instance_valid(board):
				animer_erreur_argent(board)
				
			# 2. Si c'est une carte du shop, on fait clignoter la carte en rouge
			if not is_monument and is_instance_valid(shop_popup.shop_board) and shop_popup.shop_board.get("card_slot_map"):
				var slot = shop_popup.shop_board.card_slot_map.get(cid)
				if is_instance_valid(slot):
					animer_erreur_carte_shop(slot)
					

func _apply_spectator_hover(cid: int, owner_id: int, show: bool) -> void:
	var target_node = null
	
	if owner_id == -1: # C'est le shop
		if is_instance_valid(shop_popup.shop_board) and shop_popup.shop_board.get("card_slot_map"):
			target_node = shop_popup.shop_board.card_slot_map.get(cid)
	else: # C'est un joueur
		var board = player_board_map.get(str(owner_id), null)
		if is_instance_valid(board):
			target_node = board.get_card_node(cid)
			
	if not is_instance_valid(target_node): return
	
	if show:
		appliquer_halo_jaune(target_node)
	else:
		retirer_halo_jaune(target_node)

func appliquer_halo_jaune(node: Control) -> void:
	if not is_instance_valid(node) or node.has_node("SpectatorGlow"): return
	
	var p = Panel.new()
	p.name = "SpectatorGlow"
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.show_behind_parent = true
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.set_border_width_all(5)
	style.border_color = Color(1.0, 0.84, 0.0, 1.0) # Jaune/Or vif
	style.shadow_color = Color(1.0, 0.84, 0.0, 0.7)
	style.shadow_size = 25
	style.set_corner_radius_all(10)
	p.add_theme_stylebox_override("panel", style)
	node.add_child(p)
	
	# Effet de pulsation (Juice)
	var tween = create_tween().set_loops(0)
	tween.tween_property(p, "modulate:a", 0.4, 0.5)
	tween.tween_property(p, "modulate:a", 1.0, 0.5)

func retirer_halo_jaune(node: Control) -> void:
	if not is_instance_valid(node): return
	var glow = node.get_node_or_null("SpectatorGlow")
	if is_instance_valid(glow):
		glow.queue_free()


func _on_shop_button_pressed() -> void:
	shop_popup.open_network(latest_shop_data)
