class_name Card

var id : int
var name : String
var type : String
var cost : int
var effect : Effect  # Référence vers un effet partagé


# Constructeur
func instancier_carte(p_effect: Effect, p_name: String, p_type: String, p_cost: int):
	effect = p_effect
	name = p_name
	type = p_type
	cost = p_cost


func getDescription() -> String:
	return name + " (" + type + ") - Cost: " + str(cost) + " - " + effect.getDescription()
