extends Control


func _ready():
	$Panel/VBoxContainer/backbtn.pressed.connect(_on_back_pressed)
	$Panel/PanelParametres/MarginContainer/MainVBox/AudioVBox/SliderMusique.value_changed.connect(_on_musique_changed)
	$Panel/PanelParametres/MarginContainer/MainVBox/AudioVBox/SliderEffets.value_changed.connect(_on_effets_changed)


func _on_back_pressed():
	queue_free()


func _on_musique_changed(value: float):
	$Panel/PanelParametres/MarginContainer/MainVBox/AudioVBox/MusiqueRow/MusiqueValue.text = str(int(value)) + "%"


func _on_effets_changed(value: float):
	$Panel/PanelParametres/MarginContainer/MainVBox/AudioVBox/EffetsRow/EffetsValue.text = str(int(value)) + "%"
