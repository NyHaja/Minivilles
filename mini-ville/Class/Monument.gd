class_name Monument
 
# Attributs de Card (interface)
var effect : Effect
var id : int
var name : String
var cost : int
var description : String
 
 
# Constructeur pour Monument (pas d'activation, couleur, ou icône)
func NewMonument(
	p_effect: Effect,
	p_id: int,
	p_name: String,
	p_cost: int,
	p_description: String
):
	effect = p_effect
	id = p_id
	name = p_name
	cost = p_cost
	description = p_description
 
 
func get_name() -> String:
	return name
 
func get_id() -> int:
	return id
 
func get_cost() -> int:
	return cost
 
func get_description() -> String:
	return description
 
func get_effect() -> Effect:
	return effect
