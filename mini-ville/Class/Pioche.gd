extends Node
class_name  Pioche

var pioche : Array[int]


func _init() -> void: # A REVOIR AVEC CLEMENT LES ID DES CARTES 
	for i in range(0,15): # test
		pioche.push_front(i)

func draw() -> int:
	return pioche.pop_back()

func est_vide() -> bool:
	return pioche.size() == 0
