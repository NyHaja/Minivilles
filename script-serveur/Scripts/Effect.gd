class_name Effect


var id : int
var description : String



func _init(p_id: int, p_description: String):
	id = p_id
	description = p_description

# Méthode abstraite
func appliquer(game: GameServer, owner: Player, roller: Player):
	assert(false, "appliquer() must be implemented in child class")


func peutActiver(game: GameServer, owner: Player, roller: Player) -> bool:
	return true

func getDescription() -> String:
	return description
