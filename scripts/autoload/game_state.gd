extends Node

signal state_changed
signal run_started
signal run_failed
signal run_finished(success: bool)
signal progress_changed

const SAVE_PATH := "user://night_runner_save.json"
const UI_EMIT_INTERVAL := 0.2
const DEFAULT_COMBO_WINDOW := 4.8
const RANK_THRESHOLDS := [
	{"rank": "S", "score": 2400},
	{"rank": "A", "score": 1850},
	{"rank": "B", "score": 1400},
	{"rank": "C", "score": 950},
	{"rank": "D", "score": 0},
]
const DEFAULT_META_PROGRESS := {
	"highest_score": 0,
	"selected_operation_id": "blitz_pursuit",
	"selected_directives": {},
	"unlocked_operations": ["blitz_pursuit"],
	"career_runs": 0,
	"career_successes": 0,
	"career_failures": 0,
	"operation_records": {},
	"ux_flags": {
		"first_run_brief_seen": false,
		"blitz_tutorial_completed": false,
		"blitz_hint_move_seen": false,
		"blitz_hint_combat_seen": false,
		"blitz_hint_core_seen": false,
		"blitz_hint_extract_seen": false,
	},
	"settings": {
		"master_volume": 0.82,
		"haptics_enabled": true,
	},
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
var current_secondary_objective: Dictionary = {}
var run_modifiers: Dictionary = {}
var meta_progress: Dictionary = {}
var hits_taken: int = 0
var max_combo_reached: int = 0
var secondary_objective_completed: bool = false
var secondary_objective_summary: String = ""
var extraction_bonus_config: Dictionary = {}
var extraction_bonus_label: String = ""
var cashout_tiers: Array = []
var extraction_bonus_active: bool = false
var extraction_bonus_kills: int = 0
var pending_extraction_bonus: int = 0
var double_down_taken: bool = false
var double_down_bonus_gained: int = 0
var extraction_unlock_time: float = -1.0
var enemy_score_total: int = 0
var core_score_total: int = 0
var finish_bonus_awarded: int = 0
var secondary_bonus_awarded: int = 0
var extraction_bonus_awarded: int = 0
var hazard_hits_taken: int = 0
var last_damage_source_kind: String = ""
var last_damage_source_detail: String = ""
var last_damage_position: Vector2 = Vector2.ZERO
var last_damage_position_recorded: bool = false
var live_route_phase: String = "INGRESS"
var live_route_pressure: String = "Route cold."
var live_hazard_status: String = "Hazard net dormant."
var event_banner_text: String = ""
var event_banner_emphasis: float = 0.0
var _ui_emit_accumulator: float = 0.0


func _ready() -> void:
	randomize()
	load_progress()
	apply_runtime_settings()


func _process(delta: float) -> void:
	var should_emit := false
	if event_banner_emphasis > 0.0:
		event_banner_emphasis = maxf(0.0, event_banner_emphasis - delta * 0.55)
		should_emit = true
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
		# 计时驱动的刷新按 0.2s 节流：HUD 每次收到信号会重建约 25 个字符串，
		# 每帧发信号等于每帧 60 次纯分配。离散事件（受击、得分、拾取）从各自
		# 调用点立即 emit，不经过这里，节奏不受影响。
		_ui_emit_accumulator += delta
		if _ui_emit_accumulator >= UI_EMIT_INTERVAL:
			_ui_emit_accumulator = 0.0
			state_changed.emit()


func start_run(operation: Dictionary = {}, directive: Dictionary = {}) -> void:
	current_operation_id = String(operation.get("id", ""))
	current_operation_title = String(operation.get("title", ""))
	current_operation_summary = String(operation.get("summary", ""))
	current_directive = directive.duplicate(true)
	current_secondary_objective = Dictionary(operation.get("secondary_objective", {})).duplicate(true)
	extraction_bonus_config = Dictionary(operation.get("extraction_bonus", {})).duplicate(true)
	extraction_bonus_label = String(extraction_bonus_config.get("label", "Cashout Bonus"))
	cashout_tiers = Array(operation.get("cashout_tiers", [])).duplicate(true)
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
	max_combo_reached = 0
	hits_taken = 0
	secondary_objective_completed = false
	secondary_objective_summary = ""
	extraction_bonus_active = false
	extraction_bonus_kills = 0
	pending_extraction_bonus = 0
	double_down_taken = false
	double_down_bonus_gained = 0
	extraction_unlock_time = -1.0
	enemy_score_total = 0
	core_score_total = 0
	finish_bonus_awarded = 0
	secondary_bonus_awarded = 0
	extraction_bonus_awarded = 0
	hazard_hits_taken = 0
	last_damage_source_kind = ""
	last_damage_source_detail = ""
	live_route_phase = "INGRESS"
	live_route_pressure = "Route cold."
	live_hazard_status = "Hazard net dormant."
	event_banner_text = ""
	event_banner_emphasis = 0.0
	data_cores_collected = 0
	data_cores_total = 0
	extraction_unlocked = false
	final_rank = "--"
	result_summary = ""
	meta_progress["selected_operation_id"] = current_operation_id
	if not has_ux_flag("first_run_brief_seen"):
		set_ux_flag("first_run_brief_seen")
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
	max_combo_reached = maxi(max_combo_reached, combo_count)
	combo_timer = combo_window
	var combo_multiplier: float = 1.0 + max(0, combo_count - 1) * 0.15
	var total_points := int(round((base_points * combo_multiplier + max(0, combo_count - 1) * 40) * float(run_modifiers.get("score_multiplier", 1.0))))
	score += total_points
	enemy_score_total += total_points
	if extraction_bonus_active and extraction_unlocked:
		extraction_bonus_kills += 1
		pending_extraction_bonus += get_next_extraction_bonus_value()
	_update_high_score()
	state_changed.emit()


func set_data_core_total(total: int) -> void:
	data_cores_total = total
	data_cores_collected = 0
	extraction_unlocked = total == 0
	state_changed.emit()


func collect_data_core(points: int = 250) -> void:
	var reward := int(round(points * float(run_modifiers.get("score_multiplier", 1.0))))
	data_cores_collected = min(data_cores_total, data_cores_collected + 1)
	score += reward
	core_score_total += reward
	if data_cores_collected >= data_cores_total:
		extraction_unlocked = true
		extraction_unlock_time = elapsed_time
		activate_extraction_bonus()
	_update_high_score()
	state_changed.emit()


func lose_health(amount: int = 1) -> void:
	# 已通关 / 已失败 / 未开局都不再扣血：避免通关后被残余敌人改判失败并二次记档。
	if is_run_failed or run_success or not is_run_active:
		return
	hits_taken += amount
	health = max(0, health - amount)
	if health == 0:
		var summary := "Run collapsed under %s." % get_last_damage_source_summary()
		if pending_extraction_bonus > 0:
			summary += " Lost %s +%d." % [get_extraction_bonus_label(), pending_extraction_bonus]
		set_result("FAIL", summary)
		finish_run(false)
	else:
		state_changed.emit()


func finish_run(success: bool) -> void:
	# 幂等：坠落 / 受伤收尾会在多帧里重复触发，一局只能结算一次。
	# 否则每帧都会 +1 战绩、写存档、发 telemetry、重建结算界面。
	if not is_run_active:
		return
	is_run_active = false
	is_run_failed = not success
	run_success = success
	combo_count = 0
	combo_timer = 0.0
	if success and current_operation_id == "blitz_pursuit" and not has_ux_flag("blitz_tutorial_completed"):
		set_ux_flag("blitz_tutorial_completed", true, false)
	_commit_run_record(success)
	_emit_run_telemetry()
	if is_run_failed:
		run_failed.emit()
	run_finished.emit(success)
	state_changed.emit()
	progress_changed.emit()


func set_result(rank: String, summary: String) -> void:
	final_rank = rank
	result_summary = summary
	state_changed.emit()


func calculate_rank_for_score(score_value: int) -> String:
	for rank_data in RANK_THRESHOLDS:
		if score_value >= int(rank_data.get("score", 0)):
			return String(rank_data.get("rank", "D"))
	return "D"


func formatted_time() -> String:
	var total_seconds := int(elapsed_time)
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]


