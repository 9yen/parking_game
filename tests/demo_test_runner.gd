extends SceneTree

const Config=preload("res://scripts/data/demo_game_config.gd")
const State=preload("res://scripts/domain/demo_game_state.gd")
const Economy=preload("res://scripts/domain/parking_economy.gd")
const Save=preload("res://scripts/services/save_service.gd")
const TEST_PATH="user://parking_demo_test.json"
var failures:Array[String]=[]

func _init()->void:
	_defaults();_cap();_park_recall();_duplicate();_full_lot();_shop();_missions();_visitors();_sticker();_auto_return();_save();_corrupt();_completion()
	if failures.is_empty():print("PASS: 13 Steam Demo checks");quit(0)
	else:
		for failure in failures:push_error(failure)
		quit(1)

func _defaults()->void:
	var s:=State.new();expect(s.cars.size()==2,"two starter cars");expect(s.lots.size()==4,"four NPC lots");expect(s.home_slots.size()==4,"four home spaces")
func _cap()->void:
	var r:=Economy.calculate_rewards(1.0,0,Config.PARKING_CAP_SECONDS+999);expect(r.elapsed_seconds==Config.PARKING_CAP_SECONDS,"eight-hour cap")
func _park_recall()->void:
	var s:=State.new();expect(s.park("sprout","morning",100).ok,"park succeeds");var r:=s.recall("sprout",110);expect(r.ok and r.visitor_coins==10,"recall settles earnings");var coins:=s.coins;expect(not s.recall("sprout",120).ok and s.coins==coins,"recall pays once")
func _duplicate()->void:
	var s:=State.new();s.park("sprout","morning",1);expect(not s.park("sprout","rooftop",2).ok,"duplicate parking rejected")
func _full_lot()->void:
	var s:=State.new();s.find_lot("morning").slots=[{},{},{},{}];expect(not s.park("sprout","morning",1).ok,"full lot rejected")
func _shop()->void:
	var s:=State.new();s.coins=10000;expect(not s.buy("courier").ok,"level lock enforced");s.level=2;expect(s.buy("courier").ok and s.cars.size()==3 and s.coins==9550,"purchase spends once")
func _missions()->void:
	var s:=State.new();s.stats.parked=1;var r:=s.claim_mission("first_park");var coins:=s.coins;expect(r.ok and r.coins==50,"mission reward");expect(not s.claim_mission("first_park").ok and s.coins==coins,"mission pays once")
func _visitors()->void:
	var s:=State.new();s.initialize(100);s.tick(109);expect(s.home_slots[0] is Dictionary,"visitor arrives");s.tick(200);expect(s.host_income>0,"visitor creates host income");var before:=s.coins;var r:=s.collect_host_income();expect(r.ok and s.coins>before,"host income collectible")
func _sticker()->void:
	var s:=State.new();s.initialize(0);s.tick(9);var before:=s.coins;expect(s.sticker(0).ok and s.coins==before+5,"friendly sticker reward");expect(not s.sticker(0).ok,"one sticker per visit")
func _auto_return()->void:
	var s:=State.new();s.park("sprout","morning",10);var r:=s.tick(10+Config.PARKING_CAP_SECONDS);var coins:=s.coins;s.tick(20+Config.PARKING_CAP_SECONDS);expect(r.returns==1 and s.coins==coins,"auto return pays once")
func _save()->void:
	var s:=State.new();s.coins=4321;s.park("sprout","night",123);expect(Save.save_game(s,TEST_PATH),"save writes");var restored:=Save.load_game(TEST_PATH);expect(restored.coins==4321 and restored.find_car("sprout").state==State.PARKED,"save restores state");DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
func _corrupt()->void:
	var s:=Save.state_from_json("{broken");expect(s.coins==Config.STARTING_COINS and s.cars.size()==2,"corrupt save safe")
func _completion()->void:
	var s:=State.new();s.stats.parked=1;s.stats.recalled=1;s.stats.max_out=2;s.stats.host_collections=1;s.stats.bought=1;s.level=3;expect(s.is_complete(),"demo milestone")
func expect(value:bool,message:String)->void:
	if not value:failures.append(message)
