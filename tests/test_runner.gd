extends SceneTree

const GameConfigScript = preload("res://scripts/data/game_config.gd")
const ParkingEconomyScript = preload("res://scripts/domain/parking_economy.gd")
const GameStateScript = preload("res://scripts/domain/game_state.gd")
const SaveServiceScript = preload("res://scripts/services/save_service.gd")

var failures: Array[String] = []
const TEST_SAVE_PATH := "user://parking_game_test_save.json"

func _init() -> void:
	_run_all()
	if failures.is_empty():
		print("PASS: 11 parking game checks")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _run_all() -> void:
	_test_new_game_defaults()
	_test_eight_hour_cap()
	_test_owner_share_is_additional()
	_test_duplicate_dispatch_is_rejected()
	_test_full_lot_is_rejected()
	_test_recall_settles_once()
	_test_auto_return_settles_once()
	_test_missing_save_fields_use_defaults()
	_test_same_second_repark_has_unique_id()
	_test_corrupt_save_is_safe()
	_test_save_round_trip()

func _test_new_game_defaults() -> void:
	var state := GameStateScript.new()
	_expect(state.cars.size() == 2, "New game should have two cars")
	_expect(state.coins == GameConfigScript.STARTING_COINS, "New game should have starting coins")
	_expect(state.npc_lots.size() == 4, "MVP should have four NPC lots")
	_expect(state.npc_lots[0]["slots"].size() == 4, "Each lot should have four spaces")
	_expect(state.own_lot_slots.size() == 4, "Player should own four parking spaces")

func _test_eight_hour_cap() -> void:
	var reward := ParkingEconomyScript.calculate_rewards(1.0, 100, 100 + GameConfigScript.PARKING_CAP_SECONDS + 500)
	_expect(reward["elapsed_seconds"] == GameConfigScript.PARKING_CAP_SECONDS, "Earnings must cap at eight hours")
	_expect(reward["visitor_coins"] == GameConfigScript.PARKING_CAP_SECONDS, "Capped reward should use only eight hours")

func _test_owner_share_is_additional() -> void:
	var reward := ParkingEconomyScript.calculate_rewards(1.0, 0, 100)
	_expect(reward["visitor_coins"] == 100, "Visitor should keep the full reward")
	_expect(reward["owner_coins"] == 10, "Owner should receive an additional ten percent")

func _test_duplicate_dispatch_is_rejected() -> void:
	var state := GameStateScript.new()
	var first := state.park_car("car_sprout", "npc_morning", 0, 100)
	var second := state.park_car("car_sprout", "npc_rooftop", 0, 101)
	_expect(first["ok"] and not second["ok"], "The same car cannot be parked twice")

func _test_full_lot_is_rejected() -> void:
	var state := GameStateScript.new()
	var lot := state.find_lot("npc_morning")
	lot["slots"] = [{}, {}, {}, {}]
	_expect(state.first_empty_slot("npc_morning") == -1, "A full lot should have no empty slot")
	var result := state.park_car("car_sprout", "npc_morning", -1, 100)
	_expect(not result["ok"], "Parking in a full lot must fail")

func _test_recall_settles_once() -> void:
	var state := GameStateScript.new()
	state.park_car("car_sprout", "npc_morning", 0, 100)
	var first := state.recall_car("car_sprout", 110)
	var coins_after_first := state.coins
	var second := state.recall_car("car_sprout", 120)
	_expect(first["ok"] and first["visitor_coins"] == 10, "Recall should settle elapsed earnings")
	_expect(not second["ok"] and state.coins == coins_after_first, "Repeated recall must not pay twice")

func _test_auto_return_settles_once() -> void:
	var state := GameStateScript.new()
	state.park_car("car_sprout", "npc_morning", 0, 100)
	var first := state.process_automatic_returns(100 + GameConfigScript.PARKING_CAP_SECONDS)
	var coins_after_first := state.coins
	var second := state.process_automatic_returns(200 + GameConfigScript.PARKING_CAP_SECONDS)
	_expect(first.size() == 1 and second.is_empty(), "Automatic return should happen only once")
	_expect(state.coins == coins_after_first, "Automatic return must not duplicate rewards")

func _test_missing_save_fields_use_defaults() -> void:
	var state := GameStateScript.new()
	state.load_from_dict({"coins": -50, "cars": ["invalid"], "npc_lots": [42]})
	_expect(state.coins == 0, "Invalid negative coins should be clamped")
	_expect(state.cars.size() == 2, "Missing car data should use starter cars")
	_expect(state.npc_lots.size() == 4, "Invalid lot data should use default lots")

func _test_same_second_repark_has_unique_id() -> void:
	var state := GameStateScript.new()
	var first := state.park_car("car_sprout", "npc_morning", 0, 100)
	state.recall_car("car_sprout", 100)
	var second := state.park_car("car_sprout", "npc_morning", 0, 100)
	_expect(first["parking_id"] != second["parking_id"], "Parking IDs must stay unique within the same second")

func _test_corrupt_save_is_safe() -> void:
	var state := SaveServiceScript.state_from_json("{not valid json")
	_expect(state.cars.size() == 2 and state.coins == GameConfigScript.STARTING_COINS, "Corrupt save should safely start a new game")

func _test_save_round_trip() -> void:
	var state := GameStateScript.new()
	state.coins = 4321
	state.park_car("car_sprout", "npc_night", 2, 12345)
	var saved := SaveServiceScript.save_game(state, TEST_SAVE_PATH)
	var restored := SaveServiceScript.load_game(TEST_SAVE_PATH)
	_expect(saved and restored.coins == 4321, "Save should restore player currency")
	_expect(restored.find_car("car_sprout")["state"] == GameStateScript.CAR_PARKED, "Save should restore parked car state")
	_expect(restored.find_lot("npc_night")["slots"][2] is Dictionary, "Save should restore occupied parking space")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