func is_operation_unlocked(operation_id: String) -> bool:
	return get_unlocked_operations().has(operation_id)


func get_unlocked_operations() -> Array[String]:
	var unlocked: Array[String] = []
	for value in meta_progress.get("unlocked_operations", []):
		unlocked.append(str(value))
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


func get_ux_flags() -> Dictionary:
	return Dictionary(meta_progress.get("ux_flags", {}))


func has_ux_flag(flag_name: String) -> bool:
	return bool(get_ux_flags().get(flag_name, false))


func set_ux_flag(flag_name: String, value: bool = true, save_now: bool = true) -> void:
	var ux_flags := get_ux_flags()
	if bool(ux_flags.get(flag_name, false)) == value:
		return
	ux_flags[flag_name] = value
	meta_progress["ux_flags"] = ux_flags
	if save_now:
		save_progress()
	progress_changed.emit()


func is_blitz_tutorial_active() -> bool:
	return current_operation_id == "blitz_pursuit" and not has_ux_flag("blitz_tutorial_completed")


func get_first_run_brief_lines() -> Array[String]:
	return [
		"Move / Jump / Attack / Dash",
		"Collect all data cores",
		"Extract when the gate unlocks",
	]


func get_quick_reminder_lines() -> Array[String]:
	return [
		"MOVE · JUMP · ATK · DASH",
		"TAKE ALL CORES",
		"EXTRACT ON UNLOCK",
	]


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
		meta_progress = _merge_meta_progress(parsed)
	meta_progress = _merge_meta_progress(meta_progress)
	apply_runtime_settings()
	progress_changed.emit()


