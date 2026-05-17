extends Control
class_name PlayerBoard

signal pass_turn_requested
signal open_monuments_requested

var player_data = null
var prev_deck: Dictionary = {}       # {card_id: quantity} — for buy animation
var prev_monuments: Dictionary = {}  # {m_id: bool} — for build animation

@onready var lbl_name: Label = %PlayerLabel
@onready var monument_icons: GridContainer = %MonumentIconContainer
@onready var lbl_gold: Label = %PlayerMoney
@onready var btn_pass: Button = get_node_or_null("%PasserLeTourButton")
@onready var btn_monu: TextureButton = get_node_or_null("%MonumentButton")

@onready var active_stats_box = get_node_or_null("MainColumn/TopBar/ActivePlayerStats")

@onready var piles = {
	CardColor.Type.BLUE: %BluePileBottom,
	CardColor.Type.GREEN: %GreenPileBottom,
	CardColor.Type.RED: %RedPileBottom,
	CardColor.Type.PURPLE: %PurplePileBottom
}

const CARD_SCENE = preload("res://scene/table/card_animation.tscn")

func _ready() -> void:
	var top_bar = get_node_or_null("MainColumn/TopBar")
	var monu_zone = get_node_or_null("MonumentZone")
	if top_bar: top_bar.modulate.a = 0.0
	if monu_zone: monu_zone.modulate.a = 0.0
	
	if btn_pass: btn_pass.pressed.connect(func(): pass_turn_requested.emit())
	if btn_monu: btn_monu.pressed.connect(func(): open_monuments_requested.emit())
	
	var main_col = get_node_or_null("MainColumn")
	if main_col:
		main_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		main_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
		main_col.set("alignment", BoxContainer.ALIGNMENT_CENTER)

	if active_stats_box:
		active_stats_box.resized.connect(func(): active_stats_box.pivot_offset = active_stats_box.size / 2.0)
		
	if btn_pass: btn_pass.text = tr("PASSER_LE_TOUR")

# ----------------------------------------------------------------------
# ROTATION (Sécurisée pour les Grilles)
# ----------------------------------------------------------------------
func _process(_delta: float) -> void:
	var normalized_rot = wrapf(self.rotation, -PI, PI)
	var target_rot = -self.rotation if abs(normalized_rot) > PI * 0.8 else 0.0

	if active_stats_box and is_inside_tree():
		active_stats_box.rotation = target_rot
		
	if monument_icons and is_inside_tree():
		for icon in monument_icons.get_children():
			if icon is Control: 
				if icon.size != Vector2.ZERO:
					icon.pivot_offset = icon.size / 2.0
				icon.rotation = target_rot

# ----------------------------------------------------------------------
# NEW SETUP: Reads from a Network Dictionary instead of a Player object!
# ----------------------------------------------------------------------
func setup_network(data: Dictionary, is_active_player: bool):
	var top_bar = get_node_or_null("MainColumn/TopBar")
	var monu_zone = get_node_or_null("MonumentZone")
	if top_bar: top_bar.modulate.a = 0.0
	if monu_zone: monu_zone.modulate.a = 0.0
	
	self.player_data = data
	
	var monument_array = data.get("monuments", {}) 
	
	var monument_nodes = {
		Monument.MONUMENT_ID.Aeroport: {"unbuild": "AéroportUnbuild", "build": "AéroportBuild"},
		Monument.MONUMENT_ID.Port: {"unbuild": "PortUnbuild", "build": "PortBuild"},
		Monument.MONUMENT_ID.Gare: {"unbuild": "GareUnbuild", "build": "GareBuild"},
		Monument.MONUMENT_ID.Centre_Commercial: {"unbuild": "CentreCommercialUnbuild", "build": "CentreCommercialBuild"},
		Monument.MONUMENT_ID.Parc: {"unbuild": "ParcDattractionUnbuild", "build": "ParcDattractionBuild"},
		Monument.MONUMENT_ID.Radio: {"unbuild": "TourRadioUnbuild", "build": "TourRadioBuild"}
	}

	for m_id in monument_nodes:
		var info = monument_nodes[m_id]
		var unbuild_node = find_child(info["unbuild"], true, false)
		var build_node = find_child(info["build"], true, false)

		var is_built = monument_array.get(str(m_id), false)
		var was_built = prev_monuments.get(m_id, false)

		if unbuild_node: unbuild_node.visible = not is_built
		if build_node:
			build_node.visible = is_built
			# Animate monument becoming built: golden flash fade-in
			if is_built and not was_built:
				build_node.modulate = Color(1.5, 1.5, 0.5, 0.0)  # start bright/golden, invisible
				var mt = build_node.create_tween()
				mt.tween_property(build_node, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5).set_trans(Tween.TRANS_CUBIC)

		prev_monuments[m_id] = is_built

	if btn_pass: btn_pass.visible = is_active_player
	if btn_monu: btn_monu.visible = is_active_player

	update_info()
	update_deck()

	var tween = create_tween()
	if top_bar: tween.parallel().tween_property(top_bar, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_SINE)
	if monu_zone: tween.parallel().tween_property(monu_zone, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_SINE)

# Setup pour partie locale

