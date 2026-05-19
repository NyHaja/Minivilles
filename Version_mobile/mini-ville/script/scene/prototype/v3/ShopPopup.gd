extends CanvasLayer

signal shop_card_clicked(card_id: int)

@onready var shop_board: ShopBoard = %ShopBoard
@onready var overlay: ColorRect = %Overlay
@onready var close_button: TextureButton = %backbtn
@onready var popup_panel: PanelContainer = %PopupPanel

func _ready() -> void:
	hide()
	close_button.pressed.connect(_on_close_pressed)
	overlay.gui_input.connect(_on_overlay_input)
	shop_board.shop_card_clicked.connect(func(id): shop_card_clicked.emit(id))
	get_viewport().size_changed.connect(_on_window_resized)
	_on_window_resized()

func _on_window_resized() -> void:
	var screen = get_viewport().get_visible_rect().size
	var w = screen.x * 0.4
	var h = screen.y * 0.6
	popup_panel.offset_left = -w / 2
	popup_panel.offset_right = w / 2
	popup_panel.offset_top = -h / 2
	popup_panel.offset_bottom = h / 2
	popup_panel.pivot_offset = Vector2(w / 2, h / 2)
	
	var card_w = int(screen.x * 0.10)
	var card_h = int(card_w * 1.35)
	shop_board.shop_card_w = card_w
	shop_board.shop_card_h = card_h

func open(shop_data) -> void:
	_on_window_resized()
	shop_board.update_shop(shop_data)
	show()
	popup_panel.modulate.a = 0.0
	popup_panel.scale = Vector2(0.88, 0.88)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(popup_panel, "modulate:a", 1.0, 0.18)
	tween.tween_property(popup_panel, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func close() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(popup_panel, "modulate:a", 0.0, 0.12)
	tween.tween_property(popup_panel, "scale", Vector2(0.92, 0.92), 0.12)
	await tween.finished
	hide()

func _on_close_pressed() -> void:
	close()

func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close()

func update_shop(shop_data) -> void:
	shop_board.update_shop(shop_data)

func update_network_shop(shop_data) -> void:
	shop_board.update_network_shop(shop_data)

func open_network(shop_data) -> void:
	_on_window_resized()
	shop_board.update_network_shop(shop_data)
	show()
	popup_panel.modulate.a = 0.0
	popup_panel.scale = Vector2(0.88, 0.88)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(popup_panel, "modulate:a", 1.0, 0.18)
	tween.tween_property(popup_panel, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func set_actions_enabled(can_act: bool) -> void:
	shop_board.set_actions_enabled(can_act)