func get_settings() -> Dictionary:
	return _dictionary_or_empty(meta_progress.get("settings", {}))


func get_master_volume() -> float:
	return clampf(float(get_settings().get("master_volume", 0.82)), 0.0, 1.0)


func set_master_volume(value: float, save_now: bool = true) -> void:
	var settings := get_settings()
	settings["master_volume"] = clampf(value, 0.0, 1.0)
	meta_progress["settings"] = settings
	_apply_master_volume()
	if save_now:
		save_progress()
	progress_changed.emit()


func are_haptics_enabled() -> bool:
	return bool(get_settings().get("haptics_enabled", true))


func set_haptics_enabled(enabled: bool, save_now: bool = true) -> void:
	var settings := get_settings()
	settings["haptics_enabled"] = enabled
	meta_progress["settings"] = settings
	if save_now:
		save_progress()
	progress_changed.emit()


func apply_runtime_settings() -> void:
	_apply_master_volume()


func _apply_master_volume() -> void:
	var bus_index := AudioServer.get_bus_index("Master")
	if bus_index < 0:
		bus_index = 0
	var volume := get_master_volume()
	AudioServer.set_bus_volume_db(bus_index, -80.0 if volume <= 0.001 else linear_to_db(volume))


func _merge_meta_progress(raw: Dictionary) -> Dictionary:
	var merged := DEFAULT_META_PROGRESS.duplicate(true).merged(raw, true)
	merged["ux_flags"] = Dictionary(DEFAULT_META_PROGRESS["ux_flags"]).merged(_dictionary_or_empty(raw.get("ux_flags", {})), true)
	merged["settings"] = Dictionary(DEFAULT_META_PROGRESS["settings"]).merged(_dictionary_or_empty(raw.get("settings", {})), true)
	merged["unlocked_operations"] = _string_array_or_default(raw.get("unlocked_operations", []), DEFAULT_META_PROGRESS["unlocked_operations"])
	merged["operation_records"] = _records_or_empty(raw.get("operation_records", {}))
	merged["selected_directives"] = _dictionary_or_empty(raw.get("selected_directives", {}))
	merged["selected_operation_id"] = str(merged["selected_operation_id"])
	merged["highest_score"] = maxi(0, int(merged["highest_score"]))
	merged["career_runs"] = maxi(0, int(merged["career_runs"]))
	merged["career_successes"] = maxi(0, int(merged["career_successes"]))
	merged["career_failures"] = maxi(0, int(merged["career_failures"]))
	return merged


func _string_array_or_default(value: Variant, fallback: Array) -> Array:
	if value is Array:
		var filtered: Array = []
		for entry in value:
			filtered.append(str(entry))
		return filtered
	return (fallback as Array).duplicate(true)


