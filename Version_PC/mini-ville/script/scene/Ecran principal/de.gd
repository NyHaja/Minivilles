extends TextureRect


const SPEED = 120.0
const FLOAT_AMPLITUDE = 8.0
const FLOAT_SPEED = 2.0

var base_y: float
var time: float = 0.0


func _ready():
	base_y = position.y


func _process(delta):
	pivot_offset = size / 2
	time += delta
	rotation_degrees += SPEED * delta
	position.y = base_y + sin(time * FLOAT_SPEED) * FLOAT_AMPLITUDE
