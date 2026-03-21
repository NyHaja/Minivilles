extends Node
class_name  DrawPile

var drawPile : Array[int]


func _init() -> void: # A REVOIR AVEC CLEMENT LES ID DES CARTES 
	for card_id in range(0,15): # test
		for copy in range(6):
			drawPile.push_front(card_id)
	drawPile.shuffle()

func draw() -> int:
	return drawPile.pop_back()

func is_empty() -> bool:
	return drawPile.size() == 0
