extends Node
class_name  DrawPile

var drawPile : Array[int]


func _init() -> void: # A REVOIR AVEC CLEMENT LES ID DES CARTES 
	for i in range(0,15): # test
		drawPile.push_front(i)

func draw() -> int:
	return drawPile.pop_back()

func is_empty() -> bool:
	return drawPile.size() == 0
