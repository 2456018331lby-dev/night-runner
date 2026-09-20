extends Node

## 敌人数值访问层：所有平衡向数值的唯一入口。
##
## 数据本体在 data/enemy_stats.tres（EnemyStatsData 资源，可在 Inspector 调参）。
## 本 autoload 在 _ready() 同步加载它；加载失败 / 缺字段时回退到下面的 inline DEFAULT_STATS，
## 保证"缺数据 = 旧行为"，各 enemy 脚本与 verify 都不需要改。
##
## 调敌人数值优先改 data/enemy_stats.tres，不要再回到各 enemy 脚本里散改常量。
## 改完先跑 scenes/tools/verify_enemy_stats.tscn 与 verify_encounter_pressure.tscn。

const DATA_PATH := "res://data/enemy_stats.tres"
const GRAVITY_DEFAULT := 1500.0

# 加载失败时的兜底表，与 data/enemy_stats.tres 保持一致。
const DEFAULT_STATS := {
	"runner": {
		"max_hp": 2,
		"points_award": 100,
		"speed": 132.0,
		"gravity": GRAVITY_DEFAULT,
		"contact_range": 30.0,
		"dash_attack_speed": 320.0,
		"dash_attack_duration": 0.22,
		"dash_attack_cooldown": 2.8,
		"dash_attack_range": 220.0,
	},
	"suppressor": {
		"max_hp": 3,
		"points_award": 150,
		"walk_speed": 90.0,
		"retreat_speed": 145.0,
		"gravity": GRAVITY_DEFAULT,
		"contact_range": 30.0,
		"fire_range_x": 520.0,
		"fire_range_y": 170.0,
		"comfort_range": 250.0,
		"too_close_range": 150.0,
		"fire_cooldown": 1.65,
		"projectile_speed": 385.0,
	},
	"bastion": {
		"max_hp": 5,
		"points_award": 260,
		"walk_speed": 64.0,
		"gravity": GRAVITY_DEFAULT,
		"contact_range": 38.0,
		"pressure_range_x": 380.0,
		"pressure_range_y": 180.0,
		"shock_cooldown": 2.55,
		"shock_windup": 0.68,
	},
	"phantom": {
		"max_hp": 3,
		"points_award": 220,
		"walk_speed": 128.0,
		"gravity": GRAVITY_DEFAULT,
		"contact_range": 30.0,
		"dive_range_x": 420.0,
		"dive_range_y": 210.0,
		"dive_speed_x": 460.0,
		"dive_speed_y": -250.0,
		"dive_cooldown": 2.25,
		"dive_recovery_time": 0.22,
		"windup_time": 0.42,
		"dive_time": 0.34,
	},
	"stalker": {
		"max_hp": 4,
		"points_award": 240,
		"walk_speed": 72.0,
		"gravity": GRAVITY_DEFAULT,
		"contact_range": 32.0,
		"plunge_speed_y": 680.0,
		"plunge_aim_range_x": 260.0,
		"cling_time": 1.8,
		"warning_time": 0.55,
		"recovery_time": 0.48,
		"reposition_time": 1.2,
		"landing_impact_range": 120.0,
		"platform_reach_x": 380.0,
	},
	"bolt": {
		"lifetime": 3.5,
	},
}

var _stats: Dictionary = DEFAULT_STATS


func _ready() -> void:
	_load_data()


func _load_data() -> void:
	if not ResourceLoader.exists(DATA_PATH):
		push_warning("EnemyStats: %s not found, using inline defaults." % DATA_PATH)
		_stats = DEFAULT_STATS
		return
	var data: Resource = ResourceLoader.load(DATA_PATH)
	if data == null or not data.has_method("get_kind_stats"):
		push_error("EnemyStats: %s failed to load as EnemyStatsData, using inline defaults." % DATA_PATH)
		_stats = DEFAULT_STATS
		return
	var loaded: Dictionary = {}
	for kind in data.get_kinds():
		loaded[kind] = data.get_kind_stats(kind)
	if loaded.is_empty():
		push_error("EnemyStats: %s contained no kinds, using inline defaults." % DATA_PATH)
		_stats = DEFAULT_STATS
		return
	_stats = loaded


## 取单个字段；表里没有该 kind 或字段时返回 fallback，保证调用方行为不变。
func get_stat(kind: String, key: String, fallback: Variant) -> Variant:
	var table: Dictionary = _stats.get(kind, {})
	return table.get(key, fallback)


## 取某 kind 的整张表副本（只读用途）。未知 kind 返回空字典。
func get_stats(kind: String) -> Dictionary:
	return (_stats.get(kind, {}) as Dictionary).duplicate(true)


## 是否收录了该 kind。
func has_kind(kind: String) -> bool:
	return _stats.has(kind)
