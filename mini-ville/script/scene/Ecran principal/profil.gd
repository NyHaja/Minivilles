extends Control

const CONTENT = "CenterContainer/Card/VBoxCard/MarginContent/VBoxContent"

func _ready() -> void:
	$BtnRetour/Fleche.pressed.connect(_on_fermer)
	get_node(CONTENT + "/BtnModifier").pressed.connect(_on_modifier)
	get_node(CONTENT + "/BtnRow/BtnMotDePasse").pressed.connect(_on_mot_de_passe)
	get_node(CONTENT + "/BtnRow/BtnDeconnexion").pressed.connect(_on_deconnexion)


func _on_fermer() -> void:
	SoundManager.play_click()
	get_tree().change_scene_to_file("res://scene/Ecran principale/connected_screen.tscn")


func _on_modifier() -> void:
	SoundManager.play_click()


func _on_mot_de_passe() -> void:
	SoundManager.play_click()


func _on_deconnexion() -> void:
	SoundManager.play_click()
	get_tree().change_scene_to_file("res://scene/Ecran principale/connected_screen.tscn")
