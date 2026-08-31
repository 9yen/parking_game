extends Control

const GameStateScript = preload("res://scripts/domain/game_state.gd")
const SaveServiceScript = preload("res://scripts/services/save_service.gd")
const LocalizationScript = preload("res://scripts/services/localization_service.gd")

var game_state: ParkingGameState
var words: ParkingLocalization
var selected_lot_id := "npc_morning"
var compact_mode := false
var refresh_accumulator := 0.0
var notice_key := "hint.ready"
var notice_values: Array = []

func _ready() -> void:
	game_state = SaveServiceScript.load_game()
	words = LocalizationScript.new()
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	if OS.get_cmdline_user_args().has("--compact-preview"):
		compact_mode = true
		DisplayServer.window_set_size(Vector2i(480, 720))
	theme = _create_app_theme()
	_build_interface()
	get_tree().set_auto_accept_quit(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and game_state != null:
		SaveServiceScript.save_game(game_state)
		get_tree().quit()

func _process(delta: float) -> void:
	refresh_accumulator += delta
	if refresh_accumulator < 1.0 or game_state == null:
		return
	refresh_accumulator = 0.0
	var reports := game_state.process_automatic_returns(Time.get_unix_time_from_system())
	if not reports.is_empty():
		notice_key = "notice.auto_return"
		SaveServiceScript.save_game(game_state)
	_build_interface()

func _build_interface() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var background := ColorRect.new()
	background.color = Color("#eef4f0")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24 if not compact_mode else 14)
	margin.add_theme_constant_override("margin_right", 24 if not compact_mode else 14)
	margin.add_theme_constant_override("margin_top", 20 if not compact_mode else 12)
	margin.add_theme_constant_override("margin_bottom", 20 if not compact_mode else 12)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	margin.add_child(scroll)
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 14)
	scroll.add_child(page)
	page.add_child(_build_header())
	page.add_child(_build_own_lot())
	var content: BoxContainer
	if compact_mode:
		content = VBoxContainer.new()
	else:
		content = HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	page.add_child(content)
	var garage_panel := _build_garage_panel()
	var lot_panel := _build_lot_panel()
	garage_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lot_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(garage_panel)
	content.add_child(lot_panel)
	var notice := Label.new()
	notice.text = words.text(notice_key, notice_values)
	notice.add_theme_color_override("font_color", Color("#40554d"))
	page.add_child(notice)

func _build_header() -> Control:
	var row := HBoxContainer.new()
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = words.text("app.title")
	title.add_theme_font_size_override("font_size", 26 if not compact_mode else 20)
	title.add_theme_color_override("font_color", Color("#20382f"))
	title_box.add_child(title)
	if not compact_mode:
		var subtitle := Label.new()
		subtitle.text = words.text("app.subtitle")
		subtitle.add_theme_color_override("font_color", Color("#6b7d76"))
		title_box.add_child(subtitle)
	row.add_child(title_box)
	var stats := Label.new()
	stats.text = "%s\n%s" % [words.text("stats.coins", [game_state.coins]), words.text("stats.level", [game_state.player_level, game_state.player_xp])]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(stats)
	var language := Button.new()
	language.text = words.text("action.language")
	language.pressed.connect(_on_language_pressed)
	row.add_child(language)
	var window_button := Button.new()
	window_button.text = words.text("action.normal" if compact_mode else "action.compact")
	window_button.pressed.connect(_on_window_mode_pressed)
	row.add_child(window_button)
	return row

func _build_garage_panel() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#ffffff")))
	var margin := _inner_margin()
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	var heading := Label.new()
	heading.text = "%s  ·  %s" % [words.text("section.garage"), words.text("garage.capacity", [game_state.cars.size(), game_state.garage_capacity])]
	heading.add_theme_font_size_override("font_size", 18)
	box.add_child(heading)
	for car in game_state.cars:
		box.add_child(_build_car_row(car))
	return panel

func _build_own_lot() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#dfece5")))
	var margin := _inner_margin(10)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)
	var heading := Label.new()
	heading.text = words.text("section.own_lot")
	box.add_child(heading)
	var slots := GridContainer.new()
	slots.columns = 2 if compact_mode else 4
	slots.add_theme_constant_override("h_separation", 8)
	slots.add_theme_constant_override("v_separation", 4)
	box.add_child(slots)
	for index in game_state.own_lot_slots.size():
		var slot := Label.new()
		slot.text = "P%d  %s" % [index + 1, words.text("slot.friend_ready")]
		slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_theme_color_override("font_color", Color("#597067"))
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slots.add_child(slot)
	return panel

