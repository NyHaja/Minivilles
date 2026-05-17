extends PanelContainer
class_name ShopBoard

signal shop_card_clicked(card_id: int)

@onready var grid_container: GridContainer = %ShopGridContainer

const CARD_SCENE = preload("res://scene/table/card_animation.tscn")

var shop_card_w = 117
var shop_card_h = 150
var last_clicked_slot: Control = null
var last_clicked_index: int = -1
var current_glow_tween: Tween

func get_lang_folder() -> String:
	# Récupère la langue actuelle (ex: "fr", "en", "en_US")
	if TranslationServer.get_locale().begins_with("en"):
		return "English"
	return "French"

# Maps card_id (int) → card_visual node. Populated by update_network_shop.
var card_slot_map: Dictionary = {}

# Smart in-place update. Returns {new_card_id: target_global_position} for
# each card that needs a deck→slot animation.
func update_network_shop(shop_data_dict: Dictionary) -> Dictionary:
	var position_map: Dictionary = {}

	if card_slot_map.is_empty():
		_full_rebuild(shop_data_dict)
		return position_map

	var removed_ids: Array = []
	for card_id in card_slot_map:
		if not shop_data_dict.has(str(card_id)):
			removed_ids.append(card_id)

	var new_ids: Array = []
	for card_id_str in shop_data_dict:
		if not card_slot_map.has(int(card_id_str)):
			new_ids.append(int(card_id_str))

	for card_id_str in shop_data_dict:
		var card_id = int(card_id_str)
		if card_slot_map.has(card_id):
			var slot = card_slot_map[card_id]
			if slot.has_method("set_badge_count"):
				slot.set_badge_count(shop_data_dict[card_id_str])

	removed_ids.sort_custom(func(a, b):
		var sa = card_slot_map.get(a, null)
		var sb = card_slot_map.get(b, null)
		var ia = sa.get_index() if is_instance_valid(sa) else 999
		var ib = sb.get_index() if is_instance_valid(sb) else 999
		return ia < ib
	)

	var freed_slots: Array = []
	for card_id in removed_ids:
		var slot = card_slot_map.get(card_id, null)
		if is_instance_valid(slot):
			freed_slots.append({
				"index": slot.get_index(),
				"position": slot.global_position
			})
			slot.free()
		card_slot_map.erase(card_id)

	for i in range(new_ids.size()):
		var card_id = new_ids[i]
		var card_data = CardFactory.get_card(card_id)
		if card_data == null or card_data is Monument: continue

		var qty = shop_data_dict.get(str(card_id), 1)
		var card_visual = _create_card_visual(card_id, card_data, qty)
		card_visual.modulate.a = 0.0  # hidden until fly-in animation reveals it

		grid_container.add_child(card_visual)

		if i < freed_slots.size():
			grid_container.move_child(card_visual, freed_slots[i].index)
			position_map[card_id] = freed_slots[i].position

		card_slot_map[card_id] = card_visual

	return position_map

func _full_rebuild(shop_data_dict: Dictionary) -> void:
	var old_children = grid_container.get_children()
	for child in old_children:
		child.free()
	card_slot_map.clear()

	var card_ids = shop_data_dict.keys()
	for i in range(min(card_ids.size(), 9)):
		var card_id = int(card_ids[i])
		var card_data = CardFactory.get_card(card_id)
		if card_data == null or card_data is Monument: continue
		var card_visual = _create_card_visual(card_id, card_data, shop_data_dict[card_ids[i]])
		grid_container.add_child(card_visual)
		card_slot_map[card_id] = card_visual

func _create_card_visual(card_id: int, card_data, quantity) -> Control:
	var clean_name = get_clean_file_name(card_data.get_name(), card_data.get_color())
	
	var tex_normal = load("res://assets/Cards/" + get_lang_folder() + "/Establishments/" + clean_name + "_1.png")
	
	var card_visual: Control
	if tex_normal:
		card_visual = CARD_SCENE.instantiate()
		var image_node = card_visual.get_node_or_null("Visual")
		if image_node is TextureButton:
			image_node.texture_normal = tex_normal
			image_node.pressed.connect(func(): _on_card_clicked(card_visual, card_id))
		var glow = _create_glow_panel("SelectionGlow", Color(1.0, 0.84, 0.0, 0.8))
		if image_node: image_node.add_child(glow)
		card_visual.custom_minimum_size = Vector2(shop_card_w, shop_card_h)
		if card_visual.has_method("set_badge_count"): card_visual.set_badge_count(quantity)
	else:
		card_visual = _create_fallback_button(card_data, quantity, card_id)
	return card_visual

