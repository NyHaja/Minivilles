extends PanelContainer
class_name ShopBoard

signal shop_card_clicked(card_id: int)

@onready var grid_container: GridContainer = %ShopGridContainer

const CARD_SCENE = preload("res://scene/table/card_animation.tscn")

var shop_card_w = 117
var shop_card_h = 150

func update_network_shop(shop_data_dict: Dictionary) -> void:
	for child in grid_container.get_children():
		child.queue_free()
		
	var card_ids = shop_data_dict.keys()
	var max_cards = min(card_ids.size(), 9)
		
	for i in range(max_cards):
		var card_id_str = card_ids[i]
		var card_id = int(card_id_str)
		var quantity = shop_data_dict[card_id_str]
		
		var card_visual
		var card_data = CardFactory.get_card(card_id)
		
		if card_data != null:
			var card_name = card_data.get_name()
			var card_color = card_data.get_color()
			var clean_name = get_clean_file_name(card_name, card_color)
			
			var path_basis = "res://assets/Cards/Basis/" + clean_name + "_1.png"
			var path_hover = "res://assets/Cards/Hover/" + clean_name + "_2.png"
			
			var tex_normal = load(path_basis)
			if tex_normal:
				card_visual = CARD_SCENE.instantiate()
				var image_node = card_visual.get_node_or_null("Visual")
				if image_node is TextureButton:
					image_node.texture_normal = tex_normal
					var tex_hover = load(path_hover)
					if tex_hover:
						image_node.texture_hover = tex_hover
					
					image_node.ignore_texture_size = true
					image_node.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
					
					image_node.pressed.connect(func(): shop_card_clicked.emit(card_id))

				card_visual.custom_minimum_size = Vector2(shop_card_w, shop_card_h)
				card_visual.size = Vector2(shop_card_w, shop_card_h)
				
				if card_visual.has_method("set_badge_count"):
					card_visual.set_badge_count(quantity)
			
			else:
				card_visual = Button.new()
				
				var fallback_text = str(card_data.get_activation_num()) + "\n" + card_name
				if quantity > 1:
					fallback_text += "\n(x" + str(quantity) + ")"
					
				card_visual.text = fallback_text
				card_visual.pressed.connect(func(): shop_card_clicked.emit(card_id))
				
				card_visual.custom_minimum_size = Vector2(shop_card_w, shop_card_h)
				card_visual.size = Vector2(shop_card_w, shop_card_h)
				card_visual.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				card_visual.clip_text = true 
				
				var style = StyleBoxFlat.new()
				match card_color:
					CardColor.Type.BLUE: style.bg_color = Color(0.2, 0.4, 0.8)
					CardColor.Type.GREEN: style.bg_color = Color(0.2, 0.6, 0.2)
					CardColor.Type.RED: style.bg_color = Color(0.8, 0.2, 0.2)
					CardColor.Type.PURPLE: style.bg_color = Color(0.6, 0.2, 0.8)
				
				style.set_border_width_all(2)
				style.border_color = Color(0, 0, 0, 0.5)
				card_visual.add_theme_stylebox_override("normal", style)
				
				var hover_style = style.duplicate()
				hover_style.bg_color = style.bg_color.lightened(0.2)
				card_visual.add_theme_stylebox_override("hover", hover_style)

			grid_container.add_child(card_visual)
			
			
