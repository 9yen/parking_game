extends Control

const State = preload("res://scripts/domain/demo_game_state.gd")
const Config = preload("res://scripts/data/demo_game_config.gd")
const Save = preload("res://scripts/services/save_service.gd")
const Words = preload("res://scripts/services/demo_localization.gd")
const BACKGROUND = preload("res://assets/art/environments/office_parking_courtyard.png")

var state: DemoGameState
var words: DemoLocalization
var tab := "park"
var lot_id := "morning"
var notice_key := "notice.ready"
var notice_values: Array = []
var elapsed := 0.0

func _ready() -> void:
	state=Save.load_game(); words=Words.new(); words.locale=state.locale
	get_window().content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	if OS.get_cmdline_user_args().has("--compact-preview"): state.compact=true
	_apply_window(); theme=_theme(); state.initialize(Time.get_unix_time_from_system()); _build()
	get_tree().set_auto_accept_quit(false)

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST and state:
		Save.save_game(state); get_tree().quit()

func _process(delta: float) -> void:
	elapsed+=delta
	if elapsed<1.0:return
	elapsed=0.0
	var result:=state.tick(Time.get_unix_time_from_system())
	if result.returns>0: notice_key="notice.return";notice_values=[]
	if state.is_complete() and not state.demo_seen:
		state.demo_seen=true; Save.save_game(state); call_deferred("_show_completion")
	_build()

func _build() -> void:
	for child in get_children(): remove_child(child);child.queue_free()
	var bg:=ColorRect.new();bg.color=Color("#edf4ef");bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(bg)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var pad:=12 if state.compact else 22
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,pad)
	add_child(margin)
	var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;margin.add_child(scroll)
	var page:=VBoxContainer.new();page.size_flags_horizontal=Control.SIZE_EXPAND_FILL;page.add_theme_constant_override("separation",10);scroll.add_child(page)
	page.add_child(_header());page.add_child(_tutorial());page.add_child(_tabs())
	if tab=="park":page.add_child(_park_page())
	elif tab=="home":page.add_child(_home_page())
	elif tab=="shop":page.add_child(_shop_page())
	else:page.add_child(_goals_page())
	var note:=Label.new();note.text=words.text(notice_key,notice_values);note.add_theme_color_override("font_color",Color("#486057"));page.add_child(note)

func _header() -> Control:
	var root:BoxContainer=VBoxContainer.new() if state.compact else HBoxContainer.new()
	var title_row:=HBoxContainer.new();title_row.size_flags_horizontal=Control.SIZE_EXPAND_FILL;var title:=Label.new();title.text=words.text("app.title");title.add_theme_font_size_override("font_size",20 if state.compact else 24);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title_row.add_child(title)
	var language:=Button.new();language.text=words.text("action.language");language.pressed.connect(_toggle_language);title_row.add_child(language);root.add_child(title_row)
	var row:=HBoxContainer.new();row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var next_xp:=Config.LEVEL_XP[state.level] if state.level<5 else Config.LEVEL_XP[-1]
	var stats:=Label.new();stats.text=words.text("stats",[state.coins,state.level,state.xp,next_xp]);stats.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(stats)
	var window_button:=Button.new();window_button.text=words.text("action.normal" if state.compact else "action.compact");window_button.pressed.connect(_toggle_window);row.add_child(window_button)
	var sound_button:=Button.new();sound_button.text="🔊" if state.sound else "🔇";sound_button.pressed.connect(_toggle_sound);row.add_child(sound_button)
	var reset_button:=Button.new();reset_button.text="↺";reset_button.tooltip_text=words.text("action.reset");reset_button.pressed.connect(_confirm_reset);row.add_child(reset_button)
	root.add_child(row);return root