func _records_or_empty(value: Variant) -> Dictionary:
	var records := _dictionary_or_empty(value)
	for key in records.keys():
		if not (records[key] is Dictionary):
			records.erase(key)
	return records


func _dictionary_or_empty(value: Variant) -> Dictionary:
	return Dictionary(value) if value is Dictionary else {}


func get_modifier_value(key: String, fallback: float = 1.0) -> float:
	return float(run_modifiers.get(key, fallback))


func get_current_directive_name() -> String:
	return String(current_directive.get("name", ""))


func get_current_directive_summary() -> String:
	return String(current_directive.get("summary", ""))


func get_secondary_objective_name() -> String:
	return String(current_secondary_objective.get("name", ""))


func get_secondary_objective_description() -> String:
	return String(current_secondary_objective.get("description", ""))


func evaluate_secondary_objective() -> Dictionary:
	if current_secondary_objective.is_empty():
		return {"completed": false, "summary": "", "reward_score": 0}
	var objective_type := String(current_secondary_objective.get("type", ""))
	var completed := false
	match objective_type:
		"time_limit":
			completed = elapsed_time <= float(current_secondary_objective.get("target_time", 0.0))
		"no_hit":
			completed = hits_taken <= 0
		"score_threshold":
			completed = score >= int(current_secondary_objective.get("target_score", 0))
		_:
			completed = false
	var reward_score := int(current_secondary_objective.get("reward_score", 0)) if completed else 0
	var summary := "Secondary objective complete: %s (+%d)" % [get_secondary_objective_name(), reward_score] if completed else "Secondary objective failed: %s" % get_secondary_objective_name()
	secondary_objective_completed = completed
	secondary_objective_summary = summary
	return {
		"completed": completed,
		"summary": summary,
		"reward_score": reward_score,
	}


func get_secondary_objective_status_text() -> String:
	if current_secondary_objective.is_empty():
		return "No optional objective."
	var objective_type := String(current_secondary_objective.get("type", ""))
	match objective_type:
		"time_limit":
			var target_time := float(current_secondary_objective.get("target_time", 0.0))
			var delta_time := target_time - elapsed_time
			if delta_time >= 0.0:
				return "Extract before %s // %s left" % [_format_raw_time(target_time), _format_raw_time(delta_time)]
			return "Time bonus missed // %s over" % _format_raw_time(absf(delta_time))
		"no_hit":
			if hits_taken > 0:
				return "No hits taken: BROKEN // %d hit(s)" % hits_taken
			return "No hits taken: INTACT"
		"score_threshold":
			var target_score := int(current_secondary_objective.get("target_score", 0))
			var score_gap := maxi(0, target_score - score)
			if score_gap <= 0:
				return "Score target armed // %d current" % score
			return "Reach %d score // %d left" % [target_score, score_gap]
		_:
			return get_secondary_objective_description()


func get_secondary_objective_progress_ratio() -> float:
	if current_secondary_objective.is_empty():
		return 0.0
	var objective_type := String(current_secondary_objective.get("type", ""))
	match objective_type:
		"time_limit":
			var target_time := float(current_secondary_objective.get("target_time", 0.0))
			if target_time <= 0.0:
				return 0.0
			return clampf(elapsed_time / target_time, 0.0, 1.0)
		"no_hit":
			return 0.0 if hits_taken > 0 else 1.0
		"score_threshold":
			var target_score: int = maxi(1, int(current_secondary_objective.get("target_score", 1)))
			return clampf(float(score) / float(target_score), 0.0, 1.0)
		_:
			return 0.0


func activate_extraction_bonus() -> void:
	extraction_bonus_active = not extraction_bonus_config.is_empty()
	extraction_bonus_kills = 0
	pending_extraction_bonus = 0
	state_changed.emit()


func double_down_pending_bonus(multiplier: float) -> int:
	var previous_bonus := pending_extraction_bonus
	pending_extraction_bonus = int(round(float(pending_extraction_bonus) * maxf(1.0, multiplier)))
	double_down_taken = true
	double_down_bonus_gained = pending_extraction_bonus - previous_bonus
	state_changed.emit()
	return pending_extraction_bonus


