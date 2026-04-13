@tool
extends Control

# --- VARIABLES EXPORTÉES ---
@export_group("Contenu de la Carte")

@export var texture_normale: Texture2D:
	set(value):
		texture_normale = value
		if is_node_ready(): $Visual.texture_normal = value

@export var texture_hover: Texture2D:
	set(value):
		texture_hover = value
		if is_node_ready(): $Visual.texture_hover = value

@export var bulle_texture: Texture2D:
	set(value):
		bulle_texture = value
		if is_node_ready(): $Visual/Tooltip.texture = value

@export_group("Réglages Tooltip")
@export var tooltip_distance: float = -5.0 # Règle cet écart

# --- RÉFÉRENCES ---
@onready var visual = $Visual
@onready var tooltip = $Visual/Tooltip

# --- RÉGLAGES ---
var anim_speed := 0.15
var hover_scale := Vector2(1.1, 1.1)
var normal_scale := Vector2(1.0, 1.0)
var current_tooltip_dir: String = "top"


func _ready():
	if texture_normale:
		visual.texture_normal = texture_normale
	if texture_hover:
		visual.texture_hover = texture_hover
	if bulle_texture:
		tooltip.texture = bulle_texture
	
	tooltip.hide()
	call_deferred("_setup_pivot")
	
	if Engine.is_editor_hint():
		return
		
	visual.mouse_entered.connect(_on_card_hovered)
	visual.mouse_exited.connect(_on_card_exited)
	tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _setup_pivot():
	if visual:
		visual.pivot_offset = Vector2(visual.size.x / 2.0, visual.size.y)

func _on_card_hovered():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "scale", hover_scale, anim_speed)
	
	z_index = 10
	
	var t_size = tooltip.size
	if tooltip.texture:
		t_size = tooltip.texture.get_size()
		
	var center_x = (visual.size.x - t_size.x) / 2.0
	
	# LE SECRET EST ICI :
	# Puisque les cartes adverses sont pivotées physiquement pour faire face au centre
	# du plateau, le "haut local" de la carte (-t_size.y) pointera TOUJOURS vers le centre de l'écran !
	var position_parfaite = Vector2(center_x, -t_size.y - tooltip_distance)
	
	match current_tooltip_dir:
		"top":      
			tooltip.rotation_degrees = 0
			tooltip.position = position_parfaite
			
		"bottom":   
			tooltip.rotation_degrees = 0
			tooltip.position = position_parfaite
			
		"left", "right":     
			tooltip.rotation_degrees = 180  
			tooltip.position = position_parfaite
	
	tooltip.show()
	
	
func setup_card(card_data, dir: String = "top"):
	var card_name = card_data.get_name()
	var card_color = card_data.get_color()
	var clean_name = get_clean_file_name(card_name, card_color)
	
	var path_basis = "res://assets/Cards/Basis/" + clean_name + "_1.png"
	if FileAccess.file_exists(path_basis):
		visual.texture_normal = load(path_basis)
		
	var tip_path = "res://assets/Tooltips/tooltip_" + clean_name + "_" + dir + ".png"
	var placeholder = "res://assets/Tooltips/tooltip_marché_fruit_et_légume_" + dir + ".png"
	
	if FileAccess.file_exists(tip_path):
		tooltip.texture = load(tip_path)
	elif FileAccess.file_exists(placeholder):
		tooltip.texture = load(placeholder)
		
	current_tooltip_dir = dir
	
	if tooltip.texture:
		tooltip.pivot_offset = tooltip.texture.get_size() / 2.0

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

func _on_card_exited():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "scale", normal_scale, anim_speed)
	
	z_index = 0
	tooltip.hide()
	
func set_badge_count(count: int) -> void:
	var target_visual = $Visual 
	
	var existing_badge = target_visual.get_node_or_null("CountBadge")
	
	var badge = existing_badge
	if badge == null:
		badge = Label.new()
		badge.name = "CountBadge"
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.z_index = 5 
		
		badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		
		badge.offset_top = 3
		badge.offset_right = -7
		
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		badge.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		
		var label_settings = LabelSettings.new()
		label_settings.font_size = 15
		label_settings.font_color = Color.WHITE
		label_settings.font = load("res://assets/Fonts/Exo_2/static/Exo2-BlackItalic.ttf")
		
		label_settings.outline_size = 6
		label_settings.outline_color = Color(0, 0, 0, 0.8) 
		
		badge.label_settings = label_settings
		
		target_visual.add_child(badge) 
	
	badge.text = "x" + str(count)