func _tutorial() -> Control:
	var panel:=PanelContainer.new();panel.add_theme_stylebox_override("panel",_style(Color("#fff3cd")))
	var row:=HBoxContainer.new();var label:=Label.new();label.text=words.text("tutorial.%d"%state.tutorial_step);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(label)
	if not state.tutorial_hidden:var skip:=Button.new();skip.text=words.text("action.skip");skip.pressed.connect(_skip_tutorial);row.add_child(skip)
	panel.add_child(row);return panel

func _tabs() -> Control:
	var row:Container
	if state.compact:var grid:=GridContainer.new();grid.columns=2;row=grid
	else:row=HBoxContainer.new()
	for id in ["park","home","shop","goals"]:
		var button:=Button.new();button.text=words.text("tab."+id);button.toggle_mode=true;button.button_pressed=tab==id;button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.pressed.connect(_set_tab.bind(id));row.add_child(button)
	return row

func _park_page() -> Control:
	var box:=VBoxContainer.new();box.custom_minimum_size.y=430;box.add_theme_constant_override("separation",10);var top:=HBoxContainer.new();var picker:=OptionButton.new();picker.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for i in state.lots.size():picker.add_item(words.text(state.lots[i].name_key));picker.set_item_metadata(i,state.lots[i].id);picker.select(i if state.lots[i].id==lot_id else picker.selected)
	picker.item_selected.connect(_pick_lot.bind(picker));top.add_child(picker)
	var lot:=state.find_lot(lot_id);var bonus:=Label.new();bonus.text=words.text("lot.bonus",[lot.multiplier]);top.add_child(bonus);box.add_child(top)
	var slots:=GridContainer.new();slots.columns=4 if not state.compact else 2
	for i in 4:
		var card:=PanelContainer.new();card.custom_minimum_size=Vector2(120,95);card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.add_theme_stylebox_override("panel",_style(Color("#e2ebe6"),2));var label:=Label.new();label.text="P%d\n%s"%[i+1,words.text("slot.empty") if lot.slots[i]==null else words.text(state.find_car(lot.slots[i].car).name_key)];label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;card.add_child(label);slots.add_child(card)
	box.add_child(slots);var heading:=Label.new();heading.text=words.text("section.cars");heading.add_theme_font_size_override("font_size",18);box.add_child(heading)
	for car in state.cars:box.add_child(_car_row(car))
	return _panel(box)

func _car_row(car: Dictionary) -> Control:
	var row:BoxContainer=VBoxContainer.new() if state.compact else HBoxContainer.new();row.custom_minimum_size.y=58;row.add_theme_constant_override("separation",8)
	var details:=HBoxContainer.new();var color:=ColorRect.new();color.color=Color(car.color);color.custom_minimum_size=Vector2(52,46);details.add_child(color)
	var text:=Label.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	if car.state==State.GARAGED:text.text="%s\n%s"%[words.text(car.name_key),words.text("car.status.home",[car.rate])]
	else:
		var p:=state.preview(car.instance_id,Time.get_unix_time_from_system());text.text="%s\n%s"%[words.text(car.name_key),words.text("car.status.out",[_duration(p.elapsed_seconds),p.visitor_coins])]
	details.add_child(text);row.add_child(details);var action:=Button.new()
	if car.state==State.GARAGED:action.text=words.text("action.park");action.pressed.connect(_park.bind(car.instance_id))
	else:var p:=state.preview(car.instance_id,Time.get_unix_time_from_system());action.text=words.text("action.recall",[p.visitor_coins]);action.pressed.connect(_recall.bind(car.instance_id))
	row.add_child(action);return row

