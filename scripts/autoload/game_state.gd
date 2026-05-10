extends Node

signal state_changed
signal run_started
signal run_failed
signal run_finished(success: bool)
signal progress_changed

const SAVE_PATH := "user://night_runner_save.json"
const DEFAULT_COMBO_WINDOW := 4.0
const DEFAULT_META_PROGRESS := {
	"highest_score": 0,
	"selected_operation_id": "blitz_pursuit",
	"unlocked_operations": ["blitz_pursuit"],
	"career_runs": 0,
	"career_successes": 0,
	"career_failures": 0,
	"operation_records": {},
}

var score: int = 0
var health: int = 3
var elapsed_time: float = 0.0
var is_run_active: bool = false
var is_run_failed: bool = false
var run_success: bool = false
var combo_count: int = 0
var combo_timer: float = 0.0
var combo_window: float = DEFAULT_COMBO_WINDOW
var data_cores_collected: int = 0
var data_cores_total: int = 0
var extraction_unlocked: bool = false
var final_rank: String = "--"
var result_summary: String = ""
var current_operation_id: String = ""
var current_operation_title: String = ""
var current_operation_summary: String = ""
var current_directive: Dictionary = {}
var run_modifiers: Dictionary = {}
var meta_progress: Dictionary = {}


func _ready() -> void:
	randomize()
	load_progress()


func _process(delta: float) -> void:
	var should_emit := false
	if is_run_active and not is_run_failed:
		elapsed_time += delta
		should_emit = true
		if combo_timer > 0.0:
			combo_timer -= delta
			if combo_timer <= 0.0:
				combo_timer = 0.0
				combo_count = 0
				should_emit = true
	if should_emit:
		state_changed.emit()


func start_run(operation: Dictionary = {}, directive: Dictionary = {}) -> void:
	current_operation_id = String(operation.get("id", ""))
	current_operation_title = String(operation.get("title", ""))
	current_operation_summary = String(operation.get("summary", ""))
	current_directive = directive.duplicate(true)
	run_modifiers = _build_run_modifiers(operation, directive)
	score = 0
	health = max(1, 3 + int(run_modifiers.get("health_bonus", 0)))
	elapsed_time = 0.0
	is_run_active = true
	is_run_failed = false
	run_success = false
	combo_count = 0
	combo_timer = 0.0
	combo_window = maxf(1.2, DEFAULT_COMBO_WINDOW * float(run_modifiers.get("combo_window_multiplier", 1.0)))
	data_cores_collected = 0
	data_cores_total = 0
	extraction_unlocked = false
	final_rank = "--"
	result_summary = ""
	meta_progress["selected_operation_id"] = current_operation_id
	save_progress()
	run_started.emit()
	state_changed.emit()
	progress_changed.emit()


func add_score(amount: int) -> void:
	score += amount
	_update_high_score()
	state_changed.emit()


func register_enemy_defeat(base_points: int) -> void:
	if combo_timer > 0.0 and combo_count > 0:
		combo_count += 1
	else:
		combo_count = 1
	combo_timer = combo_window
	var total_points := int(round((base_points + max(0, combo_count - 1) * 50) * float(run_modifiers.get("score_multiplier", 1.0))))
	score += total_points
	_update_high_score()
	state_changed.emit()


func set_data_core_total(total: int) -> void:
	data_cores_total = total
	data_cores_collected = 0
	extraction_unlocked = total == 0
	state_changed.emit()


func collect_data_core(points: int = 250) -> void:
	data_cores_collected = min(data_cores_total, data_cores_collected + 1)
	score += int(round(points * float(run_modifiers.get("score_multiplier", 1.0))))
	if data_cores_collected >= data_cores_total:
		extraction_unlocked = true
	_update_high_score()
	state_changed.emit()


func lose_health(amount: int = 1) -> void:
	if is_run_failed:
		return
	health = max(0, health - amount)
	if health == 0:
		finish_run(false)
	else:
		state_changed.emit()


func finish_run(success: bool) -> void:
	is_run_active = false
	is_run_failed = not success
	run_success = success
	combo_count = 0
	combo_timer = 0.0
	_commit_run_record(success)
	if is_run_failed:
		run_failed.emit()
	run_finished.emit(success)
	state_changed.emit()
	progress_changed.emit()


func set_result(rank: String, summary: String) -> void:
	final_rank = rank
	result_summary = summary
	state_changed.emit()


func formatted_time() -> String:
	var total_seconds := int(elapsed_time)
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]


func formatted_success_rate() -> String:
	var runs := int(meta_progress.get("career_runs", 0))
	if runs <= 0:
		return "--"
	var wins := int(meta_progress.get("career_successes", 0))
	return "%d%%" % int(round(float(wins) / float(runs) * 100.0))


func is_operation_unlocked(operation_id: String) -> bool:
	return get_unlocked_operations().has(operation_id)


