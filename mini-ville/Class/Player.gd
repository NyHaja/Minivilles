extends Node
class_name  Player

var monumentCount: int
var dicecount: int
var pseudo:String
var balance :int = 0 
var  monumentArray : Array[bool] = []

func activateEffect(color:Establishment.COULEUR)->void:
	pass

func _init(pseudo) -> void:
	self.pseudo = pseudo
	monumentArray.resize(6)
	monumentArray.fill(false)
	monumentArray.insert(Monument.MONUMENT_ID.Gare,true)
