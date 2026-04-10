@tool
extends Control

@export var line_color: Color = Color(1, 1, 1, 0.4) :
	set(value):
		line_color = value
		queue_redraw() # Met à jour le dessin si tu changes la couleur dans l'inspecteur

@export var line_width: float = 4.0 :
	set(value):
		line_width = value
		queue_redraw() # Met à jour le dessin si tu changes l'épaisseur

@export var dash_length: float = 12.0 :
	set(value):
		dash_length = value
		queue_redraw()

@export var padding: float = 15.0 :
	set(value):
		padding = value
		queue_redraw()

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	var top_left = Vector2(-padding, -padding)
	var top_right = Vector2(size.x + padding, -padding)
	var bottom_left = Vector2(-padding, size.y + padding)
	var bottom_right = Vector2(size.x + padding, size.y + padding)
	
	draw_dashed_line(top_left, top_right, line_color, line_width, dash_length)
	draw_dashed_line(bottom_left, bottom_right, line_color, line_width, dash_length)
	draw_dashed_line(top_left, bottom_left, line_color, line_width, dash_length)
	draw_dashed_line(top_right, bottom_right, line_color, line_width, dash_length)
