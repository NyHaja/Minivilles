extends Node
class_name CardFactory

static func get_card_by_id(id: int) -> Card:
	var cardDummy = Card.new(100, "DUMMY", 5, "Blue")
	return cardDummy