func apply_run_end_rewards(exit_bonus: int, objective_bonus: int, cashout_bonus: int) -> int:
	finish_bonus_awarded = max(0, exit_bonus)
	secondary_bonus_awarded = max(0, objective_bonus)
	extraction_bonus_awarded = max(0, cashout_bonus)
	var total_reward := finish_bonus_awarded + secondary_bonus_awarded + extraction_bonus_awarded
	add_score(total_reward)
	return total_reward


func get_next_extraction_bonus_value() -> int:
	if extraction_bonus_config.is_empty():
		return 0
	var base_value := int(extraction_bonus_config.get("base_bounty", 0))
	var step_value := int(extraction_bonus_config.get("step_bounty", 0))
	var raw_value: int = base_value + max(0, extraction_bonus_kills - 1) * step_value
	var scaled_value := float(raw_value) * float(run_modifiers.get("extraction_bonus_multiplier", 1.0))
	return int(round(scaled_value * get_cashout_tier_multiplier()))


func get_cashout_tier() -> Dictionary:
	if not extraction_unlocked or cashout_tiers.is_empty():
		return {}
	var cashout_elapsed := get_cashout_elapsed_time()
	var current_tier: Dictionary = {}
	for tier in cashout_tiers:
		if tier is Dictionary and float(Dictionary(tier).get("elapsed", 0.0)) <= cashout_elapsed:
			current_tier = Dictionary(tier)
	return current_tier


func get_cashout_tier_multiplier() -> float:
	var tier := get_cashout_tier()
	if tier.is_empty():
		return 1.0
	return float(tier.get("bounty_multiplier", 1.0))


func get_extraction_bonus_label() -> String:
	return extraction_bonus_label if not extraction_bonus_label.is_empty() else "Cashout Bonus"


func get_extraction_bonus_status_text() -> String:
	if not extraction_unlocked:
		return "Locked until all data cores are secured."
	if not extraction_bonus_active:
		return "No extraction bonus active."
	var live_time := formatted_cashout_time()
	var status_text := ""
	if pending_extraction_bonus <= 0:
		status_text = "%s %s live. Extract now or defeat enemies for bonus." % [get_extraction_bonus_label(), live_time]
	else:
		status_text = "%s %s +%d banked // %d takedowns" % [get_extraction_bonus_label(), live_time, pending_extraction_bonus, extraction_bonus_kills]
	var tier := get_cashout_tier()
	if not tier.is_empty():
		status_text += " // %s x%.1f" % [String(tier.get("label", "")), float(tier.get("bounty_multiplier", 1.0))]
	return status_text


func get_extraction_bonus_progress_ratio() -> float:
	if not extraction_bonus_active:
		return 0.0
	var kill_ratio := clampf(float(mini(extraction_bonus_kills, 5)) / 5.0, 0.0, 1.0)
	var time_ratio := clampf(get_cashout_elapsed_time() / 25.0, 0.0, 1.0)
	return maxf(kill_ratio, time_ratio)


func get_cashout_elapsed_time() -> float:
	if extraction_unlock_time < 0.0:
		return 0.0
	return maxf(0.0, elapsed_time - extraction_unlock_time)


static func compute_cashout_loop_count(cashout_elapsed: float, loop_config: Dictionary) -> int:
	if loop_config.is_empty():
		return 0
	var start_elapsed := float(loop_config.get("start_elapsed", 0.0))
	var interval := float(loop_config.get("interval", 0.0))
	if interval <= 0.0 or cashout_elapsed < start_elapsed:
		return 0
	return int(floor((cashout_elapsed - start_elapsed) / interval)) + 1


func formatted_cashout_time() -> String:
	return _format_raw_time(get_cashout_elapsed_time())


func register_damage_source(kind: String, detail: String = "", position: Vector2 = Vector2.ZERO) -> void:
	last_damage_source_kind = kind
	last_damage_source_detail = detail
	last_damage_position = position
	last_damage_position_recorded = true
	if kind == "hazard":
		hazard_hits_taken += 1


func set_live_route_status(phase_text: String, pressure_text: String, hazard_text: String) -> void:
	if live_route_phase == phase_text and live_route_pressure == pressure_text and live_hazard_status == hazard_text:
		return
	live_route_phase = phase_text
	live_route_pressure = pressure_text
	live_hazard_status = hazard_text
	state_changed.emit()


