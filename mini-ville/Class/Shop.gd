extends Node
class_name  Shop

var shop : Array[Slot]
var pioche : Pioche

const SIZESHOP = 9

func _init() -> void:
	pass

func achette(joueur:Player,IDcard:int):
	if dispo(IDcard):
		# ajoute carte dans joueur
		fill()

func slotID(IDcard:int)->Slot:
	for i in shop.size():
		if shop[i].id == IDcard:
			return shop[i]
	
	return null
		
func dispo(IDcard:int)->bool:
	return not(slotID(IDcard) == null)
	
func libererSlotVide():
	for i in  shop.size():
		if shop[i].quantity == 0:
			shop.remove_at(i)

func fill()->void:
	libererSlotVide()
	while shop.size() < 9 and not(pioche.est_vide()):
		var new = pioche.draw()
		var slotexitant = slotID(new)
		if slotexitant == null:
			var newslot = Slot.new(new,1)
			shop.append(newslot)
		else:
			slotexitant.quantity += 1
		
	
