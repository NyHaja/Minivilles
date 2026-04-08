extends TextureRect

const SPEED = 120.0
const FLOAT_AMPLITUDE = 8.0
const FLOAT_SPEED = 2.0

var base_y : float
var time : float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	base_y = position.y


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pivot_offset = size / 2
	time += delta
	rotation_degrees += SPEED * delta
	position.y = base_y + sin(time * FLOAT_SPEED) * FLOAT_AMPLITUDE
