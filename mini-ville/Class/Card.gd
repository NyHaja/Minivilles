extends Node
class_name Card

var id: int
var nom: String
var cout: int
var color: String
var icon: String

func _init(_id: int, _nom: String, _cout: int, _color: String):
	self.id = _id
	self.nom = _nom
	self.cout = _cout
	self.color = _color
