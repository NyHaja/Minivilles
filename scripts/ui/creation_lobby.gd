extends Control

var durations = ["1 min", "2 min", "3 min", "5 min"]
var dur_index = 0
var nb_joueurs = 4

func _ready():
	$ArrowGaucheDuree.pressed.connect(_on_duree_gauche)
	$ArrowDroiteDuree.pressed.connect(_on_duree_droite)
	$ArrowGaucheJoueurs.pressed.connect(_on_joueurs_gauche)
	$ArrowDroiteJoueurs.pressed.connect(_on_joueurs_droite)
	_update_joueurs()



func _on_duree_gauche():
	dur_index = (dur_index - 1 + durations.size()) % durations.size()
	$LabelDuree.text = durations[dur_index]


func _on_duree_droite():
	dur_index = (dur_index + 1) % durations.size()
	$LabelDuree.text = durations[dur_index]


func _on_joueurs_gauche():
	nb_joueurs = max(2, nb_joueurs - 1)
	_update_joueurs()


func _on_joueurs_droite():
	nb_joueurs = min(4, nb_joueurs + 1)
	_update_joueurs()


func _update_joueurs():
	$Joueur1.visible = nb_joueurs >= 1
	$Joueur2.visible = nb_joueurs >= 2
	$Joueur3.visible = nb_joueurs >= 3
	$Joueur4.visible = nb_joueurs >= 4
