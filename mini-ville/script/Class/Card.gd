class_name Card

var id : int
var name : String
var type : String
var cost : int
var effect : Effect  # Référence vers un effet partagé
var description : String


func get_id() -> int:
	return id

func get_name() -> String:
	return name

func get_type() -> String:
	return type

func get_cost() -> int:
	return cost

func get_effect_description() -> String:
	if effect != null:
		return effect.getDescription()
	return "Aucun effet"
