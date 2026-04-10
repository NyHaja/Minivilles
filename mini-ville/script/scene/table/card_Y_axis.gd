@tool
extends Control

# --- VARIABLES EXPORTÉES ---
@export_group("Contenu de la Carte")

# Image normale
@export var texture_normale: Texture2D:
	set(value):
		texture_normale = value
		if is_node_ready(): $Visual.texture_normal = value

# Image en surbrillance (Hover)
@export var texture_hover: Texture2D:
	set(value):
		texture_hover = value
		if is_node_ready(): $Visual.texture_hover = value

# Image de la bulle Figma
@export var bulle_texture: Texture2D:
	set(value):
		bulle_texture = value
		if is_node_ready(): $Visual/Tooltip.texture = value

# --- RÉFÉRENCES ---
@onready var visual = $Visual
@onready var tooltip = $Visual/Tooltip

# --- RÉGLAGES ---
var anim_speed := 0.15
var hover_scale := Vector2(1.1, 1.1)
var normal_scale := Vector2(1.0, 1.0)
var current_tooltip_dir: String = "top"
var base_tooltip_pos: Vector2


func _ready():
	# Application des textures au lancement
	if texture_normale:
		visual.texture_normal = texture_normale
	if texture_hover:
		visual.texture_hover = texture_hover
	if bulle_texture:
		tooltip.texture = bulle_texture
	
	tooltip.hide()
	
	call_deferred("_setup_pivot")
	
	base_tooltip_pos = tooltip.position
	
	# Si on est dans l'éditeur, on s'arrête là
	if Engine.is_editor_hint():
		return
		
	# Connexion des signaux pour l'animation et la bulle
	visual.mouse_entered.connect(_on_card_hovered)
	visual.mouse_exited.connect(_on_card_exited)
	tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _setup_pivot():
	if visual:
		visual.pivot_offset = Vector2(visual.size.x / 2.0, visual.size.y)

func _on_card_hovered():
	# Animation de levée
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "scale", hover_scale, anim_speed)
	
	# Gestion de l'affichage
	z_index = 10
	
	match current_tooltip_dir:
		"top":      
			tooltip.rotation_degrees = 0
			tooltip.position = base_tooltip_pos
		"left":     
			tooltip.rotation_degrees = 180  
			tooltip.position = base_tooltip_pos + Vector2(40, -80) 
		"right":    
			tooltip.rotation_degrees = 180
			tooltip.position = base_tooltip_pos + Vector2(40, -80)
		"bottom":   
			tooltip.rotation_degrees = 0
			tooltip.position = base_tooltip_pos
	
	tooltip.show()
	
	
func setup_card(card_data, tooltip_dir: String = "top"):
	var card_name = card_data.get_name()
	var card_color = card_data.get_color()
	var clean_name = get_clean_file_name(card_name, card_color)
	
	var path_basis = "res://assets/Cards/Basis/" + clean_name + "_1.png"
	if FileAccess.file_exists(path_basis):
		visual.texture_normal = load(path_basis)
		
	var tip_path = "res://assets/Tooltips/tooltip_" + clean_name + "_" + tooltip_dir + ".png"
	var placeholder = "res://assets/Tooltips/tooltip_marché_fruit_et_légume_" + tooltip_dir + ".png"
	
	if FileAccess.file_exists(tip_path):
		tooltip.texture = load(tip_path)
	elif FileAccess.file_exists(placeholder):
		tooltip.texture = load(placeholder)
		
	current_tooltip_dir = tooltip_dir
	
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
	# Animation de redescente
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "scale", normal_scale, anim_speed)
	
	# Reset de l'affichage
	z_index = 0
	tooltip.hide()
