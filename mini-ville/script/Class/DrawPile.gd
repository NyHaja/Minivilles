extends Node
class_name DrawPile

var drawPile : Array[int]

var valid_card_ids: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 27, 28, 29, 30, 31, 32]

func _init() -> void:
	for card_id in valid_card_ids:
		var card = CardFactory.get_card(card_id)
		var copies_to_add = 4
		
		if card != null and card.get_color() == CardColor.Type.PURPLE:
			copies_to_add = 2
			
		for copy in range(copies_to_add):
			drawPile.push_front(card_id)
			
	drawPile.shuffle()

func draw() -> int:
	return drawPile.pop_back()

func is_empty() -> bool:
	return drawPile.size() == 0
