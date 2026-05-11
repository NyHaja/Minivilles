extends Node
class_name DrawPile

var drawPile : Array[int]

# J'ai retiré le 21 (Monument Gare) et ajouté le 27 (Club Privé) pour refléter le nouveau CardFactory
var valid_card_ids: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 27, 28, 29, 30, 31, 32]

func _init() -> void:
	for card_id in valid_card_ids:
		var card = CardFactory.get_card(card_id)
		var copies_to_add = 4
		
		if card != null and card.get_color() == CardColor.Type.PURPLE:
			copies_to_add = 2
			
		# ⚠️ ATTENTION ICI : 
		# Si vous vouliez cibler l'"Entreprise de déménagement" (ancien 31), c'est maintenant l'ID 30.
		# Si vous vouliez cibler le "Centre d'affaires" (ancien 32), alors 31 est le bon numéro !
		if card != null and card_id == 31:
			copies_to_add = 200
			
		for copy in range(copies_to_add):
			drawPile.push_front(card_id)
			
	drawPile.shuffle()

func draw() -> int:
	return drawPile.pop_back()

func is_empty() -> bool:
	return drawPile.size() == 0
