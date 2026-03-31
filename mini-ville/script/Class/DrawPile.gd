extends Node
class_name  DrawPile

var drawPile : Array[int]

var valid_card_ids: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 28, 29, 30, 31, 32, 33]

func _init() -> void:
	for card_id in valid_card_ids:
		for copy in range(4):
			drawPile.push_front(card_id)
	drawPile.shuffle()

func draw() -> int:
	return drawPile.pop_back()

func is_empty() -> bool:
	return drawPile.size() == 0
