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
