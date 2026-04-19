extends Control

var code := ""
var boxes := []
var panels := []

var style_bande_normal := StyleBoxFlat.new()
var style_bande_hover := StyleBoxFlat.new()
var style_filled := StyleBoxFlat.new()
var style_empty := StyleBoxFlat.new()
var style_error := StyleBoxFlat.new()


func _ready():
	_init_styles()
	boxes = [
		$PopupPanel/CodeRow/Box1/LabelBox1,
		$PopupPanel/CodeRow/Box2/LabelBox2,
		$PopupPanel/CodeRow/Box3/LabelBox3,
		$PopupPanel/CodeRow/Box4/LabelBox4,
		$PopupPanel/CodeRow/Box5/LabelBox5,
		$PopupPanel/CodeRow/Box6/LabelBox6,
	]
	panels = [
		$PopupPanel/CodeRow/Box1,
		$PopupPanel/CodeRow/Box2,
		$PopupPanel/CodeRow/Box3,
		$PopupPanel/CodeRow/Box4,
		$PopupPanel/CodeRow/Box5,
		$PopupPanel/CodeRow/Box6,
	]
	$PopupPanel/BtnRejoindre.pressed.connect(_on_rejoindre)
	$PopupPanel/BtnFermer.pressed.connect(_fermer_popup)
	$BtnRetour/Fleche.pressed.connect(func():
		get_tree().change_scene_to_file("res://scene/Multijoueur/choix_lobby.tscn"))
	_actualiser_liste()


func _init_styles():
	style_bande_normal.bg_color = Color(1, 1, 1, 0.08)
	style_bande_normal.corner_radius_top_left = 12
	style_bande_normal.corner_radius_top_right = 12
	style_bande_normal.corner_radius_bottom_right = 12
	style_bande_normal.corner_radius_bottom_left = 12

	style_bande_hover.bg_color = Color(1, 1, 1, 0.18)
	style_bande_hover.corner_radius_top_left = 12
	style_bande_hover.corner_radius_top_right = 12
	style_bande_hover.corner_radius_bottom_right = 12
	style_bande_hover.corner_radius_bottom_left = 12
	style_bande_hover.border_width_left = 2
	style_bande_hover.border_width_top = 2
	style_bande_hover.border_width_right = 2
	style_bande_hover.border_width_bottom = 2
	style_bande_hover.border_color = Color(1, 1, 1, 0.4)

	style_filled.bg_color = Color(1, 1, 1, 0.18)
	style_filled.border_width_left = 4
	style_filled.border_width_top = 4
	style_filled.border_width_right = 4
	style_filled.border_width_bottom = 4
	style_filled.border_color = Color(1, 1, 1, 0.9)
	style_filled.corner_radius_top_left = 18
	style_filled.corner_radius_top_right = 18
	style_filled.corner_radius_bottom_right = 18
	style_filled.corner_radius_bottom_left = 18

	style_empty.bg_color = Color(1, 1, 1, 0.06)
	style_empty.border_width_left = 4
	style_empty.border_width_top = 4
	style_empty.border_width_right = 4
	style_empty.border_width_bottom = 4
	style_empty.border_color = Color(1, 1, 1, 0.35)
	style_empty.corner_radius_top_left = 18
	style_empty.corner_radius_top_right = 18
	style_empty.corner_radius_bottom_right = 18
	style_empty.corner_radius_bottom_left = 18

	style_error.bg_color = Color(0.6, 0.05, 0.05, 0.5)
	style_error.border_width_left = 4
	style_error.border_width_top = 4
	style_error.border_width_right = 4
	style_error.border_width_bottom = 4
	style_error.border_color = Color(1, 0.1, 0.1, 1)
	style_error.corner_radius_top_left = 18
	style_error.corner_radius_top_right = 18
	style_error.corner_radius_bottom_right = 18
	style_error.corner_radius_bottom_left = 18


func _unhandled_key_input(event):
	if not $PopupPanel.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.unicode >= 32 and code.length() < 6:
			code += char(event.unicode).to_upper()
			_update_boxes()
		elif event.keycode == KEY_BACKSPACE and code.length() > 0:
			code = code.left(code.length() - 1)
			_update_boxes()


func _update_boxes():
	for i in 6:
		if i < code.length():
			boxes[i].text = code[i]
			panels[i].add_theme_stylebox_override("panel", style_filled)
		else:
			boxes[i].text = ""
			panels[i].add_theme_stylebox_override("panel", style_empty)


func _actualiser_liste():
	var list = $PanelListe/ScrollContainer/LobbyList
	for child in list.get_children():
		if child.name != "LabelVide":
			child.queue_free()

	var lobbies = LobbyManager.get_lobbies()
	$PanelListe/ScrollContainer/LobbyList/LabelVide.visible = lobbies.is_empty()

	var now = Time.get_unix_time_from_system()
	for lobby in lobbies:
		var elapsed = int(now - lobby["created_at"])
		var remaining = max(0, 300 - elapsed)
		var mins = remaining / 60
		var secs = remaining % 60
		_creer_bande_lobby(lobby["code"], "%d:%02d" % [mins, secs], lobby.get("is_private", false))