# Setup pour partie locale (DEBUG SÉCURISÉ)
func update_shop(shop_data) -> void:
	print("\n========== SHOP DEBUG START ==========")
	
	if shop_data == null:
		print("FAIL: shop_data is null!")
		return
		
	print("1. shop_data received successfully.")

	# Extraction ultra-sécurisée de l'array
	var shop_array = shop_data.get("shop")
	
	if shop_array == null:
		print("FAIL: shop_data.get('shop') returned null! The variable 'shop' does not exist inside shop_data.")
		return
		
	if typeof(shop_array) != TYPE_ARRAY:
		print("FAIL: 'shop' was found, but it is NOT an Array. It is type: ", typeof(shop_array))
		return
		
	print("2. Shop Array Contains ", shop_array.size(), " items.")
	
	for child in grid_container.get_children():
		child.queue_free()
		
	var max_cards = min(shop_array.size(), 9)
	print("3. Attempting to draw ", max_cards, " cards...")
		
	for i in range(max_cards):
		var slot = shop_array[i]
		print("--- Slot ", i, " Data: ", slot)
		
		# Extraction sécurisée de l'ID et de la quantité
		var card_id = -1
		var quantity = 1
		
		if typeof(slot) == TYPE_ARRAY:
			card_id = int(slot[0])
			quantity = int(slot[1])
		else:
			# Si c'est un Objet local (Slot)
			card_id = int(slot.get("id")) if slot.get("id") != null else -1
			quantity = int(slot.get("quantity")) if slot.get("quantity") != null else 1
			
		print("    Extracted -> ID: ", card_id, " | QTY: ", quantity)
		
		var card_data = CardFactory.get_card(card_id)
		
		if card_data != null:
			print("    CardFactory Found: ", card_data.get_name())
			var card_name = card_data.get_name()
			var card_color = card_data.get_color()
			var clean_name = get_clean_file_name(card_name, card_color)
			
			var path_basis = "res://assets/Cards/Basis/" + clean_name + "_1.png"
			var path_hover = "res://assets/Cards/Hover/" + clean_name + "_2.png"
			
			print("    Looking for image at: ", path_basis)
			var tex_normal = load(path_basis)
			
			var card_visual
			
			if tex_normal:
				print("    -> SUCCESS: Image loaded!")
				card_visual = CARD_SCENE.instantiate()
				var image_node = card_visual.get_node_or_null("Visual")
				if image_node is TextureButton:
					image_node.texture_normal = tex_normal
					var tex_hover = load(path_hover)
					if tex_hover:
						image_node.texture_hover = tex_hover
					
					image_node.ignore_texture_size = true
					image_node.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
					
					image_node.pressed.connect(func(): shop_card_clicked.emit(card_id))

				card_visual.custom_minimum_size = Vector2(shop_card_w, shop_card_h)
				card_visual.size = Vector2(shop_card_w, shop_card_h)
				
				if card_visual.has_method("set_badge_count"):
					card_visual.set_badge_count(quantity)
			
			else:
				print("    -> FAIL: Image not found! Drawing colored fallback button.")
				card_visual = Button.new()
				
				var fallback_text = str(card_data.get_activation_num()) + "\n" + card_name
				if quantity > 1:
					fallback_text += "\n(x" + str(quantity) + ")"
					
				card_visual.text = fallback_text
				card_visual.pressed.connect(func(): shop_card_clicked.emit(card_id))
				
				card_visual.custom_minimum_size = Vector2(shop_card_w, shop_card_h)
				card_visual.size = Vector2(shop_card_w, shop_card_h)
				card_visual.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				card_visual.clip_text = true 
				
				var style = StyleBoxFlat.new()
				match card_color:
					CardColor.Type.BLUE: style.bg_color = Color(0.2, 0.4, 0.8)
					CardColor.Type.GREEN: style.bg_color = Color(0.2, 0.6, 0.2)
					CardColor.Type.RED: style.bg_color = Color(0.8, 0.2, 0.2)
					CardColor.Type.PURPLE: style.bg_color = Color(0.6, 0.2, 0.8)
				
				style.set_border_width_all(2)
				style.border_color = Color(0, 0, 0, 0.5)
				card_visual.add_theme_stylebox_override("normal", style)
				
				var hover_style = style.duplicate()
				hover_style.bg_color = style.bg_color.lightened(0.2)
				card_visual.add_theme_stylebox_override("hover", hover_style)

			grid_container.add_child(card_visual)
		else:
			print("    FAIL: CardFactory returned null for ID ", card_id)
			
	print("========== SHOP DEBUG END ==========\n")
			

func get_clean_file_name(card_name: String, color: int) -> String:
	var prefix = ""
	match color:
		CardColor.Type.BLUE: prefix = "bleu_"
		CardColor.Type.GREEN: prefix = "vert_"
		CardColor.Type.RED: prefix = "rouge_"
		CardColor.Type.PURPLE: prefix = "violet_"
	var clean_name = card_name.to_lower().replace(" ", "_").replace("'", "_")
	clean_name = clean_name.replace("é", "e").replace("è", "e").replace("à", "a").replace("ô","o").replace("î","i")
	return prefix + clean_name
	
func set_actions_enabled(can_act: bool) -> void:
	for card_visual in grid_container.get_children():
		var button = card_visual.get_node_or_null("Visual")
		if button == null:
			button = card_visual
			
		if button is BaseButton: 
			button.disabled = !can_act
