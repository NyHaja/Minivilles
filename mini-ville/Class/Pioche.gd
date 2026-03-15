extends Node
class_name  Pioche

var pioche : Array[int]

func _init() -> void:
	pass

func draw() -> int:
	return pioche.front()

func est_vide() -> bool:
	return pioche.size() == 0
