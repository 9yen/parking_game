class_name ParkingLocalization
extends RefCounted

var locale := "zh_CN"

const TEXT := {
	"zh_CN": {
		"app.title": "一起停车吧",
		"app.subtitle": "适合放在桌面角落的轻松停车时光",
		"stats.coins": "金币  %d",
		"stats.level": "等级 %d  ·  经验 %d",
		"section.garage": "我的车库",
		"section.own_lot": "我的 4 个车位",
		"section.lot": "访问停车场",
		"garage.capacity": "车辆 %d / %d",
		"car.sprout": "嫩芽小车",
		"car.pudding": "布丁小车",
		"car.garaged": "在车库 · 每秒 %.2f 金币",
		"car.parked": "停车中 %s · 预计 %d 金币",
		"action.park": "停到这里",
		"action.recall": "召回并结算",
		"action.compact": "紧凑窗口",
		"action.normal": "普通窗口",
		"action.language": "EN",
		"lot.morning": "晨光写字楼",
		"lot.rooftop": "天台创意园",
		"lot.rainbow": "彩虹便利店",
		"lot.night": "夜航工作室",
		"slot.empty": "空车位",
		"slot.friend_ready": "等待好友停车",
		"slot.occupied": "%s\n已停 %s",
		"hint.ready": "选择一个停车场，再把空闲车辆停进去。",
		"notice.parked": "%s 已经停好，开始赚钱啦。",
		"notice.recalled": "车辆回家，获得 %d 金币和 %d 经验。",
		"notice.auto_return": "有车辆达到 8 小时上限并自动回家。",
		"notice.saved": "进度已保存。",
		"error.car_busy": "这辆车已经在外面赚钱。",
		"error.slot_full": "这个停车场已经满了，换一家看看吧。",
		"error.slot_missing": "没有找到这个车位。",
		"error.car_not_parked": "这辆车现在不在停车场。",
		"error.generic": "暂时无法完成这个操作。",
	},
	"en": {
		"app.title": "Park Together",
		"app.subtitle": "A cozy parking break for the corner of your desktop",
		"stats.coins": "Coins  %d",
		"stats.level": "Level %d  ·  XP %d",
		"section.garage": "My Garage",
		"section.own_lot": "My 4 Parking Spaces",
		"section.lot": "Visit a Parking Lot",
		"garage.capacity": "Cars %d / %d",
		"car.sprout": "Sprout Compact",
		"car.pudding": "Pudding Compact",
		"car.garaged": "In garage · %.2f coins/sec",
		"car.parked": "Parked %s · %d coins ready",
		"action.park": "Park here",
		"action.recall": "Recall & collect",
		"action.compact": "Compact window",
		"action.normal": "Normal window",
		"action.language": "中文",
		"lot.morning": "Morning Office",
		"lot.rooftop": "Rooftop Studio",
		"lot.rainbow": "Rainbow Mart",
		"lot.night": "Night Shift Studio",
		"slot.empty": "Empty space",
		"slot.friend_ready": "Ready for a friend",
		"slot.occupied": "%s\nParked %s",
		"hint.ready": "Choose a parking lot, then send out an idle car.",
		"notice.parked": "%s is parked and earning coins.",
		"notice.recalled": "Welcome home! Earned %d coins and %d XP.",
		"notice.auto_return": "A car reached the 8-hour cap and returned home.",
		"notice.saved": "Progress saved.",
		"error.car_busy": "That car is already out earning.",
		"error.slot_full": "This lot is full. Try another one.",
		"error.slot_missing": "That parking space was not found.",
		"error.car_not_parked": "That car is not currently parked.",
		"error.generic": "That action is not available right now.",
	},
}

func text(key: String, values: Array = []) -> String:
	var table: Dictionary = TEXT.get(locale, TEXT["en"])
	var result := str(table.get(key, key))
	return result % values if not values.is_empty() else result

func toggle_locale() -> void:
	locale = "en" if locale == "zh_CN" else "zh_CN"
