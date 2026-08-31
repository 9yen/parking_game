class_name DemoGameConfig
extends RefCounted

const SAVE_VERSION := 2
const STARTING_COINS := 200
const GARAGE_CAPACITY := 10
const PARKING_CAP_SECONDS := 28800
const XP_PER_SECOND := 0.10
const OWNER_SHARE_RATE := 0.10
const SLOT_COUNT := 4
const LEVEL_XP: Array[int] = [0, 20, 75, 160, 300]

const CARS: Array[Dictionary] = [
	{"id":"sprout","name_key":"car.sprout","tier":1,"rate":1.0,"color":"#69d39b","price":0,"level":1,"starter":true},
	{"id":"pudding","name_key":"car.pudding","tier":1,"rate":1.25,"color":"#f5c665","price":0,"level":1,"starter":true},
	{"id":"courier","name_key":"car.courier","tier":1,"rate":1.7,"color":"#78b9e8","price":450,"level":2,"starter":false},
	{"id":"cloud","name_key":"car.cloud","tier":2,"rate":2.4,"color":"#b9a3eb","price":900,"level":3,"starter":false},
	{"id":"star","name_key":"car.star","tier":2,"rate":3.2,"color":"#ef8f91","price":1600,"level":4,"starter":false},
	{"id":"moon","name_key":"car.moon","tier":3,"rate":4.4,"color":"#5f72c9","price":2800,"level":5,"starter":false},
]

const LOTS: Array[Dictionary] = [
	{"id":"morning","name_key":"lot.morning","accent":"#70bde8","multiplier":1.0},
	{"id":"rooftop","name_key":"lot.rooftop","accent":"#bc94e0","multiplier":1.08},
	{"id":"rainbow","name_key":"lot.rainbow","accent":"#ee8d8d","multiplier":1.15},
	{"id":"night","name_key":"lot.night","accent":"#7182cf","multiplier":1.25},
]

const VISITORS: Array[Dictionary] = [
	{"name_key":"visitor.commuter","car_key":"visitor.car.mint","color":"#69c8a5","rate":1.2},
	{"name_key":"visitor.designer","car_key":"visitor.car.berry","color":"#d886a5","rate":1.5},
	{"name_key":"visitor.courier","car_key":"visitor.car.sky","color":"#70aee8","rate":1.8},
	{"name_key":"visitor.night","car_key":"visitor.car.plum","color":"#7b78bc","rate":2.1},
]

const MISSIONS: Array[Dictionary] = [
	{"id":"first_park","title_key":"mission.first_park","stat":"parked","target":1,"reward":50},
	{"id":"first_recall","title_key":"mission.first_recall","stat":"recalled","target":1,"reward":150},
	{"id":"two_out","title_key":"mission.two_out","stat":"max_out","target":2,"reward":200},
	{"id":"host_income","title_key":"mission.host_income","stat":"host_collections","target":1,"reward":200},
	{"id":"first_purchase","title_key":"mission.first_purchase","stat":"bought","target":1,"reward":350},
	{"id":"level_three","title_key":"mission.level_three","stat":"highest_level","target":3,"reward":500},
]

static func car(car_id: String) -> Dictionary:
	for item in CARS:
		if item.id == car_id: return item.duplicate(true)
	return {}

static func mission(mission_id: String) -> Dictionary:
	for item in MISSIONS:
		if item.id == mission_id: return item
	return {}