func _build_car_row(car: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _panel_style(Color("#f7faf8")))
	var margin := _inner_margin(10)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)
	var swatch := ColorRect.new()
	swatch.color = Color(str(car["color"]))
	swatch.custom_minimum_size = Vector2(42, 42)
	row.add_child(swatch)
	var description := VBoxContainer.new()
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := Label.new()
	name_label.text = words.text(str(car["name_key"]))
	name_label.add_theme_font_size_override("font_size", 16)
	description.add_child(name_label)
	var status := Label.new()
	if car["state"] == GameStateScript.CAR_GARAGED:
		status.text = words.text("car.garaged", [float(car["rate_per_second"])])
	else:
		var preview := game_state.preview_rewards(str(car["id"]), Time.get_unix_time_from_system())
		status.text = words.text("car.parked", [_format_duration(int(preview["elapsed_seconds"])), int(preview["visitor_coins"])])
	status.add_theme_color_override("font_color", Color("#65756f"))
	description.add_child(status)
	row.add_child(description)
	var action := Button.new()
	if car["state"] == GameStateScript.CAR_GARAGED:
		action.text = words.text("action.park")
		action.pressed.connect(_on_park_pressed.bind(str(car["id"])))
	else:
		action.text = words.text("action.recall")
		action.pressed.connect(_on_recall_pressed.bind(str(car["id"])))
	row.add_child(action)
	return card

func _build_lot_panel() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#ffffff")))
	var margin := _inner_margin()
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)
	var heading_row := HBoxContainer.new()
	var heading := Label.new()
	heading.text = words.text("section.lot")
	heading.add_theme_font_size_override("font_size", 18)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.add_child(heading)
	var picker := OptionButton.new()
	for index in game_state.npc_lots.size():
		var lot: Dictionary = game_state.npc_lots[index]
		picker.add_item(words.text(str(lot["name_key"])))
		picker.set_item_metadata(index, str(lot["id"]))
		if lot["id"] == selected_lot_id:
			picker.select(index)
	picker.item_selected.connect(_on_lot_selected.bind(picker))
	heading_row.add_child(picker)
	box.add_child(heading_row)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	box.add_child(grid)
	var lot := game_state.find_lot(selected_lot_id)
	for index in GameStateScript.GameConfigScript.SLOT_COUNT:
		grid.add_child(_build_slot(lot["slots"][index], index))
	return panel

func _build_slot(slot, index: int) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(150, 105 if not compact_mode else 72)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _panel_style(Color("#e8eeeb"), 2, Color("#b9c8c1")))
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if slot == null:
		label.text = "P%d\n%s" % [index + 1, words.text("slot.empty")]
		label.add_theme_color_override("font_color", Color("#789087"))
	else:
		var car := game_state.find_car(str(slot["car_id"]))
		label.text = words.text("slot.occupied", [words.text(str(car["name_key"])), _format_duration(Time.get_unix_time_from_system() - int(slot["started_at"]))])
		label.add_theme_color_override("font_color", Color("#294a3d"))
	card.add_child(label)
	return card

func _on_park_pressed(car_id: String) -> void:
	var slot_index := game_state.first_empty_slot(selected_lot_id)
	var result := game_state.park_car(car_id, selected_lot_id, slot_index, Time.get_unix_time_from_system())
	if result.get("ok", false):
		notice_key = "notice.parked"
		notice_values = [words.text(str(game_state.find_car(car_id)["name_key"]))]
		SaveServiceScript.save_game(game_state)
	else:
		_set_error_notice(str(result.get("error_key", "error.generic")))
	_build_interface()

func _on_recall_pressed(car_id: String) -> void:
	var result := game_state.recall_car(car_id, Time.get_unix_time_from_system())
	if result.get("ok", false):
		notice_key = "notice.recalled"
		notice_values = [int(result["visitor_coins"]), int(result["player_xp"])]
		SaveServiceScript.save_game(game_state)
	else:
		_set_error_notice(str(result.get("error_key", "error.generic")))
	_build_interface()

func _on_lot_selected(index: int, picker: OptionButton) -> void:
	selected_lot_id = str(picker.get_item_metadata(index))
	_build_interface()

func _on_language_pressed() -> void:
	words.toggle_locale()
	_build_interface()

func _on_window_mode_pressed() -> void:
	compact_mode = not compact_mode
	DisplayServer.window_set_size(Vector2i(480, 720) if compact_mode else Vector2i(1120, 720))
	_build_interface()

func _set_error_notice(error_key: String) -> void:
	notice_key = error_key if ParkingLocalization.TEXT[words.locale].has(error_key) else "error.generic"
	notice_values = []

func _format_duration(total_seconds: int) -> String:
	var safe_seconds := maxi(0, total_seconds)
	var hours := safe_seconds / 3600
	var minutes := (safe_seconds % 3600) / 60
	var seconds := safe_seconds % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

func _inner_margin(amount: int = 14) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", amount)
	margin.add_theme_constant_override("margin_right", amount)
	margin.add_theme_constant_override("margin_top", amount)
	margin.add_theme_constant_override("margin_bottom", amount)
	return margin

func _panel_style(color: Color, border_width: int = 0, border_color: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.border_color = border_color
	return style

func _create_app_theme() -> Theme:
	var app_theme := Theme.new()
	app_theme.set_color("font_color", "Label", Color("#294038"))
	app_theme.set_color("font_color", "Button", Color("#ffffff"))
	app_theme.set_color("font_color", "OptionButton", Color("#ffffff"))
	app_theme.set_font_size("font_size", "Label", 15)
	app_theme.set_font_size("font_size", "Button", 15)
	app_theme.set_font_size("font_size", "OptionButton", 15)
	return app_theme
