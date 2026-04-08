extends Control

signal on_back

func _ready():
	$Panel/VBoxContainer/backbtn.pressed.connect(_on_back_pressed)
	$Panel/PanelParametres/MarginContainer/MainVBox/AudioVBox/SliderMusique.value_changed.connect(_on_musique_changed)
	$Panel/PanelParametres/MarginContainer/MainVBox/AudioVBox/SliderEffets.value_changed.connect(_on_effets_changed)
	var grid = $Panel/PanelParametres/MarginContainer/MainVBox/LangueVBox/LangueGrid
	grid.get_node("BtnFR").pressed.connect(func(): LocaleManager.set_language("fr"))
	grid.get_node("BtnEN").pressed.connect(func(): LocaleManager.set_language("en"))
#	grid.get_node("BtnDE").pressed.connect(func(): LocaleManager.set_language("de"))
#	grid.get_node("BtnES").pressed.connect(func(): LocaleManager.set_language("es"))


func _on_back_pressed():
	SoundManager.play_click()
	on_back.emit()
	hide()


func _on_musique_changed(value: float):
	$Panel/PanelParametres/MarginContainer/MainVBox/AudioVBox/MusiqueRow/MusiqueValue.text = str(int(value)) + "%"


func _on_effets_changed(value: float):
	$Panel/PanelParametres/MarginContainer/MainVBox/AudioVBox/EffetsRow/EffetsValue.text = str(int(value)) + "%"
