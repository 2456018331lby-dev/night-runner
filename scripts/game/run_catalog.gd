class_name RunCatalog
extends RefCounted

const DATA_PATH := "res://data/run_operations.tres"

# 资源文件是唯一正式内容源。兜底只保留一条最小可启动路线，避免维护第二份完整
# 的三路线配置；如果打包漏掉 data/run_operations.tres，游戏仍能进入可玩的安全模式。
const FALLBACK_OPERATION := {
	"id": "blitz_pursuit",
	"title": "Emergency Pursuit",
	"subtitle": "Safe-mode extraction",
	"mode_label": "Emergency Route",
	"summary": "A minimal recovery route loaded because the operation catalog is unavailable.",
	"brief": "Recover the core and reach extraction while the catalog is repaired.",
	"intel": "Content data is unavailable. Reinstall or rebuild the package before release.",
	"theme": {
		"primary": Color("46d2ff"),
		"secondary": Color("ff7e43"),
		"backdrop": Color("08111f"),
		"moon": Color("ffd166"),
	},
	"unlocks": [],
	"locked_text": "Available in catalog recovery mode.",
	"spawn_position": Vector2(148, 590),
	"extraction_position": Vector2(900, 470),
	"platforms": [
		{"position": Vector2(520, 666), "size": Vector2(1000, 64), "color": Color("18233a")},
		{"position": Vector2(900, 500), "size": Vector2(280, 30), "color": Color("20314d")},
	],
	"encounters": [],
	"data_cores": [Vector2(520, 590)],
	"boost_pads": [],
	"hazards": [],
	"timeline_events": [],
	"core_events": [],
	"completion_spawns": [],
	"objective_intro": "Recover the core, then extract.",
	"objective_complete": "Extraction is available. Reach the gate.",
	"intro_toast": "Catalog recovery route online.",
	"block_toast": "Core recovery incomplete.",
	"completion_toast": "Recovery complete. Proceed to extraction.",
	"lane_signals": [],
	"phase_setpiece": {},
	"base_modifiers": {
		"boost_multiplier": 1.0,
		"combo_window_multiplier": 1.0,
		"dash_multiplier": 1.0,
		"extraction_bonus_multiplier": 1.0,
		"finish_bonus_multiplier": 1.0,
		"health_bonus": 0,
		"jump_multiplier": 1.0,
		"score_multiplier": 1.0,
		"silent_bonus": 0,
		"speed_multiplier": 1.0,
	},
	"directive_pool": [{
		"id": "recovery_protocol",
		"name": "Recovery Protocol",
		"summary": "A stable fallback loadout for catalog recovery.",
		"modifiers": {},
	}],
	"secondary_objective": {
		"id": "recovery_clear",
		"name": "Recovery Clear",
		"description": "Reach extraction without taking damage.",
		"type": "no_hit",
		"reward_score": 200,
	},
	"extraction_bonus": {
		"label": "Recovery Bank",
		"base_bounty": 50,
		"step_bounty": 25,
	},
	"cashout_tiers": [{"elapsed": 0.0, "label": "SAFE", "bounty_multiplier": 1.0}],
	"cashout_events": [],
	"cashout_loop": {},
}

var _data: Resource
var _operations: Array[Dictionary] = []
static var _shared: RunCatalog = null


static func shared() -> RunCatalog:
	if _shared == null:
		_shared = RunCatalog.new()
	return _shared


func _init() -> void:
	_load_data()


func _load_data() -> void:
	if not ResourceLoader.exists(DATA_PATH):
		_use_fallback("not found")
		return
	var data: Resource = ResourceLoader.load(DATA_PATH)
	if data == null or not data.has_method("get_operations"):
		_use_fallback("failed to load")
		return
	var loaded: Array = data.get_operations()
	if loaded.is_empty():
		_use_fallback("empty")
		return
	_data = data
	_operations = _deep_copy_operations(loaded)


func _use_fallback(reason: String) -> void:
	push_error("RunCatalog: %s %s; using minimal recovery route." % [DATA_PATH, reason])
	_operations = [_deep_copy_operation(FALLBACK_OPERATION)]


func _deep_copy_operation(source: Dictionary) -> Dictionary:
	return source.duplicate(true)


func _deep_copy_operations(source: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for operation in source:
		if operation is Dictionary:
			result.append(_deep_copy_operation(operation))
	return result


func get_operations() -> Array[Dictionary]:
	return _deep_copy_operations(_operations)


func get_operation(operation_id: String) -> Dictionary:
	for operation in _operations:
		if String(operation.get("id", "")) == operation_id:
			return _deep_copy_operation(operation)
	return {}


func get_first_operation_id() -> String:
	if _operations.is_empty():
		return ""
	return String(_operations[0].get("id", ""))
