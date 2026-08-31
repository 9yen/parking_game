class_name DemoGameState
extends RefCounted

const Config = preload("res://scripts/data/demo_game_config.gd")
const Economy = preload("res://scripts/domain/parking_economy.gd")
const GARAGED := "GARAGED"
const PARKED := "PARKED"

var coins := Config.STARTING_COINS
var xp := 0
var level := 1
var cars: Array[Dictionary] = []
var lots: Array[Dictionary] = []
var home_slots: Array = [null,null,null,null]
var host_income := 0
var next_visitor_at := 0
var sequence := 1
var claimed: Array[String] = []
var settled: Array[String] = []
var stats := {"parked":0,"recalled":0,"max_out":0,"host_collections":0,"bought":0,"stickers":0,"highest_level":1,"earned":0}
var locale := "zh_CN"
var compact := false
var reduce_motion := false
var sound := true
var tutorial_step := 0
var tutorial_hidden := false
var demo_seen := false

func _init() -> void:
	for template in Config.CARS:
		if template.starter: cars.append(_new_car(template))
	for template in Config.LOTS:
		var lot := template.duplicate(true)
		lot.slots = [null,null,null,null]
		lots.append(lot)

func initialize(now: int) -> void:
	if next_visitor_at == 0: next_visitor_at = now + 8

func park(instance_id: String, lot_id: String, now: int) -> Dictionary:
	var car := find_car(instance_id)
	var lot := find_lot(lot_id)
	if car.is_empty() or lot.is_empty(): return fail("error.generic")
	if car.state != GARAGED: return fail("error.car_busy")
	var slot: int = lot.slots.find(null)
	if slot < 0: return fail("error.slot_full")
	var event_id := "%s:%d:%d" % [instance_id, now, sequence]
	sequence += 1
	lot.slots[slot] = {"id":event_id,"car":instance_id,"start":now}
	car.state = PARKED
	car.parking_id = event_id
	stats.parked += 1
	stats.max_out = maxi(stats.max_out, parked_count())
	if tutorial_step == 0: tutorial_step = 1
	return {"ok":true}

func recall(instance_id: String, now: int) -> Dictionary:
	var car := find_car(instance_id)
	if car.is_empty() or car.state != PARKED: return fail("error.car_not_parked")
	for lot in lots:
		for index in lot.slots.size():
			var slot = lot.slots[index]
			if slot is Dictionary and slot.car == instance_id:
				var result := _settle(car, lot, index, now)
				stats.recalled += 1
				if tutorial_step == 1: tutorial_step = 2
				return result
	return fail("error.generic")

func tick(now: int) -> Dictionary:
	initialize(now)
	var returns := 0
	for car in cars:
		if car.state == PARKED:
			var preview := preview(car.instance_id, now)
			if preview.is_capped:
				recall(car.instance_id, now)
				returns += 1
	var visitors_done := 0
	for index in home_slots.size():
		var visitor = home_slots[index]
		if visitor is Dictionary and now >= visitor.ends:
			var gross := int(float(visitor.rate) * float(visitor.ends - visitor.start))
			host_income += int(float(gross) * Config.OWNER_SHARE_RATE)
			home_slots[index] = null
			visitors_done += 1
	while now >= next_visitor_at:
		var empty: int = home_slots.find(null)
		if empty < 0:
			next_visitor_at = now + 35
			break
		var visitor: Dictionary = Config.VISITORS[(sequence - 1) % Config.VISITORS.size()]
		home_slots[empty] = {"name_key":visitor.name_key,"car_key":visitor.car_key,"color":visitor.color,"rate":visitor.rate,"start":next_visitor_at,"ends":next_visitor_at+70,"stickered":false}
		sequence += 1
		next_visitor_at += 35
	return {"returns":returns,"visitors":visitors_done}

func preview(instance_id: String, now: int) -> Dictionary:
	var car := find_car(instance_id)
	for lot in lots:
		for slot in lot.slots:
			if slot is Dictionary and slot.car == instance_id:
				return Economy.calculate_rewards(float(car.rate) * float(lot.multiplier), slot.start, now)
	return {"elapsed_seconds":0,"visitor_coins":0,"player_xp":0,"is_capped":false}

func buy(car_id: String) -> Dictionary:
	var template := Config.car(car_id)
	if template.is_empty(): return fail("error.generic")
	if level < template.level: return fail("error.level_locked")
	if cars.size() >= Config.GARAGE_CAPACITY: return fail("error.garage_full")
	if coins < template.price: return fail("error.not_enough_coins")
	coins -= template.price
	var car := _new_car(template)
	car.instance_id = "%s_%d" % [car_id, sequence]
	sequence += 1
	cars.append(car)
	stats.bought += 1
	if tutorial_step < 5: tutorial_step = 5
	return {"ok":true}

func collect_host_income() -> Dictionary:
	if host_income <= 0: return fail("error.no_owner_income")
	var amount := host_income
	host_income = 0
	coins += amount
	stats.host_collections += 1
	stats.earned += amount
	if tutorial_step < 4: tutorial_step = 4
	return {"ok":true,"coins":amount}

