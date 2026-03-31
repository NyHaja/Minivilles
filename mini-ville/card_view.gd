extends Control
class_name CardView

@onready var front_texture: TextureRect = $Front
@onready var name_label: Label = $Front/NameLabel
@onready var cost_label: Label = $Front/CostLabel
@onready var id_label: Label = $Front/IdLabel

var is_hovered: bool = false
var is_selected: bool = false

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup(card_data) -> void:
	name_label.text = str(card_data.name)
	cost_label.text = "Cost: " + str(card_data.cost)
	id_label.text = "ID: " + str(card_data.id)

	var path = CardFactory.get_card_texture_path(card_data.id)
	if path != "":
		front_texture.texture = load(path)

func set_quantity(quantity: int) -> void:
	id_label.text += " x" + str(quantity)

func set_selected(value: bool) -> void:
	is_selected = value

	if value:
		modulate = Color(1.0, 0.8, 0.8, 1.0)
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0)

func play_spawn_animation(delay: float = 0.0) -> void:
	modulate.a = 0.0
	scale = Vector2(0.85, 0.85)

	var tween = create_tween()

	if delay > 0.0:
		tween.tween_interval(delay)

	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.20)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.20)

func _on_mouse_entered() -> void:
	if is_hovered:
		return
	is_hovered = true

	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.12)

func _on_mouse_exited() -> void:
	is_hovered = false

	var target_scale = Vector2(1.0, 1.0)
	if is_selected:
		target_scale = Vector2(1.05, 1.05)

	var tween = create_tween()
	tween.tween_property(self, "scale", target_scale, 0.12)
