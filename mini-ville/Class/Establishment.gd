class_name Establishment

# Attributs Card
var effect : Effect
var id : int
var name : String
var cost : int
var description : String

# Attributs Establishment
var activationNum : Array  # [min, max]
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
	activationNum = p_activationNum


# vérifier si la carte s'active avec un res de dés
func est_activee(resultat_des: int) -> bool:
	return resultat_des >= activationNum[0] and resultat_des <= activationNum[1]


# Getter pour obtenir la description complète (Avec le num d'activation en plus que la méthode de card)
func get_description_complete() -> String:
	var activation = str(activationNum[0]) if activationNum[0] == activationNum[1] else str(activationNum[0]) + "-" + str(activationNum[1])
	return "[" + activation + "] " + name + " (" + str(cost) + "💰) - " + description