func _home_page() -> Control:
	var box:=VBoxContainer.new();var phase_index:=int(Time.get_unix_time_from_system()/180)%4;var phase_keys:=["phase.day","phase.sunset","phase.night","phase.rain"];var phase_tints:=[Color.WHITE,Color("#ffd2a3"),Color("#7d91bd"),Color("#a5bec4")]
	var phase:=Label.new();phase.text=words.text("section.home")+" · "+words.text(phase_keys[phase_index]);phase.add_theme_font_size_override("font_size",18);box.add_child(phase)
	var image:=TextureRect.new();image.texture=BACKGROUND;image.modulate=phase_tints[phase_index];image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;image.custom_minimum_size=Vector2(300,190 if state.compact else 260);box.add_child(image)
	var title:=HBoxContainer.new();var label:=Label.new();label.text=words.text("host.pending",[state.host_income]);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title.add_child(label);var collect:=Button.new();collect.text=words.text("action.collect",[state.host_income]);collect.disabled=state.host_income<=0;collect.pressed.connect(_collect_host);title.add_child(collect);box.add_child(title)
	var grid:=GridContainer.new();grid.columns=2 if state.compact else 4
	for i in 4:grid.add_child(_visitor_card(i))
	box.add_child(grid);return _panel(box)

func _visitor_card(index:int)->Control:
	var card:=VBoxContainer.new();card.custom_minimum_size=Vector2(130,70);var visitor=state.home_slots[index];var label:=Label.new();label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	if visitor==null:label.text="P%d\n%s"%[index+1,words.text("slot.waiting")]
	else:label.text=words.text("visitor.detail",[words.text(visitor.name_key),words.text(visitor.car_key),_duration(maxi(0,visitor.ends-Time.get_unix_time_from_system()))])
	card.add_child(label)
	if visitor is Dictionary:var b:=Button.new();b.text=words.text("action.sticker");b.disabled=visitor.stickered;b.pressed.connect(_sticker.bind(index));card.add_child(b)
	return _panel(card)

func _shop_page()->Control:
	var box:=VBoxContainer.new();var owned:=Label.new();owned.text=words.text("section.collection",[state.cars.size()]);owned.add_theme_font_size_override("font_size",18);box.add_child(owned)
	for template in Config.CARS:
		if template.starter:continue
		var row:=HBoxContainer.new();var swatch:=ColorRect.new();swatch.color=Color(template.color);swatch.custom_minimum_size=Vector2(42,42);row.add_child(swatch);var label:=Label.new();label.text="%s · T%d · %.2f/s"%[words.text(template.name_key),template.tier,template.rate];label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(label);var buy:=Button.new();buy.text=words.text("action.buy",[template.price]) if state.level>=template.level else words.text("action.locked",[template.level]);buy.disabled=state.level<template.level or state.coins<template.price;buy.pressed.connect(_buy.bind(template.id));row.add_child(buy);box.add_child(row)
	return _panel(box)

func _goals_page()->Control:
	var box:=VBoxContainer.new()
	for mission in Config.MISSIONS:
		var row:=HBoxContainer.new();var label:=Label.new();label.text="%s  %s"%[words.text(mission.title_key),words.text("mission.progress",[state.progress(mission.id),mission.target])];label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(label);var b:=Button.new();b.text=words.text("action.claimed") if state.claimed.has(mission.id) else words.text("action.claim",[mission.reward]);b.disabled=state.claimed.has(mission.id) or state.progress(mission.id)<mission.target;b.pressed.connect(_claim.bind(mission.id));row.add_child(b);box.add_child(row)
	return _panel(box)

