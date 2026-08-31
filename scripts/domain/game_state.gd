class_name ParkingGameState
extends RefCounted

const GameConfigScript = preload("res://scripts/data/game_config.gd")
const ParkingEconomyScript = preload("res://scripts/domain/parking_economy.gd")

const CAR_GARAGED := "GARAGED"
const CAR_PARKED := "PARKED"

var save_version: int = GameConfigScript.SAVE_VERSION
var coins: int = GameConfigScript.STARTING_COINS
var player_xp: int = 0
var player_level: int = 1
var garage_capacity: int = GameConfigScript.STARTING_GARAGE_CAPACITY
var cars: Array[Dictionary] = []
var npc_lots: Array[Dictionary] = []
var own_lot_slots: Array = [null, null, null, null]
var settled_parking_ids: Array[String] = []
var next_parking_sequence: int = 1

func _init() -> void:
	_create_default_state()

func _create_default_state() -> void:
	cars.clear()
	for template in GameConfigScript.STARTER_CARS:
		var car: Dictionary = template.duplicate(true)
		car["state"] = CAR_GARAGED
		car["parking_id"] = ""
		cars.append(car)
	npc_lots.clear()
	for template in GameConfigScript.NPC_LOTS:
		var lot: Dictionary = template.duplicate(true)
		lot["slots"] = [null, null, null, null]
		npc_lots.append(lot)

func park_car(car_id: String, lot_id: String, slot_index: int, now: int) -> Dictionary:
	var car := find_car(car_id)
	var lot := find_lot(lot_id)
	if car.is_empty():
		return _failure("error.car_missing")
	if lot.is_empty():
		return _failure("error.lot_missing")
	if car.get("state", "") != CAR_GARAGED:
		return _failure("error.car_busy")
	var slots: Array = lot["slots"]
	if slot_index == -1:
		return _failure("error.slot_full")
	if slot_index < 0 or slot_index >= slots.size():
		return _failure("error.slot_missing")
	if slots[slot_index] != null:
		return _failure("error.slot_full")
	var parking_id := "%s:%s:%d:%d" % [car_id, lot_id, now, next_parking_sequence]
	next_parking_sequence += 1
	slots[slot_index] = {
		"parking_id": parking_id,
		"car_id": car_id,
		"started_at": now,
	}
	car["state"] = CAR_PARKED
	car["parking_id"] = parking_id
	return {"ok": true, "parking_id": parking_id}

func recall_car(car_id: String, now: int) -> Dictionary:
	var car := find_car(car_id)
	if car.is_empty() or car.get("state", "") != CAR_PARKED:
		return _failure("error.car_not_parked")
	var parked := _find_parking_for_car(car_id)
	if parked.is_empty():
		car["state"] = CAR_GARAGED
		car["parking_id"] = ""
		return _failure("error.parking_missing")
	return _settle_parking(parked["lot"], int(parked["slot_index"]), car, now)

func process_automatic_returns(now: int) -> Array[Dictionary]:
	var reports: Array[Dictionary] = []
	for car in cars:
		if car.get("state", "") != CAR_PARKED:
			continue
		var parked := _find_parking_for_car(str(car["id"]))
		if parked.is_empty():
			continue
		var slot: Dictionary = parked["lot"]["slots"][parked["slot_index"]]
		if now - int(slot["started_at"]) >= GameConfigScript.PARKING_CAP_SECONDS:
			reports.append(_settle_parking(parked["lot"], int(parked["slot_index"]), car, now))
	return reports

func preview_rewards(car_id: String, now: int) -> Dictionary:
	var car := find_car(car_id)
	var parked := _find_parking_for_car(car_id)
	if car.is_empty() or parked.is_empty():
		return {"elapsed_seconds": 0, "visitor_coins": 0, "player_xp": 0, "is_capped": false}
	var slot: Dictionary = parked["lot"]["slots"][parked["slot_index"]]
	return ParkingEconomyScript.calculate_rewards(float(car["rate_per_second"]), int(slot["started_at"]), now)

func find_car(car_id: String) -> Dictionary:
	for car in cars:
		if car.get("id", "") == car_id:
			return car
	return {}

