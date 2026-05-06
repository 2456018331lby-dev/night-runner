extends Node

signal state_changed
signal run_started
signal run_failed
signal run_finished(success: bool)

const COMBO_WINDOW := 4.0

var score: int = 0
var health: int = 3
var elapsed_time: float = 0.0
var is_run_active: bool = false
var is_run_failed: bool = false
var run_success: bool = false
var combo_count: int = 0
var combo_timer: float = 0.0
var data_cores_collected: int = 0
var data_cores_total: int = 0
var extraction_unlocked: bool = false
var final_rank: String = "--"
var result_summary: String = ""
var meta_progress: Dictionary = {
	"highest_score": 0,
	"unlocked_chapters": ["prototype"],
}


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


func start_run() -> void:
	score = 0
	health = 3
	elapsed_time = 0.0
	is_run_active = true
	is_run_failed = false
	run_success = false
	combo_count = 0
	combo_timer = 0.0
	data_cores_collected = 0
	data_cores_total = 0
	extraction_unlocked = false
	final_rank = "--"
	result_summary = ""
	run_started.emit()
	state_changed.emit()


func add_score(amount: int) -> void:
	score += amount
	if score > int(meta_progress.get("highest_score", 0)):
		meta_progress["highest_score"] = score
	state_changed.emit()


func register_enemy_defeat(base_points: int) -> void:
	if combo_timer > 0.0 and combo_count > 0:
		combo_count += 1
	else:
		combo_count = 1
	combo_timer = COMBO_WINDOW
	score += base_points + max(0, combo_count - 1) * 50
	if score > int(meta_progress.get("highest_score", 0)):
		meta_progress["highest_score"] = score
	state_changed.emit()


func set_data_core_total(total: int) -> void:
	data_cores_total = total
	data_cores_collected = 0
	extraction_unlocked = total == 0
	state_changed.emit()


func collect_data_core(points: int = 250) -> void:
	data_cores_collected = min(data_cores_total, data_cores_collected + 1)
	score += points
	if data_cores_collected >= data_cores_total:
		extraction_unlocked = true
	if score > int(meta_progress.get("highest_score", 0)):
		meta_progress["highest_score"] = score
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
	if is_run_failed:
		run_failed.emit()
	run_finished.emit(success)
	state_changed.emit()


func set_result(rank: String, summary: String) -> void:
	final_rank = rank
	result_summary = summary
	state_changed.emit()


func formatted_time() -> String:
	var total_seconds := int(elapsed_time)
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]
