extends Node

# --- GESTION RESEAU ---
var network_client: GameClient
var my_player_id: int
var latest_players_data: Dictionary = {}
var latest_shop_data: Dictionary = {}

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

@onready var turn_overlay: ColorRect = $TurnOverlay
@onready var lbl_turn_announcement: Label = %LblTurnAnnouncement
@onready var btn_overlay_roll_1: TextureButton = $TurnOverlay/VBoxContainer/HBoxContainer/Roll1Die
@onready var btn_overlay_roll_2: TextureButton = $TurnOverlay/VBoxContainer/HBoxContainer/Roll2Dices

var result_overlay: ColorRect
var die_1: TextureRect
var die_2: TextureRect
var btn_conserver: TextureButton
var btn_relancer: TextureButton
var btn_add_2: TextureButton
var mini_dice_array: Array = []

var dice_textures = [
	preload("res://assets/UI/die_one.png"), preload("res://assets/UI/die_two.png"),
	preload("res://assets/UI/die_three.png"), preload("res://assets/UI/die_four.png"),
	preload("res://assets/UI/die_five.png"), preload("res://assets/UI/die_six.png")
]

# Popups
@onready var monument_menu: ColorRect = %MonumentOverlay
@onready var close_menu: TextureButton = %closeButton 
@onready var cards_monuments_container = $MonumentOverlay/MainContainer/CardsMonumentsContainer
@onready var victory_screen: PanelContainer = $VictoryScreen
@onready var lbl_winner_name: Label = %LblWinnerName
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
@onready var buy_confirm_panel: ColorRect = %ConfirmCardBuyPanel
@onready var confirm_card_buy: Button = %ConfirmCardBuy
@onready var cancel_card_buy: Button = %CancelCardBuy

# Variables de stockage temporaire pour les popups
var trade_target_id: int = -1
var trade_their_card_id: int = -1
var trade_my_card_id: int = -1
var give_target_id: int = -1
var give_card_id: int = -1
var selected_shop_card_id: int = -1

func _ready() -> void:
	network_client = GameClient.new()
	network_client.gameplayScreen = self
	add_child(network_client)
	
	my_player_id = NetworkManager.get_joueur_id()
	var game_id = get_tree().get_meta("game_id", 0)
	var ordre_joueurs = get_tree().get_meta("ordre_joueurs", [])
	
	# Passe les infos à GameClient
	network_client.game_id = game_id
	network_client.ordre_joueurs = ordre_joueurs
	
	_find_dice_ui_nodes()
	_force_overlays_to_front()
	
	if btn_overlay_roll_1: btn_overlay_roll_1.pressed.connect(func(): network_client.request_roll_dice(1))
	if btn_overlay_roll_2: btn_overlay_roll_2.pressed.connect(func(): network_client.request_roll_dice(2))
	
	%ConfirmCardBuy.pressed.connect(_on_confirm_buy_shop_pressed)
	%CancelCardBuy.pressed.connect(func(): buy_confirm_panel.hide())
	close_menu.pressed.connect(func(): monument_menu.hide())
	
	if btn_conserver: btn_conserver.pressed.connect(func(): dice_decision_made.emit("keep"))
	if btn_relancer: btn_relancer.pressed.connect(func(): dice_decision_made.emit("reroll"))
	if btn_add_2: btn_add_2.pressed.connect(func(): dice_decision_made.emit("add2"))
	
	%ConfirmTrade.pressed.connect(func(): trade_completed.emit([trade_my_card_id, trade_target_id, trade_their_card_id]))
	%ConfirmGive.pressed.connect(func(): give_card_completed.emit([give_card_id, give_target_id]))
	
	for board in boards:
		if is_instance_valid(board):
			board.pass_turn_requested.connect(func(): network_client.request_skip_turn())
			board.open_monuments_requested.connect(_on_open_monuments_pressed)

	get_viewport().size_changed.connect(_on_window_resized)
	_on_window_resized.call_deferred()

