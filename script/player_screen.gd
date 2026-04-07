extends Control

var pop_rule_scene = preload("res://scenes/rules_panel.tscn")
var popup_rule

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	popup_rule = pop_rule_scene.instantiate()
	add_child(popup_rule)
	popup_rule.hide()

	popup_rule.on_back.connect(_on_popup_back)

	$gameMode/playbtn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/ui/mode_de_jeu.tscn"))


#------------- HEADER --------------

# bouton pour afficher les règles
func affiche_popup_rule():
	SoundManager.play_click()
	$gameMode.hide()
	popup_rule.show()
	
func affiche_parametre() -> void:
	SoundManager.play_click()
	
func _on_popup_back():
	$gameMode.show()
	

	
	