func _park(id:String)->void:_result(state.park(id,lot_id,Time.get_unix_time_from_system()),"notice.park");_save_build()
func _recall(id:String)->void:var r:=state.recall(id,Time.get_unix_time_from_system());_result(r,"notice.recall",[r.get("visitor_coins",0),r.get("player_xp",0)]);_save_build()
func _buy(id:String)->void:_result(state.buy(id),"notice.buy");_save_build()
func _claim(id:String)->void:var r:=state.claim_mission(id);_result(r,"notice.claim",[r.get("coins",0)]);_save_build()
func _collect_host()->void:var r:=state.collect_host_income();_result(r,"notice.host",[r.get("coins",0)]);_save_build()
func _sticker(i:int)->void:_result(state.sticker(i),"notice.sticker");_save_build()
func _result(r:Dictionary,success:String,values:Array=[])->void:notice_key=success if r.get("ok",false) else r.get("error_key","error.generic");notice_values=values if r.get("ok",false) else [];_tone(r.get("ok",false))
func _save_build()->void:Save.save_game(state);_build()
func _set_tab(id:String)->void:tab=id;_build()
func _pick_lot(i:int,p:OptionButton)->void:lot_id=p.get_item_metadata(i);_build()
func _toggle_language()->void:state.locale="en" if state.locale=="zh_CN" else "zh_CN";words.locale=state.locale;_save_build()
func _toggle_window()->void:state.compact=not state.compact;_apply_window();_save_build()
func _toggle_sound()->void:state.sound=not state.sound;_save_build()
func _skip_tutorial()->void:state.tutorial_hidden=true;state.tutorial_step=5;_save_build()
func _confirm_reset()->void:
	var dialog:=ConfirmationDialog.new();dialog.title=words.text("reset.title");dialog.dialog_text=words.text("reset.body");dialog.ok_button_text=words.text("reset.confirm");dialog.confirmed.connect(_reset_save);add_child(dialog);dialog.popup_centered(Vector2i(520,220))
func _reset_save()->void:state=State.new();state.locale=words.locale;state.initialize(Time.get_unix_time_from_system());notice_key="notice.ready";notice_values=[];Save.save_game(state);_apply_window();_build()
func _apply_window()->void:DisplayServer.window_set_size(Vector2i(480,720) if state.compact else Vector2i(1120,720))
func _duration(s:int)->String:return "%02d:%02d:%02d"%[s/3600,(s%3600)/60,s%60]
func _panel(child:Control)->PanelContainer:var p:=PanelContainer.new();p.add_theme_stylebox_override("panel",_style(Color("#ffffff")));p.add_child(child);return p
func _style(color:Color,border:=0)->StyleBoxFlat:var s:=StyleBoxFlat.new();s.bg_color=color;s.corner_radius_top_left=12;s.corner_radius_top_right=12;s.corner_radius_bottom_left=12;s.corner_radius_bottom_right=12;s.content_margin_left=12;s.content_margin_right=12;s.content_margin_top=10;s.content_margin_bottom=10;s.border_width_left=border;s.border_width_right=border;s.border_width_top=border;s.border_width_bottom=border;s.border_color=Color("#b8c9c0");return s
func _theme()->Theme:
	var t:=Theme.new();t.set_color("font_color","Label",Color("#294038"));t.set_font_size("font_size","Label",15);t.set_font_size("font_size","Button",15)
	var normal:=_style(Color("#3f6f5c"));var hover:=_style(Color("#4f826d"));var pressed:=_style(Color("#e7a95c"));var disabled:=_style(Color("#9aaba3"))
	for type in ["Button","OptionButton"]:
		t.set_stylebox("normal",type,normal);t.set_stylebox("hover",type,hover);t.set_stylebox("pressed",type,pressed);t.set_stylebox("disabled",type,disabled);t.set_color("font_color",type,Color.WHITE);t.set_color("font_pressed_color",type,Color("#253a32"))
	return t
func _show_completion()->void:var d:=AcceptDialog.new();d.title=words.text("demo.title");d.dialog_text=words.text("demo.body");d.ok_button_text=words.text("demo.continue");add_child(d);d.popup_centered(Vector2i(620,300))
func _tone(success:bool)->void:
	if not state.sound:return
	var stream:=AudioStreamWAV.new();stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=22050;stream.stereo=false
	var frames:=1543;var data:=PackedByteArray();data.resize(frames*2);var frequency:=660.0 if success else 220.0
	for i in frames:data.encode_s16(i*2,int(sin(float(i)*TAU*frequency/22050.0)*3200.0*(1.0-float(i)/frames)))
	stream.data=data;var player:=AudioStreamPlayer.new();player.stream=stream;add_child(player);player.finished.connect(player.queue_free);player.play()
