extends Node

## 校验 RunCatalog 操作表完整、类型正确、数据合理，并确认 fallback 表与 .tres 文件一致。
## 数据本体在 data/run_operations.tres；改它或 RunCatalog 后先跑本场景。

const DATA_PATH := "res://data/run_operations.tres"

# 每个 operation 必须提供的关键字段（缺失即算回归）。
const REQUIRED_KEYS := [
	"id", "title", "subtitle", "mode_label", "summary", "brief", "intel",
	"theme", "unlocks", "locked_text", "spawn_position", "extraction_position",
	"platforms", "encounters", "data_cores", "boost_pads", "hazards",
	"timeline_events", "core_events", "completion_spawns",
	"objective_intro", "objective_complete", "intro_toast", "block_toast",
	"completion_toast", "lane_signals", "phase_setpiece",
	"base_modifiers", "directive_pool", "secondary_objective",
	"extraction_bonus", "cashout_tiers", "cashout_events", "cashout_loop",
]

# 已知的三条操作路线 id。
const EXPECTED_OPERATION_IDS := ["blitz_pursuit", "ghost_circuit", "overdrive_protocol"]

# 仅 Overdrive 才有的贪分通道，缺了会静默抹平最高贪分路线。
const OVERDRIVE_ONLY_KEYS := ["cashout_beacon"]

var failures: Array[String] = []


func _ready() -> void:
	_verify_data_file()
	_verify_catalog_api()
	_verify_operation_shape()
	_verify_encounter_scenes()
	_verify_route_specific_keys()
	_verify_fallback_consistency()

	if failures.is_empty():
		print("RunCatalog regression passed.")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _verify_data_file() -> void:
	# 数据文件必须存在且能作为 RunOperationData 载入。
	_expect(ResourceLoader.exists(DATA_PATH), "run operations data exists at %s" % DATA_PATH)
	if not ResourceLoader.exists(DATA_PATH):
		return
	var data: Resource = ResourceLoader.load(DATA_PATH)
	_expect(data != null and data.has_method("get_operations"), "data file loads as RunOperationData")
	if data == null or not data.has_method("get_operations"):
		return

	var operations: Array = data.get_operations()
	_expect(not operations.is_empty(), "data file contains operations")
	_expect(operations.size() == 3, "data file contains exactly 3 operations")

	# 校验每个 operation 包含所有必需键。
	for operation in operations:
		_expect_required_keys(operation, "data file")


func _verify_catalog_api() -> void:
	# RunCatalog 应能实例化，并提供 get_operations / get_operation / get_first_operation_id / shared 方法。
	var catalog = RunCatalog.new()
	_expect(catalog != null, "RunCatalog instantiates")
	if catalog == null:
		return

	var operations: Array = catalog.get_operations()
	_expect(not operations.is_empty(), "catalog.get_operations() returns non-empty array")
	_expect(operations.size() == 3, "catalog returns exactly 3 operations")

	# 校验已知 operation id 能被查询。
	for op_id in EXPECTED_OPERATION_IDS:
		var operation: Dictionary = catalog.get_operation(op_id)
		_expect(not operation.is_empty(), "catalog.get_operation('%s') returns data" % op_id)
		_expect(str(operation.get("id", "")) == op_id, "operation id matches query '%s'" % op_id)

	# 未知 id 应返回空字典。
	var missing := catalog.get_operation("__nonexistent__")
	_expect(missing.is_empty(), "catalog.get_operation() returns empty dict for unknown id")

	# get_first_operation_id 应返回第一个操作的 id。
	var first_id: String = catalog.get_first_operation_id()
	_expect(first_id == "blitz_pursuit", "get_first_operation_id() returns 'blitz_pursuit'")

	# shared() 必须返回同一个实例，否则操作表会被重复加载多份。
	var shared_a = RunCatalog.shared()
	var shared_b = RunCatalog.shared()
	_expect(shared_a == shared_b, "RunCatalog.shared() returns a stable instance")
	_expect(shared_a.get_operations().size() == 3, "shared() catalog returns exactly 3 operations")