func get_route_phase_text() -> String:
	return live_route_phase


func get_route_pressure_text() -> String:
	return live_route_pressure


func get_hazard_status_text() -> String:
	return live_hazard_status


func push_event_banner(text: String, emphasis: float = 1.0) -> void:
	event_banner_text = text
	event_banner_emphasis = clampf(emphasis, 0.0, 1.0)
	state_changed.emit()


func get_event_banner_text() -> String:
	return event_banner_text


func get_event_banner_emphasis() -> float:
	return event_banner_emphasis


func get_operation_feel_summary() -> String:
	match current_operation_id:
		"blitz_pursuit":
			return "Fast-clear route. Secure the cores cleanly, then decide whether pursuit pressure is worth cashout greed."
		"ghost_circuit":
			return "Angle-reading route. Suppressors and relay hazards matter more than raw speed, and overstay turns stealth into exposure."
		"overdrive_protocol":
			return "Adaptive greed route. Directive choice, mixed enemy lanes and score threshold decisions define the run."
		_:
			return "Short-run extraction loop."


func get_run_metrics() -> Dictionary:
	return {
		"combat_score": enemy_score_total,
		"core_score": core_score_total,
		"exit_bonus": finish_bonus_awarded,
		"objective_bonus": secondary_bonus_awarded,
		"cashout_bonus": extraction_bonus_awarded,
		"hits_taken": hits_taken,
		"hazard_hits": hazard_hits_taken,
		"max_combo": max_combo_reached,
		"cashout_kills": extraction_bonus_kills,
		"elapsed_time": elapsed_time,
		"operation_feel": get_operation_feel_summary(),
	}


func get_run_score_breakdown_lines() -> Array[String]:
	var lines: Array[String] = []
	lines.append("Combat +%d // Core haul +%d" % [enemy_score_total, core_score_total])
	if run_success:
		lines.append("Exit package +%d // Optional +%d // Cashout +%d" % [
			finish_bonus_awarded,
			secondary_bonus_awarded,
			extraction_bonus_awarded,
		])
	else:
		lines.append("No extraction package secured // Lost banked cashout +%d" % pending_extraction_bonus)
	return lines


func get_run_rank_report_lines() -> Array[String]:
	var lines: Array[String] = []
	if run_success:
		var next_rank := _get_next_rank_target()
		if next_rank.is_empty():
			lines.append("Rank S secured // Score target cleared.")
		else:
			lines.append("Rank %s // %d score to %s." % [
				final_rank,
				maxi(0, int(next_rank.get("score", 0)) - score),
				String(next_rank.get("rank", "S")),
			])
	else:
		lines.append("Extraction failed // secure the gate before chasing rank.")
	lines.append("Pace %s // Exit package +%d." % [formatted_time(), finish_bonus_awarded])
	lines.append("Damage %d hit(s) // Hazard hits %d." % [hits_taken, hazard_hits_taken])
	if not current_secondary_objective.is_empty():
		var optional_label := "Optional complete +%d." % secondary_bonus_awarded if secondary_objective_completed else "Optional missed // %s" % get_secondary_objective_name()
		lines.append(optional_label)
	if run_success and extraction_bonus_awarded > 0:
		lines.append("%s cashed +%d from %d takedown(s) over %s." % [
			get_extraction_bonus_label(),
			extraction_bonus_awarded,
			extraction_bonus_kills,
			formatted_cashout_time(),
		])
		if double_down_taken:
			lines.append("Double-down honored: bank x2 (+%d)." % double_down_bonus_gained)
	elif pending_extraction_bonus > 0:
		if double_down_taken:
			lines.append("%s lost +%d after doubling down over %s // the gamble collapsed." % [get_extraction_bonus_label(), pending_extraction_bonus, formatted_cashout_time()])
		else:
			lines.append("%s lost +%d after %s // cash out sooner." % [get_extraction_bonus_label(), pending_extraction_bonus, formatted_cashout_time()])
	elif extraction_bonus_active:
		lines.append("%s unused at %s // overstay after unlock for score." % [get_extraction_bonus_label(), formatted_cashout_time()])
	return lines