func get_unlocked_operations() -> Array[String]:
	var unlocked: Array[String] = []
	for value in meta_progress.get("unlocked_operations", []):
		unlocked.append(String(value))
	return unlocked


func unlock_operation(operation_id: String) -> bool:
	if operation_id.is_empty():
		return false
	var unlocked := get_unlocked_operations()
	if unlocked.has(operation_id):
		return false
	unlocked.append(operation_id)
	meta_progress["unlocked_operations"] = unlocked
	save_progress()
	progress_changed.emit()
	return true


func get_operation_record(operation_id: String) -> Dictionary:
	var records: Dictionary = meta_progress.get("operation_records", {})
	var raw: Dictionary = records.get(operation_id, {})
	return _default_operation_record().merged(raw, true)


func save_progress() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(meta_progress))


func load_progress() -> void:
	meta_progress = DEFAULT_META_PROGRESS.duplicate(true)
	if not FileAccess.file_exists(SAVE_PATH):
		progress_changed.emit()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		progress_changed.emit()
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		meta_progress = DEFAULT_META_PROGRESS.duplicate(true).merged(parsed, true)
	progress_changed.emit()


func get_modifier_value(key: String, fallback: float = 1.0) -> float:
	return float(run_modifiers.get(key, fallback))


func get_current_directive_name() -> String:
	return String(current_directive.get("name", ""))


func get_current_directive_summary() -> String:
	return String(current_directive.get("summary", ""))


func _build_run_modifiers(operation: Dictionary, directive: Dictionary) -> Dictionary:
	var merged: Dictionary = {
		"health_bonus": 0,
		"speed_multiplier": 1.0,
		"dash_multiplier": 1.0,
		"jump_multiplier": 1.0,
		"boost_multiplier": 1.0,
		"score_multiplier": 1.0,
		"combo_window_multiplier": 1.0,
		"finish_bonus_multiplier": 1.0,
		"silent_bonus": 0,
		"attack_force_multiplier": 1.0,
	}
	var base_modifiers: Dictionary = operation.get("base_modifiers", {})
	for key in base_modifiers.keys():
		merged[key] = base_modifiers[key]
	var directive_modifiers: Dictionary = directive.get("modifiers", {})
	for key in directive_modifiers.keys():
		var current_value: Variant = merged.get(key)
		var next_value: Variant = directive_modifiers[key]
		if current_value is float or current_value is int:
			if key.ends_with("_multiplier"):
				merged[key] = float(current_value) * float(next_value)
			else:
				merged[key] = float(current_value) + float(next_value)
		else:
			merged[key] = next_value
	return merged


func _update_high_score() -> void:
	if score > int(meta_progress.get("highest_score", 0)):
		meta_progress["highest_score"] = score


func _commit_run_record(success: bool) -> void:
	meta_progress["career_runs"] = int(meta_progress.get("career_runs", 0)) + 1
	if success:
		meta_progress["career_successes"] = int(meta_progress.get("career_successes", 0)) + 1
	else:
		meta_progress["career_failures"] = int(meta_progress.get("career_failures", 0)) + 1

	var records: Dictionary = meta_progress.get("operation_records", {})
	var record := get_operation_record(current_operation_id)
	record["runs"] = int(record.get("runs", 0)) + 1
	if success:
		record["successes"] = int(record.get("successes", 0)) + 1
		record["best_rank"] = _pick_best_rank(String(record.get("best_rank", "--")), final_rank)
	if score > int(record.get("best_score", 0)):
		record["best_score"] = score
	if success:
		var best_time := float(record.get("best_time", 0.0))
		if best_time <= 0.0 or elapsed_time < best_time:
			record["best_time"] = elapsed_time
	if String(record.get("last_directive_name", "")).is_empty() or not current_directive.is_empty():
		record["last_directive_name"] = get_current_directive_name()
	records[current_operation_id] = record
	meta_progress["operation_records"] = records

	if success:
		_unlock_follow_up_operations()
	save_progress()


func _unlock_follow_up_operations() -> void:
	var operation: Dictionary = preload("res://scripts/game/run_catalog.gd").get_operation(current_operation_id)
	for operation_id in operation.get("unlocks", []):
		unlock_operation(String(operation_id))


func _default_operation_record() -> Dictionary:
	return {
		"runs": 0,
		"successes": 0,
		"best_score": 0,
		"best_rank": "--",
		"best_time": 0.0,
		"last_directive_name": "",
	}


func _pick_best_rank(existing_rank: String, next_rank: String) -> String:
	var order := ["S", "A", "B", "C", "D", "--"]
	if order.find(next_rank) == -1:
		return existing_rank
	if order.find(existing_rank) == -1:
		return next_rank
	return next_rank if order.find(next_rank) < order.find(existing_rank) else existing_rank
