extends Node

var test_player: Player
var test_shop: Shop
@onready var lbl_gold: Label = %LblGold
@onready var lbl_stats: Label = %LblStats
@onready var shop_container: GridContainer = %ShopContainer
@onready var btn_roll_1: Button = %BtnRoll1
@onready var btn_roll_2: Button = %BtnRoll2
@onready var lbl_dice: Label = %LblDice
@onready var deck_container: HFlowContainer = %DeckContainer

func _ready() -> void:
	test_player = Player.new("TestBot", 1, 5)
	test_shop = Shop.new()
	
	$AddGold.pressed.connect(_on_add_gold_pressed)
	$RemoveGold.pressed.connect(_on_remove_gold_pressed)
	
	setup_monument_button($BuildGare, Monument.MONUMENT_ID.Gare)
	setup_monument_button($BuildCentreCommercial, Monument.MONUMENT_ID.Centre_Commercial)
	setup_monument_button($BuildParcAttraction, Monument.MONUMENT_ID.Parc)
	setup_monument_button($BuildRadio, Monument.MONUMENT_ID.Radio)
	setup_monument_button($BuildAeroport, Monument.MONUMENT_ID.Aeroport)
	setup_monument_button($BuildPort, Monument.MONUMENT_ID.Port)
	
	btn_roll_2.disabled = true
	
	print("\n=== SANDBOX STARTED ===")
	print_player_stats()
	update_shop_ui()
	update_deck_ui()
	
func _on_roll_1_pressed() -> void:
	var d1 = randi_range(1, 6)
	
	lbl_dice.text = "Rolled: " + str(d1)
	print("\nRolled 1 Die: ", d1)
	
	# TRIGGER EFFECTS A VOIR AVEC CLEMENT
	
func _on_roll_2_pressed() -> void:
	var d1 = randi_range(1, 6)
	var d2 = randi_range(1, 6)
	var total = d1 + d2
	
	lbl_dice.text = "Rolled: " + str(d1) + " + " + str(d2) + " = " + str(total)
	print("\nRolled 2 Dice: ", d1, " + ", d2, " = ", total)
	
	# TRIGGER EFFECTS A VOIR AVEC CLEMENT
	
func setup_monument_button(btn: Button, monu_id: int) -> void:
	btn.toggle_mode = true
	
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
	
	btn.pressed.connect(_on_any_monument_pressed.bind(monu_id, btn))

func _on_any_monument_pressed(monu_id: int, clicked_btn: Button) -> void:
	var monu_data = _get_monument_data(monu_id)
	print("\n[?] Attempting to build: ", monu_data.name, " (Cost: ", monu_data.cost, ")...")
	
	var monu = Monument.new()
	monu.id = monu_id
	monu.cost = monu_data.cost
	
	if test_player.monumentIsActive(monu_id):
		print("FAILED: Monument already built!")
		clicked_btn.button_pressed = true
		return
	
	if test_player.constructMonument(monu):
		print("SUCCESS: Built the ", monu_data.name, "!")
		clicked_btn.button_pressed = true
		clicked_btn.text = monu_data.name + " (Owned)"
		
		if monu_id == Monument.MONUMENT_ID.Gare:
			btn_roll_2 .disabled = false
			print("Unlocked 2 Dice!")
	else:
		print("FAILED: Not enough gold!")
		clicked_btn.button_pressed = false
		
	print_player_stats()

func _get_monument_data(m_id: int) -> Dictionary:
	match m_id:
		Monument.MONUMENT_ID.Gare: return {"name": "Gare", "cost": 4}
		Monument.MONUMENT_ID.Centre_Commercial: return {"name": "Centre Commercial", "cost": 10}
		Monument.MONUMENT_ID.Parc: return {"name": "Parc d'Attractions", "cost": 16}
		Monument.MONUMENT_ID.Radio: return {"name": "Tour Radio", "cost": 22}
		Monument.MONUMENT_ID.Port: return {"name": "Port", "cost": 2}
		Monument.MONUMENT_ID.Aeroport: return {"name": "Aéroport", "cost": 30}
		_: return {"name": "Unknown", "cost": 999}

# -----------------------------------------
# GOLD BUTTONS
# -----------------------------------------
func _on_add_gold_pressed() -> void:
	test_player.recieveGold(5)
	print("\n[+] Added 5 Gold.")
	print_player_stats()

func _on_remove_gold_pressed() -> void:
	test_player.loseGold(2)
	print("\n[-] Lost 2 Gold.")
	print_player_stats()

# -----------------------------------------
# SHOP BUTTON
# -----------------------------------------
func _on_buy_pressed(card_id: int) -> void:
	print("\n[?] Attempting to buy Card ID: ", card_id, "...")
	
	var card = test_player.get_card_from_factory(card_id)
	
	if card == null:
		print("CRITICAL ERROR: The Factory returned null for ID ", card_id, "! Check your adapter function.")
		return 
	
	if test_shop.available(card_id):
		if test_player.buyCard(card):
			test_shop.removeCardFromStock(card_id)
			print("SUCCESS: Bought ", card.name)
			update_shop_ui()
			update_deck_ui()
		else:
			print("FAILED: Not enough gold!")
	else:
		print("FAILED: Card not in the shop right now.")
		
	print_player_stats()
	
func update_shop_ui() -> void:
	for child in shop_container.get_children():
		child.queue_free()
		
	for slot in test_shop.shop:
		var btn = Button.new()
		
		btn.text = "ID: " + str(slot.id) + "\nQty: " + str(slot.quantity)
		btn.custom_minimum_size = Vector2(80, 80)
		
		btn.pressed.connect(_on_buy_pressed.bind(slot.id))
		
		shop_container.add_child(btn)
		
func update_deck_ui() -> void:
	for child in deck_container.get_children():
		deck_container.remove_child(child)
		child.queue_free()
		
	for instance in test_player.deck:
		if typeof(instance) != TYPE_ARRAY:
			continue
		
		var card_id = instance[0]
		var quantity = instance[1]
		
		var card_data = test_player.get_card_from_factory(card_id)
		
		if card_data != null:
			for i in range(quantity):
				var card_visual = Button.new()
				card_visual.text = str(card_data.activation) + "\n" + card_data.name
				
				card_visual.custom_minimum_size = Vector2(100, 140)
				
				card_visual.disabled = true
				card_visual.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				
				var style = StyleBoxFlat.new()
				
				match card_data.color:
					CardColor.Type.BLUE: style.bg_color = Color(0.2, 0.4, 0.8)
					CardColor.Type.GREEN: style.bg_color = Color(0.2, 0.6, 0.2)
					CardColor.Type.RED: style.bg_color = Color(0.8, 0.2, 0.2)
					CardColor.Type.PURPLE: style.bg_color = Color(0.6, 0.2, 0.8)
					
				card_visual.add_theme_stylebox_override("disabled", style)
				card_visual.add_theme_color_override("front_disabled_color", Color.WHITE)
				
				deck_container.add_child(card_visual)
				

func print_player_stats() -> void:
	lbl_gold.text = "Gold: " + str(test_player.balance)
	lbl_stats.text = "Establishments: " + str(test_player.establishmentCount) + "\nMonuments: " + str(test_player.monumentCount)
	
	print("--- PLAYER STATS ---")
	print("Gold: ", test_player.balance)
	print("Establishments: ", test_player.establishmentCount)
	print("Monuments: ", test_player.monumentCount)
	print("Deck Array: ", test_player.deck)
	print("--------------------")
