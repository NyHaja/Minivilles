extends Control
class_name PlayerBoard

signal pass_turn_requested
signal open_monuments_requested

var player = null

@onready var lbl_name: Label = %PlayerLabel
@onready var lbl_gold: Label = %PlayerMoney
@onready var btn_pass: TextureButton = get_node_or_null("%PasserLeTourButton")
@onready var btn_monu: TextureButton = get_node_or_null("%MonumentButton")

@onready var active_stats_box = get_node_or_null("MainColumn/TopBar/ActivePlayerStats")

@onready var piles = {
	CardColor.Type.BLUE: %BluePileBottom,
	CardColor.Type.GREEN: %GreenPileBottom,
	CardColor.Type.RED: %RedPileBottom,
	CardColor.Type.PURPLE: %PurplePileBottom
}

const CARD_SCENE = preload("res://scene/table/card_Y_axis.tscn")

func _ready() -> void:
	if btn_pass: btn_pass.pressed.connect(func(): pass_turn_requested.emit())
	if btn_monu: btn_monu.pressed.connect(func(): open_monuments_requested.emit())
	
	# Correction : Forcer le centrage vertical du contenu du plateau 
	var main_col = get_node_or_null("MainColumn")
	if main_col:
		main_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		main_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
		main_col.set("alignment", BoxContainer.ALIGNMENT_CENTER)

func _process(_delta: float) -> void:
	if active_stats_box and is_inside_tree():
		active_stats_box.pivot_offset = active_stats_box.size / 2.0
		var angle = fmod(self.rotation + PI, 2*PI) - PI
		if abs(angle) > PI * 0.8:
			active_stats_box.rotation = -self.rotation
		else:
			active_stats_box.rotation = 0

func setup(player_data, is_active_player: bool) -> void:
	player = player_data
	if btn_pass: btn_pass.visible = is_active_player
	if btn_monu: btn_monu.visible = is_active_player 
	update_info()
	update_deck()

func update_info() -> void:
	if not player: return
	lbl_name.text = player.username
	lbl_gold.text = str(player.balance)

func set_actions_enabled(can_act: bool) -> void:
	if btn_pass: btn_pass.disabled = !can_act
	if btn_monu: btn_monu.disabled = !can_act

func update_deck() -> void:
	if not player: return
	for pile in piles.values():
		var anchor = pile.get_node_or_null("Anchor")
		if anchor:
			for child in anchor.get_children(): child.queue_free()
	
	var pile_counts = {CardColor.Type.BLUE: 0, CardColor.Type.GREEN: 0, CardColor.Type.RED: 0, CardColor.Type.PURPLE: 0}
	var card_width = 156 
	var card_height = 200
	var stack_gap = 25 
	
	for instance in player.deck:
		if typeof(instance) != TYPE_ARRAY: continue
		var card_id = instance[0]
		var quantity = instance[1]
		var card_data = CardFactory.get_card(card_id)
		
		if card_data != null:
			var color = card_data.get_color()
			var target_pile = piles[color]
			var anchor = target_pile.get_node_or_null("Anchor")
			if not anchor: continue
			
			for i in range(quantity):
				var card_visual
				var clean_name = get_clean_file_name(card_data.get_name(), color)
				var path_basis = "res://assets/Cards/Basis/" + clean_name + "_1.png"
				
				if FileAccess.file_exists(path_basis):
					card_visual = CARD_SCENE.instantiate()
					var image_node = card_visual.get_node_or_null("Visual")
					if image_node is TextureButton:
						image_node.texture_normal = load(path_basis)
				else:
					card_visual = Button.new()
					card_visual.text = card_data.get_name()
					
				card_visual.custom_minimum_size = Vector2(card_width, card_height)
				card_visual.position = Vector2(pile_counts[color] * stack_gap, 0)
				anchor.add_child(card_visual)
				pile_counts[color] += 1

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