func update_shop(shop_data) -> void:
	if not shop_data or not shop_data.get("shop"): return
	for child in grid_container.get_children(): child.queue_free()
	
	var shop_array = shop_data.get("shop")
	var max_cards = min(shop_array.size(), 9)
		
	for i in range(max_cards):
		var slot = shop_array[i]
		var card_id = int(slot[0]) if typeof(slot) == TYPE_ARRAY else int(slot.get("id"))
		var quantity = int(slot[1]) if typeof(slot) == TYPE_ARRAY else int(slot.get("quantity"))
		var card_data = CardFactory.get_card(card_id)
		
		if card_data:
			var card_visual
			var clean_name = get_clean_file_name(card_data.get_name(), card_data.get_color())
			var tex_normal = load("res://assets/Cards/" + get_lang_folder() + "/" + "Establishments/" + clean_name + "_1.png")
			
			if tex_normal:
				card_visual = CARD_SCENE.instantiate()
				var image_node = card_visual.get_node_or_null("Visual")
				if image_node is TextureButton:
					image_node.texture_normal = tex_normal
					image_node.pressed.connect(func(): _on_card_clicked(card_visual, card_id))
				
				var glow = _create_glow_panel("SelectionGlow", Color(1.0, 0.84, 0.0, 0.8))
				if image_node: image_node.add_child(glow)
				
				card_visual.custom_minimum_size = Vector2(shop_card_w, shop_card_h)
				if card_visual.has_method("set_badge_count"): card_visual.set_badge_count(quantity)
			else:
				card_visual = _create_fallback_button(card_data, quantity, card_id)
				
			grid_container.add_child(card_visual)

func _create_glow_panel(p_name: String, p_color: Color) -> Panel:
	var p = Panel.new()
	p.name = p_name
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.show_behind_parent = true
	p.modulate.a = 0.0
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0,0,0,0)
	style.shadow_color = p_color
	style.shadow_size = 20
	style.set_corner_radius_all(8)
	p.add_theme_stylebox_override("panel", style)
	return p

func _create_fallback_button(card_data, quantity, card_id) -> Button:
	var btn = Button.new()
	btn.text = card_data.get_name() + "\n(x" + str(quantity) + ")"
	btn.pressed.connect(func(): _on_card_clicked(btn, card_id))
	btn.custom_minimum_size = Vector2(shop_card_w, shop_card_h)
	btn.pivot_offset = btn.custom_minimum_size / 2.0
	
	# Halo de sélection (invisible par défaut) [cite: 86]
	var s_glow = _create_glow_panel("SelectionGlow", Color(1.0, 0.84, 0.0, 0.8))
	btn.add_child(s_glow)
	
	# Animation mécanique au survol (Élévation + Scale)
	btn.mouse_entered.connect(func():
		if !btn.disabled:
			var tween = get_tree().create_tween().set_parallel(true)
			tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1)
			tween.tween_property(btn, "position:y", btn.position.y - 10, 0.1)
	)
	btn.mouse_exited.connect(func():
		var tween = get_tree().create_tween().set_parallel(true)
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
		tween.tween_property(btn, "position:y", btn.position.y + 10, 0.1)
	)
	return btn

func _on_card_clicked(slot_node: Control, card_id: int):
	last_clicked_slot = slot_node
	last_clicked_index = slot_node.get_index()
	
	for child in grid_container.get_children():
		var glow = child.get_node_or_null("Visual/SelectionGlow")
		if not glow: glow = child.get_node_or_null("SelectionGlow")
		if glow: glow.modulate.a = 0.0
			
	if current_glow_tween: current_glow_tween.kill()
	var active_glow = slot_node.get_node_or_null("Visual/SelectionGlow")
	if not active_glow: active_glow = slot_node.get_node_or_null("SelectionGlow")
	
	if active_glow:
		active_glow.modulate.a = 1.0
		current_glow_tween = get_tree().create_tween().set_loops() 
		current_glow_tween.tween_property(active_glow, "modulate:a", 0.4, 0.8).set_trans(Tween.TRANS_SINE)
		current_glow_tween.tween_property(active_glow, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	
	shop_card_clicked.emit(card_id)

func clear_selection():
	last_clicked_slot = null
	last_clicked_index = -1
	if current_glow_tween: current_glow_tween.kill()
	for child in grid_container.get_children():
		var glow = child.get_node_or_null("Visual/SelectionGlow")
		if not glow: glow = child.get_node_or_null("SelectionGlow")
		if glow: get_tree().create_tween().tween_property(glow, "modulate:a", 0.0, 0.2)

func get_clean_file_name(card_name: String, color: int) -> String:
	var prefix = ""
	match color:
		CardColor.Type.BLUE: prefix = "bleu_"
		CardColor.Type.GREEN: prefix = "vert_"
		CardColor.Type.RED: prefix = "rouge_"
		CardColor.Type.PURPLE: prefix = "violet_"
	return prefix + card_name.to_lower().replace(" ", "_").replace("'", "_").replace("é", "e").replace("è", "e").replace("à", "a")

# --- FONCTION RESTAURÉE ---
func set_actions_enabled(can_act: bool) -> void:
	for card_visual in grid_container.get_children():
		var button = card_visual.get_node_or_null("Visual")
		if button == null:
			button = card_visual
			
		if button is BaseButton: 
			button.disabled = !can_act
