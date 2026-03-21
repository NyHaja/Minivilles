extends Node
class_name  Shop

var shop : Array[Slot]
var drawPile : DrawPile #125 carte de "reserve" (sans compter les monument et les carte de départ)

const SIZESHOP = 9

# TO DO
func _init() -> void:
	drawPile = DrawPile.new()
	fill()

func removeCardFromStock(card_id: int) -> void:
	var target_slot = slotID(card_id)
	
	if target_slot != null:
		target_slot.quantity -= 1
		
		fill()

func slotID(IDcard:int)->Slot:
	for i in shop.size():
		if shop[i].id == IDcard:
			return shop[i]
	
	return null
		
func available(IDcard:int)->bool:
	return not(slotID(IDcard) == null)

func fill()->void:
	for i in range(SIZESHOP):
		if i >= shop.size():
			shop.append(Slot.new(-1, 0))
			
		while shop[i].quantity <= 0 and not drawPile.is_empty():
			var new_card_id = drawPile.draw()
			var existantSlot = slotID(new_card_id)
			
			if existantSlot != null and existantSlot != shop[i]:
				existantSlot.quantity += 1
			else:
				shop[i].id = new_card_id
				shop[i].quantity = 1
	for i in range(shop.size() -1, -1, -1):
		if shop[i].quantity <= 0:
			shop.remove_at(i)
	
func print_shop()->void:
	for slot:Slot in self.shop:
		print(slot.id)
		
