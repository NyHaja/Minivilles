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

const CARD_SCENE = preload("res://scene/table/card_animation.tscn")

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
		
		# On normalise la rotation pour qu'elle reste toujours strictement entre -PI et PI
		var normalized_rot = wrapf(self.rotation, -PI, PI)
		
		# Si le plateau est en haut (rotation proche de 180° ou -180°)
		if abs(normalized_rot) > PI * 0.8:
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
			
			var dir_suffix = get_board_tooltip_direction()
			
			for i in range(quantity):
				var card_visual = CARD_SCENE.instantiate()
				
				anchor.add_child(card_visual)
				
				card_visual.setup_card(card_data, dir_suffix)
				
				card_visual.custom_minimum_size = Vector2(card_width, card_height)
				card_visual.position = Vector2(pile_counts[color] * stack_gap, 0)
				
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





func get_board_tooltip_direction() -> String:
	var rot = wrapf(self.rotation, -PI, PI)
	
	if abs(rot) < 0.5:
		return "top"
	elif abs(rot) > 2.5:
		return "bottom"
	elif rot > 0.5:
		return "left"
	else:
		return "right"
		
# Dans PlayerBoard.gd
func set_ui_visible(is_visible: bool) -> void:
	var alpha = 1.0 if is_visible else 0.0
	
	if lbl_name: lbl_name.modulate.a = alpha
	if lbl_gold: lbl_gold.modulate.a = alpha
	if active_stats_box: active_stats_box.modulate.a = alpha
	
	# UTILISATION DE SELF_MODULATE
	# Cela cache le bouton, mais n'affectera pas l'animation des dés ajoutée en enfant
	if btn_pass:
		btn_pass.self_modulate.a = alpha
		btn_pass.disabled = !is_visible
		# Au cas où tu as un "Label" de texte à l'intérieur du bouton :
		for child in btn_pass.get_children():
			if child is CanvasItem and not child is TextureRect:
				child.modulate.a = alpha
		
	if btn_monu:
		btn_monu.self_modulate.a = alpha
		btn_monu.disabled = !is_visible
		for child in btn_monu.get_children():
			if child is CanvasItem:
				child.modulate.a = alpha
