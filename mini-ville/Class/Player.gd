extends Node
class_name  Player

var monumentCount: int
var diceCount: int
var username:String
var balance :int = 0 
var monumentArray : Array[bool] = []
var deck : Array[int]

func activateEffect(color:Establishment.COLOR)->void:
	pass

func recieveGold(amount: int) -> void:
	balance += amount

func _init(username) -> void:
	self.username = username
	monumentArray.resize(6)
	monumentArray.fill(false)
	monumentArray.insert(Monument.MONUMENT_ID.Gare,true)
