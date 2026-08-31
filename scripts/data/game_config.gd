class_name GameConfig
extends RefCounted

const SAVE_VERSION: int = 1
const STARTING_COINS: int = 200
const STARTING_GARAGE_CAPACITY: int = 10
const PARKING_CAP_SECONDS: int = 8 * 60 * 60
const PLAYER_XP_PER_SECOND: float = 0.05
const OWNER_SHARE_RATE: float = 0.10
const SLOT_COUNT: int = 4

const STARTER_CARS: Array[Dictionary] = [
	{
		"id": "car_sprout",
		"name_key": "car.sprout",
		"tier": 1,
		"rate_per_second": 1.0,
		"color": "#72d6a0",
	},
	{
		"id": "car_pudding",
		"name_key": "car.pudding",
		"tier": 1,
		"rate_per_second": 1.25,
		"color": "#f7c96f",
	},
]

const NPC_LOTS: Array[Dictionary] = [
	{"id": "npc_morning", "name_key": "lot.morning", "accent": "#7cc7ff"},
	{"id": "npc_rooftop", "name_key": "lot.rooftop", "accent": "#d5a6ff"},
	{"id": "npc_rainbow", "name_key": "lot.rainbow", "accent": "#ff9f9f"},
	{"id": "npc_night", "name_key": "lot.night", "accent": "#7f91dc"},
]

