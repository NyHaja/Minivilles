extends Node
class_name  Establishment

enum COLOR{
	BLUE,
	GREEN,
	RED,
	PURPLE
}

var id: int
var cost: int
var color: int
var activation: Array
var icon: String
var effect: Callable
