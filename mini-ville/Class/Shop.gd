extends Node
class_name  Shop

var shop : Array[Slot]
var drawPile : DrawPile #125 carte de "reserve" (sans compter les monument et les carte de départ)

const SIZESHOP = 9

# TO DO
func _init() -> void:
	drawPile = DrawPile.new()
	fill()
	print_shop()

func bought(joueur:Player,IDcard:int):
	if available(IDcard):
		# ajoute carte dans joueur
		fill()

func slotID(IDcard:int)->Slot:
	for i in shop.size():
		if shop[i].id == IDcard:
			return shop[i]
	
	return null
		
func available(IDcard:int)->bool:
	return not(slotID(IDcard) == null)
	
func freeEmptySlot():
	for i in shop.size():
		if shop[i].quantity == 0:
			shop.remove_at(i)

func fill()->void:
	freeEmptySlot()
	while shop.size() < 9 and not(drawPile.is_empty()):
		var new = drawPile.draw()
		var existantSlot = slotID(new)
		if existantSlot == null:
			var newslot = Slot.new(new,1)
			shop.append(newslot)
		else:
			existantSlot.quantity += 1
		
	
func print_shop()->void:
	for slot:Slot in self.shop:
		print(slot.id)
		
