class_name Card

var id : int
var name : String
var type : String
var cost : int
var effect : Effect  # Référence vers un effet partagé


func getDescription() -> String:
	return name + " (" + type + ") - Cost: " + str(cost) + " - " + effect.getDescription()
