extends PanelContainer
class_name ShopBoard

signal shop_card_clicked(card_id: int)

@onready var grid_container: GridContainer = %ShopGridContainer

const CARD_SCENE = preload("res://scene/table/card_animation.tscn")

var shop_card_w = 117
var shop_card_h = 150

func update_shop(shop_data) -> void:
	for child in grid_container.get_children():
		child.queue_free()
		
	var max_cards = min(shop_data.shop.size(), 9)
		
	for i in range(max_cards):
		var slot = shop_data.shop[i]
		var card_visual
		var card_data = CardFactory.get_card(slot.id)
		
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
					
					image_node.pressed.connect(func(): shop_card_clicked.emit(slot.id))

				card_visual.custom_minimum_size = Vector2(shop_card_w, shop_card_h)
				card_visual.size = Vector2(shop_card_w, shop_card_h)
				
				if card_visual.has_method("set_badge_count"):
					card_visual.set_badge_count(slot.quantity)
			
			else:
				card_visual = Button.new()
				
				var fallback_text = str(card_data.get_activation_num()) + "\n" + card_name
				if slot.quantity > 1:
					fallback_text += "\n(x" + str(slot.quantity) + ")"
					
				card_visual.text = fallback_text
				card_visual.pressed.connect(func(): shop_card_clicked.emit(slot.id))
				
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
