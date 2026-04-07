extends Node

var nom: String = ""
var parties_jouees: int = 0
var parties_gagnees: int = 0
var rang: String = "legende"


func set_from_profile(data: Dictionary):
	nom = data.get("nom", "")
	parties_jouees = data.get("parties_jouees", 0)
	parties_gagnees = data.get("parties_gagnees", 0)
	rang = data.get("rang", "legende")


func is_logged_in() -> bool:
	return nom != ""
