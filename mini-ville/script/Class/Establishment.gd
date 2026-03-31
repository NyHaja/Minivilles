class_name Establishment extends Card

# Attributs Card
#var effect : Effect
#var id : int
#var name : String
#var cost : int
#var description : String

# Attributs Establishment
var activation : Array  # [min, max]
var color : CardColor.Type
var icon : Icon.Type



func NewCard(
	p_effect: Effect, 
	p_id: int, 
	p_name: String, 
	p_icon: Icon.Type, 
	p_color: CardColor.Type, 
	p_cost: int, 
	p_description: String, 
	p_activationNum: Array
):
	effect = p_effect
	id = p_id
	name = p_name
	icon = p_icon
	color = p_color
	cost = p_cost
	description = p_description
	activation = p_activationNum


func get_activation_num() -> Array:
	return activation

func get_color() -> CardColor.Type:
	return color

func get_icon() -> Icon.Type:
	return icon
