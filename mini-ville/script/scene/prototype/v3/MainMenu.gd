extends Control

@onready var main_screen: VBoxContainer = %MainScreen
@onready var setup_screen: VBoxContainer = %SetupScreen
@onready var player_count: OptionButton = %PlayerCount
@onready var player_names: VBoxContainer = %PlayerNames
@onready var play: Button = %Play
@onready var start: Button = %Start

func _ready() -> void:
	player_count.add_item("2 Players", 2)
	player_count.add_item("3 Players", 3)
	player_count.add_item("4 Players", 4)
	
	play.pressed.connect(_on_play_pressed)
	start.pressed.connect(_on_start_pressed)
	player_count.item_selected.connect(_on_player_count_changed)
	
	_on_player_count_changed(0) 

func _on_play_pressed() -> void:
	main_screen.hide()
	setup_screen.show()

func _on_player_count_changed(index: int) -> void:
	var count = player_count.get_item_id(index)
	
	for i in range(player_names.get_child_count()):
		var line_edit = player_names.get_child(i)
		line_edit.visible = i < count

func _on_start_pressed() -> void:
	GameData.player_names.clear()
	
	for i in range(player_names.get_child_count()):
		var line_edit = player_names.get_child(i) as LineEdit
		if line_edit.visible:
			if line_edit.text == "":
				GameData.player_names.append("Player " + str(i + 1))
			else:
				GameData.player_names.append(line_edit.text)
	
	print("Starting game with: ", GameData.player_names)
	
	get_tree().change_scene_to_file("res://scene/Prototype/V3/main.tscn")