func get_run_verdict_text() -> String:
	var hazard_clause := "Hazard net avoided cleanly." if hazard_hits_taken <= 0 else "Hazard net connected %d time(s)." % hazard_hits_taken
	var combo_clause := "Max combo x%d." % max_combo_reached if max_combo_reached > 0 else "No combo chain established."
	if run_success:
		return "Extracted in %s with %d hit(s) taken. %s %s" % [
			formatted_time(),
			hits_taken,
			combo_clause,
			hazard_clause,
		]
	return "Route collapsed after %s with %d hit(s) taken. %s %s" % [
		formatted_time(),
		hits_taken,
		combo_clause,
		hazard_clause,
	]


func get_result_outcome_summary() -> String:
	if run_success:
		return "All %d cores secured. Extracted in %s with rank %s." % [
			data_cores_total,
			formatted_time(),
			final_rank,
		]
	if extraction_unlocked:
		return "Extraction was live, but the run collapsed to %s." % get_last_damage_source_summary()
	return "The run ended before extraction unlocked. Last pressure came from %s." % get_last_damage_source_summary()


func get_result_next_hint() -> String:
	if run_success:
		if extraction_bonus_awarded > 0:
			return "Next run, stay in the cashout lane a little longer if the route still feels stable."
		return "Next run, try a short cashout overstay after the gate unlocks for bonus score."
	if not extraction_unlocked:
		if data_cores_collected <= 1:
			return "Follow the route vector and secure the early cores before taking long fights."
		return "Finish the remaining cores first. Extraction matters more than greed."
	if pending_extraction_bonus > 0:
		return "The gate was open. Cash out earlier instead of holding the lane for one more fight."
	return "Once extraction opens, reset the lane and leave instead of brawling in place."


func get_last_damage_source_summary() -> String:
	match last_damage_source_kind:
		"hazard":
			return "route hazard pressure"
		"enemy":
			match last_damage_source_detail:
				"runner_body":
					return "runner impact"
				"suppressor_body":
					return "suppressor impact"
				"suppressor_bolt":
					return "suppressor fire"
				"bastion_body":
					return "bastion collision"
				"bastion_shockwave":
					return "bastion shockwave"
				"phantom_body":
					return "phantom slash"
				"phantom_dive":
					return "phantom dive"
				"stalker_body":
					return "stalker slam"
				"stalker_landing":
					return "stalker shockwave"
				_:
					return "hostile pressure"
		_:
			return "combat pressure"


func describe_modifier_block(modifiers: Dictionary) -> String:
	if modifiers.is_empty():
		return "No modifier shifts."
	var fragments: Array[String] = []
	var order := [
		"speed_multiplier",
		"dash_multiplier",
		"jump_multiplier",
		"boost_multiplier",
		"attack_force_multiplier",
		"combo_window_multiplier",
		"score_multiplier",
		"finish_bonus_multiplier",
		"extraction_bonus_multiplier",
		"health_bonus",
		"silent_bonus",
	]
	for key in order:
		if not modifiers.has(key):
			continue
		var fragment := _format_modifier_line(key, modifiers[key])
		if not fragment.is_empty():
			fragments.append(fragment)
	return " // ".join(fragments) if not fragments.is_empty() else "No modifier shifts."


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
		"extraction_bonus_multiplier": 1.0,
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
		record["best_rank"] = _pick_best_rank(str(record.get("best_rank", "--")), final_rank)
	if score > int(record.get("best_score", 0)):
		record["best_score"] = score
	if success:
		var best_time := float(record.get("best_time", 0.0))
		if best_time <= 0.0 or elapsed_time < best_time:
			record["best_time"] = elapsed_time
	if str(record.get("last_directive_name", "")).is_empty() or not current_directive.is_empty():
		record["last_directive_name"] = get_current_directive_name()
	records[current_operation_id] = record
	meta_progress["operation_records"] = records

	if success:
		_unlock_follow_up_operations()
	save_progress()


func _unlock_follow_up_operations() -> void:
	var operation: Dictionary = preload("res://scripts/game/run_catalog.gd").shared().get_operation(current_operation_id)
	for operation_id in operation.get("unlocks", []):
		unlock_operation(str(operation_id))


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


