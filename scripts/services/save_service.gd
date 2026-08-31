class_name ParkingSaveService
extends RefCounted

const GameStateScript = preload("res://scripts/domain/demo_game_state.gd")
const SAVE_PATH := "user://parking_save_v2.json"

static func save_game(state: DemoGameState, save_path: String = SAVE_PATH) -> bool:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(state.to_dict()))
	file.close()
	return true

static func load_game(save_path: String = SAVE_PATH) -> DemoGameState:
	if not FileAccess.file_exists(save_path):
		return GameStateScript.new()
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return GameStateScript.new()
	var json_text := file.get_as_text()
	file.close()
	return state_from_json(json_text)

static func state_from_json(json_text: String) -> DemoGameState:
	var state := GameStateScript.new()
	var parser := JSON.new()
	if parser.parse(json_text) != OK:
		return state
	var parsed = parser.data
	if parsed is Dictionary:
		state.load_dict(parsed)
	return state
