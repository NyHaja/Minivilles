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
var lift_amount := 50.0
var anim_speed := 0.2

var base_pos := Vector2.ZERO 
var hover_offset := Vector2(0, -lift_amount)

func _ready():
	# Application des textures au lancement
	if texture_normale:
		visual.texture_normal = texture_normale
	if texture_hover:
		visual.texture_hover = texture_hover
	if bulle_texture:
		tooltip.texture = bulle_texture
	
	tooltip.hide()
	
	# Si on est dans l'éditeur, on s'arrête là
	if Engine.is_editor_hint():
		return
		
	# Connexion des signaux pour l'animation et la bulle
	visual.mouse_entered.connect(_on_card_hovered)
	visual.mouse_exited.connect(_on_card_exited)
	tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_card_hovered():
	# Animation de levée
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "position", base_pos + hover_offset, anim_speed)
	
	# Gestion de l'affichage
	z_index = 10
	tooltip.show()

func _on_card_exited():
	# Animation de redescente
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "position", base_pos, anim_speed)
	
	# Reset de l'affichage
	z_index = 0
	tooltip.hide()