func _get_next_rank_target() -> Dictionary:
	var next_target: Dictionary = {}
	for rank_data in RANK_THRESHOLDS:
		var target_score := int(rank_data.get("score", 0))
		if score < target_score:
			next_target = Dictionary(rank_data)
	return next_target


func _format_modifier_line(key: String, value: Variant) -> String:
	match key:
		"speed_multiplier":
			return _format_percent_shift("SPD", float(value))
		"dash_multiplier":
			return _format_percent_shift("DASH", float(value))
		"jump_multiplier":
			return _format_percent_shift("JUMP", float(value))
		"boost_multiplier":
			return _format_percent_shift("BOOST", float(value))
		"attack_force_multiplier":
			return _format_percent_shift("ATK", float(value))
		"combo_window_multiplier":
			return _format_percent_shift("COMBO", float(value))
		"score_multiplier":
			return _format_percent_shift("SCORE", float(value))
		"finish_bonus_multiplier":
			return _format_percent_shift("EXIT", float(value))
		"extraction_bonus_multiplier":
			return _format_percent_shift("CASHOUT", float(value))
		"health_bonus":
			var health_delta := int(round(float(value)))
			return "HP %+d" % health_delta if health_delta != 0 else ""
		"silent_bonus":
			var bonus := int(round(float(value)))
			return "SILENT +%d" % bonus if bonus != 0 else ""
		_:
			return ""


func _format_percent_shift(label: String, multiplier: float) -> String:
	if is_equal_approx(multiplier, 1.0):
		return ""
	var percent_delta := int(round((multiplier - 1.0) * 100.0))
	return "%s %+d%%" % [label, percent_delta]


func _format_raw_time(time_value: float) -> String:
	var total_seconds := int(time_value)
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]


func _emit_run_telemetry() -> void:
	if not OS.has_feature("web"):
		return
	var telemetry := _build_run_telemetry()
	var telemetry_json := JSON.stringify(telemetry)
	var js_code := "console.log('[NightRunner Telemetry]', %s);" % telemetry_json
	JavaScriptBridge.eval(js_code)


func _build_run_telemetry() -> Dictionary:
	var death_cause := _get_death_cause()
	var death_position := _get_death_position()
	var phase_reached := _get_phase_reached()
	return {
		"run_id": "%s_%d_%d" % [current_operation_id, Time.get_ticks_msec(), randi()],
		"route_id": current_operation_id,
		"directive_id": String(current_directive.get("id", "base")),
		"success": run_success,
		"death_cause": death_cause,
		"death_x_position": death_position.x,
		"death_y_position": death_position.y,
		"phase_reached": phase_reached,
		"cashout_overstay_seconds": int(get_cashout_elapsed_time()),
		"cores_collected": data_cores_collected,
		"final_score": score,
		"elapsed_time": int(elapsed_time),
		"hits_taken": hits_taken,
		"max_combo": max_combo_reached,
		"extraction_unlocked": extraction_unlocked,
	}


func _get_death_cause() -> String:
	if run_success:
		return "success"
	if last_damage_source_kind == "fall":
		return "fall"
	if last_damage_source_kind == "hazard":
		return "hazard"
	if last_damage_source_detail == "runner_body":
		return "enemy_runner"
	if last_damage_source_detail.begins_with("suppressor"):
		return "enemy_suppressor"
	if last_damage_source_detail.begins_with("bastion"):
		return "enemy_bastion"
	if last_damage_source_detail.begins_with("phantom"):
		return "enemy_phantom"
	if last_damage_source_detail.begins_with("stalker"):
		return "enemy_stalker"
	if last_damage_source_detail == "bolt_body":
		return "enemy_bolt"
	return "unknown"


func _get_death_position() -> Vector2:
	# 没有记录过伤害来源时返回哨兵值，避免把 (0,0) 当成真实死亡坐标。
	if not last_damage_position_recorded:
		return Vector2(-1.0, -1.0)
	return last_damage_position


func _get_phase_reached() -> String:
	# live_route_phase 由 World 实时维护（INGRESS / BREACH / CASHOUT），比静态推断更贴近实际进度。
	if not live_route_phase.is_empty():
		return live_route_phase.to_lower()
	if extraction_unlocked:
		return "extraction"
	if data_cores_collected > 0:
		return "breach"
	return "ingress"