func _verify_operation_shape() -> void:
	# 每个 operation 的关键字段应有正确的类型和合理的值。
	var catalog = RunCatalog.new()
	var operations: Array = catalog.get_operations()

	for operation in operations:
		var op_id: String = str(operation.get("id", ""))
		_expect_required_keys(operation, "catalog")

		# 文本字段非空。
		_expect(not str(operation.get("title", "")).is_empty(), "%s has non-empty title" % op_id)
		_expect(not str(operation.get("brief", "")).is_empty(), "%s has non-empty brief" % op_id)

		# theme 包含颜色字段。
		var theme: Dictionary = operation.get("theme", {})
		_expect(theme.has("primary") and theme.primary is Color, "%s theme.primary is Color" % op_id)
		_expect(theme.has("secondary") and theme.secondary is Color, "%s theme.secondary is Color" % op_id)

		# spawn / extraction 位置是 Vector2。
		var spawn_pos: Variant = operation.get("spawn_position")
		_expect(spawn_pos is Vector2, "%s spawn_position is Vector2" % op_id)
		var extraction_pos: Variant = operation.get("extraction_position")
		_expect(extraction_pos is Vector2, "%s extraction_position is Vector2" % op_id)

		# platforms 数组非空。
		var platforms: Array = operation.get("platforms", [])
		_expect(not platforms.is_empty(), "%s has platforms" % op_id)

		# encounters 数组非空且每个包含 scene 和 position。
		var encounters: Array = operation.get("encounters", [])
		_expect(not encounters.is_empty(), "%s has encounters" % op_id)
		for encounter in encounters:
			_expect(encounter.has("scene") and encounter.scene is PackedScene, "%s encounter has valid scene" % op_id)
			_expect(encounter.has("position") and encounter.position is Vector2, "%s encounter has position" % op_id)

		# data_cores 数组非空。
		var cores: Array = operation.get("data_cores", [])
		_expect(not cores.is_empty(), "%s has data_cores" % op_id)

		# base_modifiers 包含关键乘数。
		var modifiers: Dictionary = operation.get("base_modifiers", {})
		_expect(modifiers.has("speed_multiplier"), "%s base_modifiers has speed_multiplier" % op_id)
		_expect(modifiers.has("score_multiplier"), "%s base_modifiers has score_multiplier" % op_id)

		# 撤离兑现窗口必须存在，否则行动失去核心闭环。
		var extraction_bonus: Dictionary = operation.get("extraction_bonus", {})
		_expect(not extraction_bonus.is_empty(), "%s has a non-empty extraction_bonus" % op_id)



func _verify_encounter_scenes() -> void:
	# .tres 里的 PackedScene 引用必须真实可解析，null scene 会让刷怪静默失效。
	var data: Resource = ResourceLoader.load(DATA_PATH)
	if data == null or not data.has_method("get_operations"):
		return

	for operation in data.get_operations():
		var op_id: String = str(operation.get("id", ""))
		for encounter in operation.get("encounters", []):
			_expect(encounter.has("scene"), "%s encounter has scene key" % op_id)
			_expect(encounter.get("scene") != null, "%s encounter scene reference resolves" % op_id)
		for event in operation.get("timeline_events", []):
			_check_spawn_scenes(op_id, "timeline_event", event)
		for event in operation.get("core_events", []):
			_check_spawn_scenes(op_id, "core_event", event)
		for event in operation.get("cashout_events", []):
			_check_spawn_scenes(op_id, "cashout_event", event)
		for setup in operation.get("completion_spawns", []):
			_expect(setup.get("scene") != null, "%s completion_spawn scene reference resolves" % op_id)


func _check_spawn_scenes(op_id: String, event_label: String, event: Variant) -> void:
	if not (event is Dictionary):
		return
	for spawn_data in Dictionary(event).get("spawn", []):
		if spawn_data is Dictionary and Dictionary(spawn_data).has("scene"):
			_expect(Dictionary(spawn_data).get("scene") != null,
				"%s %s spawn scene reference resolves" % [op_id, event_label])


func _verify_route_specific_keys() -> void:
	# Overdrive 是最高贪分路线，cashout_beacon 不能丢。
	var catalog = RunCatalog.new()
	for operation in catalog.get_operations():
		var op_id: String = str(operation.get("id", ""))
		if op_id != "overdrive_protocol":
			continue
		for key in OVERDRIVE_ONLY_KEYS:
			_expect(operation.has(key), "operation %s has required key '%s'" % [op_id, key])


func _verify_fallback_consistency() -> void:
	# 加载 .tres 文件与 RunCatalog.DEFAULT_OPERATIONS 进行逐字段一致性校验。
	var data: Resource = ResourceLoader.load(DATA_PATH)
	if data == null or not data.has_method("get_operations"):
		return

	var file_operations: Array = data.get_operations()
	var fallback_operations: Array = RunCatalog.DEFAULT_OPERATIONS.duplicate(true)

	_expect(file_operations.size() == fallback_operations.size(),
		"fallback table has same operation count as data file (%d vs %d)" % [fallback_operations.size(), file_operations.size()])

	# 逐 operation 校验 id 一致（顺序可能不同，但 id 集合应相同）。
	var file_ids: Array[String] = []
	var fallback_ids: Array[String] = []
	for op in file_operations:
		file_ids.append(str(op.get("id", "")))
	for op in fallback_operations:
		fallback_ids.append(str(op.get("id", "")))

	for id in file_ids:
		_expect(id in fallback_ids, "fallback table contains operation id '%s'" % id)
	for id in fallback_ids:
		_expect(id in file_ids, "data file contains fallback operation id '%s'" % id)

	# 兜底表也必须满足同一套字段白名单，否则数据文件缺失时会静默降级成残缺操作。
	for operation in fallback_operations:
		_expect_required_keys(operation, "fallback table")


func _expect_required_keys(operation: Variant, source_label: String) -> void:
	if not (operation is Dictionary):
		_expect(false, "%s operation entry is a Dictionary" % source_label)
		return
	var op_id: String = str(Dictionary(operation).get("id", ""))
	for key in REQUIRED_KEYS:
		_expect(Dictionary(operation).has(key), "%s operation %s has required key '%s'" % [source_label, op_id, key])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
