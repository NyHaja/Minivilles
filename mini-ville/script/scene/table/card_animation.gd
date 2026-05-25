@tool
extends Control

@export var tooltip_scale_target: Vector2 = Vector2(1.3, 1.3) # + Grand
var mouse_over: bool = false

# --- VARIABLES EXPORTÉES ---
@export_group("Contenu de la Carte")

@export var texture_normale: Texture2D:
	set(value):
		texture_normale = value
		if is_node_ready(): $Visual.texture_normal = value

@export var texture_hover: Texture2D:
	set(value):
		texture_hover = value
		if is_node_ready(): $Visual.texture_hover = value

@export var bulle_texture: Texture2D:
	set(value):
		bulle_texture = value
		if is_node_ready(): %Tooltip.texture = value

@export_group("Réglages Tooltip")
@export var tooltip_distance: float = 10.0

# --- RÉFÉRENCES ---
@onready var visual = $Visual
@onready var tooltip = %Tooltip

var selection_glow: Panel
var hover_tween: Tween
var current_tooltip_dir: String = "top"
var anim_speed := 0.15
var type_couleur_carte: int = -1
var card_data = null

func get_lang_folder() -> String:
	# Récupère la langue actuelle (ex: "fr", "en", "en_US")
	if TranslationServer.get_locale().begins_with("en"):
		return "English"
	return "French"

func _ready() -> void:
	if Engine.is_editor_hint(): return
	
	# Initialisation du pivot pour l'agrandissement depuis le bas
	visual.pivot_offset = Vector2(visual.size.x / 2.0, visual.size.y)
	
	# Initialisation du tooltip
	tooltip.modulate.a = 0.0
	tooltip.scale = Vector2(0.8, 0.8)
	tooltip.hide()
	
	# -------------------------------------------------------------
	# 1. CRÉATION OU MISE À JOUR DU HALO BLANC POUR LA CARTE
	# -------------------------------------------------------------
	selection_glow = visual.get_node_or_null("SelectionGlow")
	if not selection_glow:
		selection_glow = _create_glow_panel()
		visual.add_child(selection_glow)
	
	# On FORCE le style blanc au cas où un vieux halo jaune serait sauvegardé dans la scène
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.shadow_color = Color(1.0, 1.0, 1.0, 0.8) # BLANC PUR
	style.shadow_size = 15 # Taille réduite pour la carte
	style.set_corner_radius_all(8)
	selection_glow.add_theme_stylebox_override("panel", style)

	# -------------------------------------------------------------
	# 2. CRÉATION OU MISE À JOUR DU HALO BLANC POUR LE TOOLTIP
	# -------------------------------------------------------------
	var tooltip_glow = tooltip.get_node_or_null("TooltipGlow")
	if not tooltip_glow:
		tooltip_glow = Panel.new()
		tooltip_glow.name = "TooltipGlow"
		tooltip_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
		tooltip_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tooltip_glow.show_behind_parent = true
		tooltip.add_child(tooltip_glow)
		
	# On FORCE le style ici aussi pour être certain de la taille et couleur
	var t_style = StyleBoxFlat.new()
	t_style.bg_color = Color(0, 0, 0, 0)
	t_style.shadow_color = Color(1.0, 1.0, 1.0, 0.8) # BLANC PUR
	t_style.shadow_size = 20 # Taille réduite pour la bulle
	t_style.set_corner_radius_all(15) 
	tooltip_glow.add_theme_stylebox_override("panel", t_style)
	
	# Connexion des signaux
	visual.mouse_entered.connect(_on_mouse_entered)
	visual.mouse_exited.connect(_on_mouse_exited)

func _create_glow_panel() -> Panel:
	var p = Panel.new()
	p.name = "SelectionGlow"
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.show_behind_parent = true
	p.modulate.a = 0.0
	return p

# Dans card_animation.gd

# Variable pour s'assurer que le tooltip est grand

