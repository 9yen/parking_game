class_name ParkingEconomy
extends RefCounted

const GameConfigScript = preload("res://scripts/data/demo_game_config.gd")

static func capped_elapsed_seconds(started_at: int, now: int) -> int:
	return clampi(now - started_at, 0, GameConfigScript.PARKING_CAP_SECONDS)

static func calculate_rewards(rate_per_second: float, started_at: int, now: int) -> Dictionary:
	var elapsed := capped_elapsed_seconds(started_at, now)
	var visitor_coins := int(floorf(rate_per_second * float(elapsed)))
	return {
		"elapsed_seconds": elapsed,
		"visitor_coins": visitor_coins,
		"owner_coins": int(floorf(float(visitor_coins) * GameConfigScript.OWNER_SHARE_RATE)),
		"player_xp": int(floorf(float(elapsed) * GameConfigScript.XP_PER_SECOND)),
		"is_capped": elapsed >= GameConfigScript.PARKING_CAP_SECONDS,
	}
