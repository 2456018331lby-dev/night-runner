extends Node

## 校验 EnemyStats 数值表完整、类型正确、数值合理，并确认每个 enemy 场景能用表实例化。
## 数据本体在 data/enemy_stats.tres；改它、EnemyStats 或 enemy 调参入口后先跑本场景。

const DATA_PATH := "res://data/enemy_stats.tres"

const ENEMY_SCENES := {
	"runner": "res://scenes/actors/enemy_runner.tscn",
	"suppressor": "res://scenes/actors/enemy_suppressor.tscn",
	"bastion": "res://scenes/actors/enemy_bastion.tscn",
	"phantom": "res://scenes/actors/enemy_phantom.tscn",
	"stalker": "res://scenes/actors/enemy_stalker.tscn",
	"bolt": "res://scenes/actors/enemy_bolt.tscn",
}

# 每个 kind 必须提供的字段（挑关键平衡字段，缺失即算回归）。
const REQUIRED_KEYS := {
	"runner": ["max_hp", "points_award", "speed", "gravity", "contact_range", "dash_attack_cooldown"],
	"suppressor": ["max_hp", "points_award", "walk_speed", "fire_cooldown", "projectile_speed", "fire_range_x"],
	"bastion": ["max_hp", "points_award", "walk_speed", "shock_cooldown", "shock_windup"],
	"phantom": ["max_hp", "points_award", "walk_speed", "dive_speed_x", "dive_speed_y", "dive_cooldown"],
	"stalker": ["max_hp", "points_award", "walk_speed", "plunge_speed_y", "cling_time", "landing_impact_range"],
	"bolt": ["lifetime"],
}

# 每个 kind 允许出现的全部字段（各 enemy _hydrate_stats() 的消费面）；数据文件出现表外键说明拼错或成了死字段。
const ALLOWED_KEYS := {
	"runner": ["max_hp", "points_award", "speed", "gravity", "contact_range", "dash_attack_speed", "dash_attack_duration", "dash_attack_cooldown", "dash_attack_range"],
	"suppressor": ["max_hp", "points_award", "walk_speed", "retreat_speed", "gravity", "contact_range", "fire_range_x", "fire_range_y", "comfort_range", "too_close_range", "fire_cooldown", "projectile_speed"],
	"bastion": ["max_hp", "points_award", "walk_speed", "gravity", "contact_range", "pressure_range_x", "pressure_range_y", "shock_cooldown", "shock_windup"],
	"phantom": ["max_hp", "points_award", "walk_speed", "gravity", "contact_range", "dive_range_x", "dive_range_y", "dive_speed_x", "dive_speed_y", "dive_cooldown", "dive_recovery_time", "windup_time", "dive_time"],
	"stalker": ["max_hp", "points_award", "walk_speed", "gravity", "contact_range", "plunge_speed_y", "plunge_aim_range_x", "cling_time", "warning_time", "recovery_time", "reposition_time", "landing_impact_range", "platform_reach_x"],
	"bolt": ["lifetime"],
}

var failures: Array[String] = []