func _on_mouse_entered() -> void:
	mouse_over = true
	
	if hover_tween: hover_tween.kill()
	
	# 👇 CORRECTION ICI : On force le passage au premier plan absolu
	z_as_relative = false
	z_index = 4096
	
	hover_tween = create_tween().set_parallel(true)
	
	var elevation_carte = 20.0
	
	# 1. CARTE
	hover_tween.tween_property(visual, "scale", Vector2(1.1, 1.1), anim_speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	hover_tween.tween_property(visual, "position:y", -elevation_carte, anim_speed).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 2. HALO
	if selection_glow:
		hover_tween.tween_property(selection_glow, "modulate:a", 1.0, anim_speed)
		
	# 3. TOOLTIP
	if tooltip.texture != null:
		tooltip.show()
		tooltip.modulate.a = 0
		tooltip.scale = Vector2(0.3, 0.3)
		
		await get_tree().process_frame
		if not mouse_over: return 

		var t_size = tooltip.size
		var v_size = visual.size
		var t_center = t_size / 2.0
		var v_center = v_size / 2.0
		
		tooltip.pivot_offset = t_center
		var scaled_t_y = t_size.y * tooltip_scale_target.y
		var scaled_t_x = t_size.x * tooltip_scale_target.x
		var desired_pivot_x = v_center.x
		var desired_pivot_y = 0.0

		match current_tooltip_dir:
			"top":
				tooltip.rotation_degrees = 0
				desired_pivot_y = -elevation_carte - tooltip_distance - (scaled_t_y / 2.0)
			"bottom":
				tooltip.rotation_degrees = 180
				desired_pivot_y = -elevation_carte - tooltip_distance - (scaled_t_y / 2.0)
			"left":
				tooltip.rotation_degrees = -90
				desired_pivot_y = -elevation_carte - tooltip_distance - (scaled_t_x / 2.0)
			"right":
				tooltip.rotation_degrees = 90
				desired_pivot_y = -elevation_carte - tooltip_distance - (scaled_t_x / 2.0)

		tooltip.position = Vector2(desired_pivot_x, desired_pivot_y) - t_center
		
		hover_tween.tween_property(tooltip, "modulate:a", 1.0, anim_speed)
		hover_tween.tween_property(tooltip, "scale", tooltip_scale_target, anim_speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_mouse_exited() -> void:
	mouse_over = false
	
	if hover_tween: hover_tween.kill()
	hover_tween = create_tween().set_parallel(true)
	
	# 👇 CORRECTION ICI : On enlève le z_index tout de suite pour ne pas bloquer les autres cartes
	z_as_relative = true
	z_index = 0
	
	# 1. CARTE
	hover_tween.tween_property(visual, "scale", Vector2(1.0, 1.0), anim_speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	hover_tween.tween_property(visual, "position:y", 0.0, anim_speed).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# 2. HALO
	if selection_glow:
		hover_tween.tween_property(selection_glow, "modulate:a", 0.0, anim_speed)
		
	# 3. TOOLTIP
	if tooltip.texture != null:
		hover_tween.tween_property(tooltip, "modulate:a", 0.0, anim_speed)
		hover_tween.tween_property(tooltip, "scale", Vector2(0.3, 0.3), anim_speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		await hover_tween.finished
		if not mouse_over: tooltip.hide()

func setup_card(card_data, dir: String = "top") -> void:
	type_couleur_carte = card_data.get_color()
	self.card_data = card_data
	var card_name = card_data.get_name()
	var card_color = card_data.get_color()
	var clean_name = get_clean_file_name(card_name, card_color)

	# --- 1. CHARGEMENT SÉCURISÉ DE L'IMAGE DE LA CARTE ---
	var path_basis = "res://assets/Cards/" + get_lang_folder() + "/" + "Establishments/" + clean_name + "_1.png"
	var tex_carte = load(path_basis) 
	
	var visual_node = get_node_or_null("Visual") 
	if is_instance_valid(visual_node) and tex_carte != null:
		if visual_node is TextureButton:
			visual_node.texture_normal = tex_carte
		elif visual_node is TextureRect:
			visual_node.texture = tex_carte

	# --- 2. SÉCURITÉ POUR LE CHARGEMENT DU TOOLTIP ---
	# On récupère la variable tooltip existante (probablement un @onready) ou le noeud directement
	var tooltip_node = get("tooltip") 
	if tooltip_node == null:
		tooltip_node = get_node_or_null("Tooltip")
		
	# Si le noeud n'est pas encore prêt dans la scène, on attend une frame
	if tooltip_node == null:
		if not is_node_ready():
			await ready
		tooltip_node = get("tooltip")
		if tooltip_node == null:
			tooltip_node = get_node_or_null("Tooltip")

	# Si on a bien récupéré le Tooltip, on lui applique l'image
	if is_instance_valid(tooltip_node):
		var tip_path = "res://assets/Tooltips/" + get_lang_folder() + "/" + "tooltip_" + clean_name + ".png"
		var tip_tex = load(tip_path)
		
		if tip_tex:
			tooltip_node.texture = tip_tex
		else:
			var placeholder = "res://assets/Tooltips/tooltip_marche_de_fruits_et_legumes.png"
			var placeholder_tex = load(placeholder)
			if placeholder_tex:
				tooltip_node.texture = placeholder_tex
			else:
				tooltip_node.texture = null 

		current_tooltip_dir = dir
		
		if tooltip_node.texture:
			tooltip_node.pivot_offset = tooltip_node.size / 2.0

func get_clean_file_name(card_name: String, color: int = -1) -> String:
	var prefix = ""
	match color:
		CardColor.Type.BLUE: prefix = "bleu_"
		CardColor.Type.GREEN: prefix = "vert_"
		CardColor.Type.RED: prefix = "rouge_"
		CardColor.Type.PURPLE: prefix = "violet_"
		
	var clean_name = card_name.to_lower().replace(" ", "_").replace("'", "_")
	clean_name = clean_name.replace("é", "e").replace("è", "e").replace("à", "a")
	return prefix + clean_name

func set_badge_count(count: int) -> void:
	var target_visual = $Visual 
	
	var existing_badge = target_visual.get_node_or_null("CountBadge")
	
	var badge = existing_badge
	if badge == null:
		badge = Label.new()
		badge.name = "CountBadge"
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.show_behind_parent = false
		
		badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		
		badge.offset_top = 3
		badge.offset_right = -7
		
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		badge.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		
		var label_settings = LabelSettings.new()
		label_settings.font_size = 15
		label_settings.font_color = Color.WHITE
		label_settings.font = load("res://assets/Fonts/Exo_2/static/Exo2-BlackItalic.ttf")
		
		label_settings.outline_size = 6
		label_settings.outline_color = Color(0, 0, 0, 0.8) 
		
		badge.label_settings = label_settings
		
		target_visual.add_child(badge) 
	
	badge.text = "x" + str(count)
	
func _get_activation_glow_color() -> Color:
	match type_couleur_carte:
		CardColor.Type.BLUE: return Color(0.2, 0.6, 1.0, 1.0)
		CardColor.Type.GREEN: return Color(0.2, 0.9, 0.2, 1.0)
		CardColor.Type.RED: return Color(1.0, 0.2, 0.2, 1.0)
		CardColor.Type.PURPLE: return Color(0.7, 0.2, 1.0, 1.0)
		_: return Color(1.0, 1.0, 1.0, 1.0)

func animer_montee() -> Tween:
	# 👇 CORRECTION ICI
	z_as_relative = false
	z_index = 4096

	var style = selection_glow.get_theme_stylebox("panel")
	style.shadow_color = _get_activation_glow_color()

	var tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property(visual, "position:y", -35.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(selection_glow, "modulate:a", 1.0, 0.3)

	return tween

func animer_descente() -> Tween:
	var tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property(visual, "position:y", 0.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(selection_glow, "modulate:a", 0.0, 0.3)
	
	# Nettoyage à la toute fin de la descente
	tween.chain().tween_callback(func():
		var style = selection_glow.get_theme_stylebox("panel")
		style.shadow_color = Color(1.0, 1.0, 1.0, 0.8)
		# 👇 CORRECTION ICI
		z_as_relative = true
		z_index = 0
	)
	
	return tween