func setup(player_data, is_active_player: bool):
	var top_bar = get_node_or_null("MainColumn/TopBar")
	var monu_zone = get_node_or_null("MonumentZone")
	if top_bar: top_bar.modulate.a = 0.0
	if monu_zone: monu_zone.modulate.a = 0.0
	
	self.player_data = player_data
	
	var monument_nodes = {
		Monument.MONUMENT_ID.Aeroport: {"unbuild": "AéroportUnbuild", "build": "AéroportBuild"},
		Monument.MONUMENT_ID.Port: {"unbuild": "PortUnbuild", "build": "PortBuild"},
		Monument.MONUMENT_ID.Gare: {"unbuild": "GareUnbuild", "build": "GareBuild"},
		Monument.MONUMENT_ID.Centre_Commercial: {"unbuild": "CentreCommercialUnbuild", "build": "CentreCommercialBuild"},
		Monument.MONUMENT_ID.Parc: {"unbuild": "ParcDattractionUnbuild", "build": "ParcDattractionBuild"},
		Monument.MONUMENT_ID.Radio: {"unbuild": "TourRadioUnbuild", "build": "TourRadioBuild"}
	}

	for m_id in monument_nodes:
		var info = monument_nodes[m_id]
		var unbuild_node = find_child(info["unbuild"], true, false)
		var build_node = find_child(info["build"], true, false)
		var is_built = player_data.monumentIsActive(m_id)
		
		if unbuild_node: unbuild_node.visible = not is_built
		if build_node: build_node.visible = is_built

	if btn_pass: btn_pass.visible = is_active_player
	if btn_monu: btn_monu.visible = is_active_player

	update_info()
	update_deck()
	
	var tween = create_tween()
	if top_bar: tween.parallel().tween_property(top_bar, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_SINE)
	if monu_zone: tween.parallel().tween_property(monu_zone, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_SINE)

# ----------------------------------------------------------------------
# RESTE DE LA LOGIQUE
# ----------------------------------------------------------------------
func update_info() -> void:
	if player_data == null: return
	
	if player_data is Dictionary:
		if player_data.is_empty(): return
		lbl_name.text = player_data.get("username", "Unknown")
		lbl_gold.text = str(int(player_data.get("balance", 0)))
	else:
		lbl_name.text = player_data.username
		lbl_gold.text = str(player_data.balance)

func set_actions_enabled(can_act: bool) -> void:
	if btn_pass: btn_pass.disabled = !can_act
	if btn_monu: btn_monu.disabled = !can_act

func update_deck() -> void:
	if player_data == null: return

	for pile in piles.values():
		var anchor = pile.get_node_or_null("Anchor")
		if anchor:
			for child in anchor.get_children():
				anchor.remove_child(child)
				child.queue_free()

	var pile_counts = {CardColor.Type.BLUE: 0, CardColor.Type.GREEN: 0, CardColor.Type.RED: 0, CardColor.Type.PURPLE: 0}
	var card_width = 156
	var card_height = 200
	var stack_gap = 25

	var deck_array = []
	if player_data is Dictionary:
		deck_array = player_data.get("deck", [])
	else:
		deck_array = player_data.deck

	var new_deck_snapshot: Dictionary = {}

	for instance in deck_array:
		if typeof(instance) != TYPE_ARRAY: continue
		var card_id = int(instance[0])
		var quantity = int(instance[1])
		var card_data_obj = CardFactory.get_card(card_id)
		new_deck_snapshot[card_id] = quantity

		if card_data_obj != null:
			var color = card_data_obj.get_color()
			var target_pile = piles[color]
			var anchor = target_pile.get_node_or_null("Anchor")
			if not anchor: continue

			var dir_suffix = get_board_tooltip_direction()
			var prev_qty = prev_deck.get(card_id, 0)

			for i in range(quantity):
				var card_visual = CARD_SCENE.instantiate()
				anchor.add_child(card_visual)
				card_visual.setup_card(card_data_obj, dir_suffix)
				card_visual.custom_minimum_size = Vector2(card_width, card_height)
				card_visual.position = Vector2(pile_counts[color] * stack_gap, 0)

				# Slide-up + fade for cards that are new since last sync
				if i >= prev_qty:
					var final_y = card_visual.position.y
					card_visual.position.y = final_y + 40.0
					card_visual.modulate.a = 0.0
					var ct = card_visual.create_tween().set_parallel(true)
					ct.tween_property(card_visual, "modulate:a", 1.0, 0.35)
					ct.tween_property(card_visual, "position:y", final_y, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

				pile_counts[color] += 1

	prev_deck = new_deck_snapshot

	for color in piles:
		var count = pile_counts[color]
		if count > 0: piles[color].custom_minimum_size.x = card_width + ((count - 1) * stack_gap)

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

func get_board_tooltip_direction() -> String:
	var rot = wrapf(self.rotation, -PI, PI)
	if abs(rot) < 0.5: return "top"
	elif abs(rot) > 2.5: return "bottom"
	elif rot > 0.5: return "left"
	else: return "right"
		
func set_ui_visible(is_visible: bool) -> void:
	var alpha = 1.0 if is_visible else 0.0
	
	if lbl_name: lbl_name.modulate.a = alpha
	if lbl_gold: lbl_gold.modulate.a = alpha
	if active_stats_box: active_stats_box.modulate.a = alpha
	if monument_icons: monument_icons.modulate.a = alpha
	
	if btn_pass:
		btn_pass.self_modulate.a = alpha
		btn_pass.disabled = !is_visible
		for child in btn_pass.get_children():
			if child is CanvasItem and not child is TextureRect:
				child.modulate.a = alpha
				
	if btn_monu:
		btn_monu.self_modulate.a = alpha
		btn_monu.disabled = !is_visible
		for child in btn_monu.get_children():
			if child is CanvasItem:
				child.modulate.a = alpha
				
func get_card_node(card_id: int) -> Control:
	# On parcourt chaque pile du joueur
	for color in piles:
		var anchor = piles[color].get_node_or_null("Anchor")
		if anchor:
			# On cherche parmi les cartes instanciées
			for card_visual in anchor.get_children():
				# On vérifie si la carte a stocké son card_data et si l'ID correspond
				if card_visual.get("card_data") and card_visual.card_data.id == card_id:
					return card_visual
	return null