func _ready() -> void:
	_verify_data_file()
	_verify_table_shape()
	_verify_value_sanity()
	_verify_scene_hydration()

	if failures.is_empty():
		print("Enemy stats regression passed.")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _verify_data_file() -> void:
	# 数据文件必须存在且能作为 EnemyStatsData 载入——EnemyStats 加载失败会静默回退 inline 表，这里把失败显式化。
	_expect(ResourceLoader.exists(DATA_PATH), "enemy stats data exists at %s" % DATA_PATH)
	if not ResourceLoader.exists(DATA_PATH):
		return
	var data: Resource = ResourceLoader.load(DATA_PATH)
	_expect(data != null and data.has_method("get_kind_stats"), "data file loads as EnemyStatsData")
	if data == null or not data.has_method("get_kind_stats"):
		return

	# kind 集合与场景表完全一致，防拼写和漏配。
	var data_kinds: Array = data.get_kinds()
	for kind in ENEMY_SCENES.keys():
		_expect(kind in data_kinds, "data file declares kind %s" % kind)
		var table: Dictionary = data.get_kind_stats(kind)
		_expect(not table.is_empty(), "data file kind %s is non-empty" % kind)
		# 键白名单：出现消费面之外的键 = 拼错或死字段。
		var allowed: Array = ALLOWED_KEYS.get(kind, [])
		for key in table.keys():
			_expect(key in allowed, "%s data key %s is consumed by its enemy script" % [kind, key])
		# 类型检查：hp / 分数必须是 int，其余数值必须是 int 或 float。
		for key in table.keys():
			var value: Variant = table[key]
			if key == "max_hp" or key == "points_award":
				_expect(value is int, "%s %s is an int" % [kind, key])
			else:
				_expect(value is int or value is float, "%s %s is numeric" % [kind, key])

	# 漂移护栏：inline 兜底表必须与数据文件逐字段一致，否则加载失败时数值会悄悄变化。
	for kind in ENEMY_SCENES.keys():
		var file_table: Dictionary = data.get_kind_stats(kind)
		var fallback_table: Dictionary = EnemyStats.DEFAULT_STATS.get(kind, {})
		_expect(file_table.keys().size() == fallback_table.keys().size(), "%s fallback table has same key count as data file" % kind)
		for key in file_table.keys():
			var file_value: Variant = file_table[key]
			var fallback_value: Variant = fallback_table.get(key, null)
			_expect(
				fallback_value != null and is_equal_approx(float(file_value), float(fallback_value)),
				"%s.%s inline fallback (%s) matches data file (%s)" % [kind, key, str(fallback_value), str(file_value)]
			)


func _verify_table_shape() -> void:
	for kind in ENEMY_SCENES.keys():
		_expect(EnemyStats.has_kind(kind), "table has kind %s" % kind)
		var required: Array = REQUIRED_KEYS.get(kind, [])
		for key in required:
			var value: Variant = EnemyStats.get_stat(kind, key, null)
			_expect(value != null, "%s table provides %s" % [kind, key])

	# get_stats 应返回副本，改副本不污染源表。
	var copy := EnemyStats.get_stats("runner")
	copy["max_hp"] = 999
	_expect(int(EnemyStats.get_stat("runner", "max_hp", -1)) != 999, "get_stats returns an isolated copy")
	# 未知 kind 走 fallback。
	_expect(int(EnemyStats.get_stat("__missing__", "max_hp", 7)) == 7, "unknown kind returns fallback")


func _verify_value_sanity() -> void:
	# hp / 分数为正整数；速度 / range / cooldown 为正数（dive_speed_y 例外，向上为负）。
	for kind in REQUIRED_KEYS.keys():
		if kind == "bolt":
			_expect(float(EnemyStats.get_stat("bolt", "lifetime", -1.0)) > 0.0, "bolt lifetime is positive")
			continue
		var hp := int(EnemyStats.get_stat(kind, "max_hp", 0))
		_expect(hp >= 1, "%s max_hp is at least 1" % kind)
		var points := int(EnemyStats.get_stat(kind, "points_award", 0))
		_expect(points > 0, "%s points_award is positive" % kind)


func _verify_scene_hydration() -> void:
	# 每个 enemy 场景应能实例化，且实例上的 POINTS_AWARD 与表一致（bolt 无此字段，只验实例化）。
	for kind in ENEMY_SCENES.keys():
		var path: String = ENEMY_SCENES[kind]
		_expect(ResourceLoader.exists(path), "%s scene exists at %s" % [kind, path])
		if not ResourceLoader.exists(path):
			continue
		var packed := load(path) as PackedScene
		_expect(packed != null, "%s scene loads as PackedScene" % kind)
		if packed == null:
			continue
		var instance := packed.instantiate()
		_expect(instance != null, "%s scene instantiates" % kind)
		if instance == null:
			continue
		add_child(instance)
		if kind != "bolt":
			var expected_points := int(EnemyStats.get_stat(kind, "points_award", -1))
			var actual_points := int(instance.get("POINTS_AWARD"))
			_expect(actual_points == expected_points, "%s instance POINTS_AWARD (%d) matches table (%d)" % [kind, actual_points, expected_points])
			var expected_hp := int(EnemyStats.get_stat(kind, "max_hp", -1))
			var actual_hp := int(instance.get("max_hp"))
			_expect(actual_hp == expected_hp, "%s instance max_hp (%d) matches table (%d)" % [kind, actual_hp, expected_hp])
		instance.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
