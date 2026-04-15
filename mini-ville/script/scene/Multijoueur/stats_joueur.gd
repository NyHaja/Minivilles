extends Control


func _ready():
	$BtnRetour.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_retour())


func setup(nom: String, parties_jouees: int, parties_gagnees: int, rang: String = "legende"):
	$Content/ProfileRow/NomJoueur.text = nom
	$Content/StatsContainer/Stat1Row/StatJouees.text = tr("Nombre de partie(s) jouée(s) : %d") % parties_jouees
	$Content/StatsContainer/Stat2Row/StatGagnees.text = tr("Nombre de partie(s) gagnée(s) : %d") % parties_gagnees
	$Content/RangContainer/BadgeWrap/BadgeRang.texture = load("res://assets/ui/stats_joueur/badge_%s.png" % rang)
	$Content/RangContainer/LegendeTxtWrap/TexteLegende.text = rang.capitalize()


func _on_retour():
	queue_free()