func find_lot(lot_id: String) -> Dictionary:
	for lot in npc_lots:
		if lot.get("id", "") == lot_id:
			return lot
	return {}

func first_empty_slot(lot_id: String) -> int:
	var lot := find_lot(lot_id)
	if lot.is_empty():
		return -1
	var slots: Array = lot["slots"]
	for index in slots.size():
		if slots[index] == null:
			return index
	return -1

func to_dict() -> Dictionary:
	return {
		"save_version": save_version,
		"coins": coins,
		"player_xp": player_xp,
		"player_level": player_level,
		"garage_capacity": garage_capacity,
		"cars": cars.duplicate(true),
		"npc_lots": npc_lots.duplicate(true),
		"own_lot_slots": own_lot_slots.duplicate(true),
		"settled_parking_ids": settled_parking_ids.duplicate(),
		"next_parking_sequence": next_parking_sequence,
	}

func load_from_dict(data: Dictionary) -> void:
	_create_default_state()
	save_version = int(data.get("save_version", GameConfigScript.SAVE_VERSION))
	coins = maxi(0, int(data.get("coins", GameConfigScript.STARTING_COINS)))
	player_xp = maxi(0, int(data.get("player_xp", 0)))
	player_level = maxi(1, int(data.get("player_level", 1)))
	garage_capacity = maxi(2, int(data.get("garage_capacity", GameConfigScript.STARTING_GARAGE_CAPACITY)))
	if _is_valid_car_array(data.get("cars")):
		cars.assign(data["cars"])
	if _is_valid_lot_array(data.get("npc_lots")):
		npc_lots.assign(data["npc_lots"])
	if data.get("own_lot_slots") is Array and data["own_lot_slots"].size() == GameConfigScript.SLOT_COUNT:
		own_lot_slots.assign(data["own_lot_slots"])
	next_parking_sequence = maxi(1, int(data.get("next_parking_sequence", 1)))
	settled_parking_ids.clear()
	if data.get("settled_parking_ids") is Array:
		for value in data["settled_parking_ids"]:
			settled_parking_ids.append(str(value))

func _find_parking_for_car(car_id: String) -> Dictionary:
	for lot in npc_lots:
		var slots: Array = lot["slots"]
		for index in slots.size():
			var slot = slots[index]
			if slot is Dictionary and slot.get("car_id", "") == car_id:
				return {"lot": lot, "slot_index": index}
	return {}

func _settle_parking(lot: Dictionary, slot_index: int, car: Dictionary, now: int) -> Dictionary:
	var slot: Dictionary = lot["slots"][slot_index]
	var parking_id := str(slot["parking_id"])
	if settled_parking_ids.has(parking_id):
		return _failure("error.already_settled")
	var rewards := ParkingEconomyScript.calculate_rewards(float(car["rate_per_second"]), int(slot["started_at"]), now)
	coins += int(rewards["visitor_coins"])
	player_xp += int(rewards["player_xp"])
	settled_parking_ids.append(parking_id)
	lot["slots"][slot_index] = null
	car["state"] = CAR_GARAGED
	car["parking_id"] = ""
	rewards["ok"] = true
	rewards["parking_id"] = parking_id
	return rewards

func _failure(error_key: String) -> Dictionary:
	return {"ok": false, "error_key": error_key}

func _is_dictionary_array(value) -> bool:
	if not value is Array:
		return false
	for item in value:
		if not item is Dictionary:
			return false
	return true

func _is_valid_lot_array(value) -> bool:
	if not _is_dictionary_array(value) or value.is_empty():
		return false
	for lot in value:
		if not lot.has("id") or not lot.has("name_key"):
			return false
		if not lot.get("slots") is Array or lot["slots"].size() != GameConfigScript.SLOT_COUNT:
			return false
	return true

func _is_valid_car_array(value) -> bool:
	if not _is_dictionary_array(value) or value.is_empty():
		return false
	for car in value:
		if not car.has_all(["id", "name_key", "tier", "rate_per_second", "color", "state", "parking_id"]):
			return false
		if car["state"] != CAR_GARAGED and car["state"] != CAR_PARKED:
			return false
	return true