func sticker(index: int) -> Dictionary:
	if index < 0 or index >= 4 or not home_slots[index] is Dictionary: return fail("error.generic")
	if home_slots[index].stickered: return fail("error.already_stickered")
	home_slots[index].stickered = true
	coins += 5
	stats.stickers += 1
	return {"ok":true,"coins":5}

func claim_mission(id: String) -> Dictionary:
	var mission := Config.mission(id)
	if mission.is_empty() or claimed.has(id): return fail("error.already_claimed")
	if progress(id) < mission.target: return fail("error.mission_incomplete")
	claimed.append(id)
	coins += mission.reward
	stats.earned += mission.reward
	return {"ok":true,"coins":mission.reward}

func progress(id: String) -> int:
	var mission := Config.mission(id)
	return 0 if mission.is_empty() else mini(stats.get(mission.stat,0), mission.target)

func is_complete() -> bool:
	return stats.parked >= 1 and stats.recalled >= 1 and stats.max_out >= 2 and stats.host_collections >= 1 and stats.bought >= 1 and level >= 3

func parked_count() -> int:
	var result := 0
	for car in cars:
		if car.state == PARKED: result += 1
	return result

func find_car(id: String) -> Dictionary:
	for car in cars:
		if car.instance_id == id: return car
	return {}

func find_lot(id: String) -> Dictionary:
	for lot in lots:
		if lot.id == id: return lot
	return {}

func to_dict() -> Dictionary:
	return {"save_version":Config.SAVE_VERSION,"coins":coins,"xp":xp,"level":level,"cars":cars,"lots":lots,"home_slots":home_slots,"host_income":host_income,"next_visitor_at":next_visitor_at,"sequence":sequence,"claimed":claimed,"settled":settled,"stats":stats,"locale":locale,"compact":compact,"reduce_motion":reduce_motion,"sound":sound,"tutorial_step":tutorial_step,"tutorial_hidden":tutorial_hidden,"demo_seen":demo_seen}

func load_dict(data: Dictionary) -> void:
	coins = maxi(0, data.get("coins",coins))
	xp = maxi(0, data.get("xp",data.get("player_xp",0)))
	level = clampi(data.get("level",data.get("player_level",1)),1,5)
	if _valid_dict_array(data.get("cars")): cars.assign(data.cars)
	if _valid_dict_array(data.get("lots")): lots.assign(data.lots)
	if data.get("home_slots") is Array and data.home_slots.size()==4: home_slots.assign(data.home_slots)
	host_income = maxi(0,data.get("host_income",0)); next_visitor_at=maxi(0,data.get("next_visitor_at",0)); sequence=maxi(1,data.get("sequence",1))
	_copy_strings(data.get("claimed"),claimed); _copy_strings(data.get("settled"),settled)
	if data.get("stats") is Dictionary:
		for key in stats: stats[key]=maxi(0,data.stats.get(key,stats[key]))
	locale = data.get("locale","zh_CN") if data.get("locale","zh_CN") in ["zh_CN","en"] else "zh_CN"
	compact=data.get("compact",false); reduce_motion=data.get("reduce_motion",false); sound=data.get("sound",true)
	tutorial_step=clampi(data.get("tutorial_step",0),0,5); tutorial_hidden=data.get("tutorial_hidden",false); demo_seen=data.get("demo_seen",false)
	_migrate_cars(); _refresh_level()

func _settle(car: Dictionary, lot: Dictionary, index: int, now: int) -> Dictionary:
	var slot: Dictionary = lot.slots[index]
	if settled.has(slot.id): return fail("error.already_settled")
	var reward := Economy.calculate_rewards(float(car.rate)*float(lot.multiplier),slot.start,now)
	coins += reward.visitor_coins; xp += reward.player_xp; stats.earned += reward.visitor_coins
	settled.append(slot.id); lot.slots[index]=null; car.state=GARAGED; car.parking_id=""; _refresh_level()
	reward.ok=true
	return reward

func _refresh_level() -> void:
	level=1
	for index in Config.LEVEL_XP.size():
		if xp >= Config.LEVEL_XP[index]: level=index+1
	stats.highest_level=maxi(stats.highest_level,level)

func _new_car(template: Dictionary) -> Dictionary:
	var car:=template.duplicate(true); car.state=GARAGED; car.parking_id=""; car.instance_id=template.id
	return car

func _migrate_cars() -> void:
	for index in cars.size():
		var car=cars[index]; var template=Config.car(car.get("id",str(car.get("instance_id","sprout")).split("_")[0]))
		for key in template:
			if not car.has(key): car[key]=template[key]
		if not car.has("instance_id"): car.instance_id=car.get("id","car") if index<2 else "%s_%d"%[car.get("id","car"),index]

func _valid_dict_array(value) -> bool:
	if not value is Array or value.is_empty(): return false
	for item in value:
		if not item is Dictionary: return false
	return true

func _copy_strings(source, target: Array[String]) -> void:
	target.clear()
	if source is Array:
		for item in source: target.append(str(item))

func fail(key: String) -> Dictionary:
	return {"ok":false,"error_key":key}