func _creer_bande_lobby(code_lobby: String, temps_restant: String, is_private: bool = false):
	var list = $PanelListe/ScrollContainer/LobbyList

	var bande = Panel.new()
	bande.custom_minimum_size = Vector2(0, 50)
	bande.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bande.add_theme_stylebox_override("panel", style_bande_normal)
	bande.mouse_filter = Control.MOUSE_FILTER_STOP

	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 0)

	var lbl_code = Label.new()
	lbl_code.text = code_lobby
	lbl_code.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_code.add_theme_font_override("font", load("res://Fonts/EricaOne-Regular.ttf"))
	lbl_code.add_theme_font_size_override("font_size", 26)
	lbl_code.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	lbl_code.add_theme_color_override("font_outline_color", Color(0.168, 0.2, 0.486, 1))
	lbl_code.add_theme_constant_override("outline_size", 3)
	lbl_code.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_code.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_code.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var lbl_temps = Label.new()
	lbl_temps.text = temps_restant
	lbl_temps.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_temps.add_theme_font_override("font", load("res://Fonts/Exo_2/static/Exo2-BoldItalic.ttf"))
	lbl_temps.add_theme_font_size_override("font_size", 20)
	lbl_temps.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	lbl_temps.add_theme_color_override("font_outline_color", Color(0.168, 0.2, 0.486, 1))
	lbl_temps.add_theme_constant_override("outline_size", 2)
	lbl_temps.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_temps.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_temps.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var lbl_visibilite = Label.new()
	lbl_visibilite.text = tr("Privée") if is_private else tr("Public")
	lbl_visibilite.custom_minimum_size = Vector2(100, 0)
	lbl_visibilite.size_flags_horizontal = Control.SIZE_SHRINK_END
	lbl_visibilite.add_theme_font_override("font", load("res://Fonts/Exo_2/static/Exo2-BoldItalic.ttf"))
	lbl_visibilite.add_theme_font_size_override("font_size", 18)
	lbl_visibilite.add_theme_color_override("font_color", Color(1, 0.4, 0.4, 1) if is_private else Color(0.4, 1, 0.4, 1))
	lbl_visibilite.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	lbl_visibilite.add_theme_constant_override("outline_size", 2)
	lbl_visibilite.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_visibilite.clip_text = true
	lbl_visibilite.mouse_filter = Control.MOUSE_FILTER_IGNORE

	hbox.add_child(lbl_code)
	hbox.add_child(lbl_temps)
	hbox.add_child(lbl_visibilite)
	bande.add_child(hbox)

	bande.mouse_entered.connect(func():
		bande.add_theme_stylebox_override("panel", style_bande_hover))
	bande.mouse_exited.connect(func():
		bande.add_theme_stylebox_override("panel", style_bande_normal))
	bande.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_private:
				_ouvrir_popup()
			else:
				get_tree().set_meta("lobby_code", code_lobby)
				get_tree().change_scene_to_file("res://scene/Multijoueur/attente_lobby.tscn"))

	list.add_child(bande)


func _ouvrir_popup():
	code = ""
	for i in 6:
		boxes[i].text = ""
		panels[i].add_theme_stylebox_override("panel", style_empty)
	$PopupPanel.visible = true


func _fermer_popup():
	$PopupPanel.visible = false
	code = ""


func _on_rejoindre():
	if code.length() < 6:
		return
	var lobbies = LobbyManager.get_lobbies()
	var valide = false
	for lobby in lobbies:
		if lobby["code"] == code:
			valide = true
			break
	if valide:
		get_tree().set_meta("lobby_code", code)
		get_tree().change_scene_to_file("res://scene/Multijoueur/attente_lobby.tscn")
	else:
		_feedback_erreur()


func _feedback_erreur():
	for panel in panels:
		panel.add_theme_stylebox_override("panel", style_error)
	var tween = create_tween()
	var popup = $PopupPanel
	var pos_origine = popup.position
	tween.tween_property(popup, "position", pos_origine + Vector2(-12, 0), 0.05)
	tween.tween_property(popup, "position", pos_origine + Vector2(12, 0), 0.05)
	tween.tween_property(popup, "position", pos_origine + Vector2(-8, 0), 0.05)
	tween.tween_property(popup, "position", pos_origine + Vector2(8, 0), 0.05)
	tween.tween_property(popup, "position", pos_origine, 0.05)
	await tween.finished
	for i in 6:
		if i < code.length():
			panels[i].add_theme_stylebox_override("panel", style_filled)
		else:
			panels[i].add_theme_stylebox_override("panel", style_empty)