func set_actions_enabled(can_act: bool) -> void:
	for board in boards:
		if is_instance_valid(board): board.set_actions_enabled(can_act)
	if is_instance_valid(shop_board): shop_board.set_actions_enabled(can_act)

func update_network_boards(players_data: Dictionary):
	latest_players_data = players_data
	
	var player_ids = players_data.keys()
	var my_id_str = str(my_player_id)
	
	if player_ids.has(my_id_str):
		player_ids.erase(my_id_str)
		player_ids.push_front(my_id_str) 
		
	for b in boards:
		b.hide()
		
	for i in range(player_ids.size()):
		if i < boards.size():
			var board = boards[i]
			var p_id = player_ids[i]
			var data = players_data[p_id]
			
			board.show()
			
			if board.has_method("setup_network"):
				var is_me = (p_id == my_id_str)
				board.setup_network(data, is_me)

func update_network_shop(shop_data: Dictionary):
	latest_shop_data = shop_data
	
	if is_instance_valid(shop_board) and shop_board.has_method("update_network_shop"):
		shop_board.update_network_shop(shop_data)

func show_victory_screen(winner_name: String) -> void:
	set_actions_enabled(false)
	lbl_winner_name.text = "🏆 " + winner_name + " " + tr("GAGNE!")
	victory_screen.move_to_front()
	victory_screen.show()

func _on_shop_card_clicked(card_id: int) -> void:
	selected_shop_card_id = card_id
	buy_confirm_panel.move_to_front()
	buy_confirm_panel.show()

func _on_confirm_buy_shop_pressed() -> void:
	buy_confirm_panel.hide()
	monument_menu.hide()
	
	var card_data = CardFactory.get_card(selected_shop_card_id)
	if card_data is Monument:
		network_client.request_build_monument(selected_shop_card_id)
	else:
		network_client.request_buy_card(selected_shop_card_id)

func _on_open_monuments_pressed() -> void:
	monument_menu.move_to_front()
	monument_menu.show()

func showResult(d1: int, d2: int, can_reroll: bool = false) -> String:
	var amount = 1 if d2 == 0 else 2
	
	var action = await play_dice_animation(amount, d1, d2, can_reroll)
	
	return action

func play_dice_animation(amount: int, final_d1: int, final_d2: int = 0, can_reroll: bool = false) -> String:
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
		btn.text = data.get("username", tr("Joueur ") + str(p_id)) + "\n" + tr("Or: ") + str(data.get("balance", 0))
		btn.pressed.connect(func(): player_chosen.emit(p_id))
		player_buttons_container.add_child(btn)
		
	var chosen_target_id = await player_chosen
	choose_player_panel.hide()
	return chosen_target_id

func ask_trade_cards() -> Array:
	trade_panel.move_to_front()
	trade_panel.show()
	btn_confirm_trade.disabled = true
	trade_target_id = -1
	trade_their_card_id = -1
	trade_my_card_id = -1
	
	for c in trade_opponents.get_children(): c.queue_free()
	
	for p_id_str in latest_players_data:
		var p_id = int(p_id_str)
		if p_id == my_player_id: continue
		var data = latest_players_data[p_id_str]
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(130, 180)
		btn.text = data.get("username", "Joueur " + str(p_id))
		btn.pressed.connect(func(): _on_trade_opponent_selected(p_id, data))
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
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(130, 180)
			btn.text = card.name
			btn.pressed.connect(func():
				if is_mine: trade_my_card_id = card_id
				else: trade_their_card_id = card_id
				if trade_target_id != -1 and trade_their_card_id != -1 and trade_my_card_id != -1:
					btn_confirm_trade.disabled = false
			)
			container.add_child(btn)

func ask_give_card() -> Array:
	give_panel.move_to_front()
	give_panel.show()
	var result = await give_card_completed
	give_panel.hide()
	return result

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
