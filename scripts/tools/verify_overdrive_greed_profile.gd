extends Node

const RunCatalogScript := preload("res://scripts/game/run_catalog.gd")

var failures: Array[String] = []


func _ready() -> void:
	var blitz := RunCatalogScript.get_operation("blitz_pursuit")
	_expect(not blitz.is_empty(), "Blitz Pursuit exists")
	if not blitz.is_empty():
		var blitz_objective: Dictionary = blitz.get("secondary_objective", {})
		_expect(float(blitz_objective.get("target_time", 0.0)) == 58.0, "Blitz time-limit target remains 00:58")
		_expect(String(blitz_objective.get("description", "")).contains("00:58"), "Blitz time-limit description matches its target")

	var overdrive := RunCatalogScript.get_operation("overdrive_protocol")
	_expect(not overdrive.is_empty(), "Overdrive Protocol exists")
	if overdrive.is_empty():
		_finish()
		return

	var objective: Dictionary = overdrive.get("secondary_objective", {})
	_expect(String(objective.get("type", "")) == "score_threshold", "Overdrive optional objective is score-threshold based")
	_expect(int(objective.get("target_score", 0)) >= 3200, "Overdrive score threshold stays high enough to require greed")
	_expect(int(objective.get("reward_score", 0)) >= 600, "Overdrive score-threshold reward is worth routing around")

	var extraction_bonus: Dictionary = overdrive.get("extraction_bonus", {})
	var base_bounty := int(extraction_bonus.get("base_bounty", 0))
	var step_bounty := int(extraction_bonus.get("step_bounty", 0))
	_expect(base_bounty >= 120, "Overdrive cashout base bounty is higher than standard routes")
	_expect(step_bounty >= 65, "Overdrive cashout step bounty escalates clearly")

	var base_modifiers: Dictionary = overdrive.get("base_modifiers", {})
	_expect(float(base_modifiers.get("extraction_bonus_multiplier", 1.0)) > 1.0, "Overdrive base modifiers improve cashout value")

	var found_panic_dividend := false
	for directive in overdrive.get("directive_pool", []):
		if String(directive.get("id", "")) != "panic_dividend":
			continue
		found_panic_dividend = true
		var modifiers: Dictionary = directive.get("modifiers", {})
		_expect(float(modifiers.get("extraction_bonus_multiplier", 1.0)) >= 1.3, "Panic Dividend multiplies cashout rewards")
		_expect(GameState.describe_modifier_block(modifiers).contains("CASHOUT"), "cashout multiplier is visible in directive UI summaries")
	_expect(found_panic_dividend, "Panic Dividend directive exists")

	var cashout_events: Array = overdrive.get("cashout_events", [])
	_expect(cashout_events.size() >= 3, "Overdrive has a third cashout escalation wave")
	if cashout_events.size() >= 3:
		var final_event: Dictionary = cashout_events[cashout_events.size() - 1]
		_expect(float(final_event.get("elapsed", 0.0)) >= 22.0, "final Overdrive cashout wave is a late greed check")
		_expect(_count_control_enemies(final_event.get("spawn", [])) >= 3, "final Overdrive cashout wave uses cross-lane control pressure")

	GameState.start_run(overdrive, {"modifiers": {"extraction_bonus_multiplier": 1.5}})
	GameState.score = 2200
	_expect(GameState.get_secondary_objective_status_text().contains("1000 left"), "score-threshold optional objective shows remaining score")
	GameState.score = 3300
	_expect(GameState.get_secondary_objective_status_text().contains("Score target armed"), "score-threshold optional objective confirms when armed")
	GameState.activate_extraction_bonus()
	_expect(GameState.get_next_extraction_bonus_value() == int(round(float(base_bounty) * 1.5 * float(base_modifiers.get("extraction_bonus_multiplier", 1.0)))), "cashout multiplier affects first bounty")
	GameState.extraction_bonus_kills = 2
	_expect(GameState.get_next_extraction_bonus_value() == int(round(float(base_bounty + step_bounty) * 1.5 * float(base_modifiers.get("extraction_bonus_multiplier", 1.0)))), "cashout multiplier affects step bounty")

	if not blitz.is_empty():
		GameState.start_run(blitz, {})
		GameState.elapsed_time = 42.0
		var blitz_live_status := GameState.get_secondary_objective_status_text()
		_expect(blitz_live_status.contains("00:16 left"), "time-limit optional objective shows remaining time")
		GameState.elapsed_time = 65.0
		var blitz_missed_status := GameState.get_secondary_objective_status_text()
		_expect(blitz_missed_status.contains("Time bonus missed"), "time-limit optional objective marks missed bonus")
		_expect(blitz_missed_status.contains("00:07 over"), "time-limit optional objective shows over-time")

	var ghost := RunCatalogScript.get_operation("ghost_circuit")
	_expect(not ghost.is_empty(), "Ghost Circuit exists")
	if not ghost.is_empty():
		GameState.start_run(ghost, {})
		GameState.hits_taken = 1
		var ghost_status := GameState.get_secondary_objective_status_text()
		_expect(ghost_status.contains("BROKEN"), "no-hit optional objective marks broken status")
		_expect(ghost_status.contains("1 hit"), "no-hit optional objective shows hit count")

	_expect(GameState.calculate_rank_for_score(2400) == "S", "rank thresholds produce S at the top target")
	_expect(GameState.calculate_rank_for_score(2399) == "A", "rank thresholds keep near-S clears at A")
	_expect(GameState.calculate_rank_for_score(949) == "D", "rank thresholds keep sub-C clears at D")

	GameState.run_success = true
	GameState.score = 2200
	GameState.final_rank = GameState.calculate_rank_for_score(GameState.score)
	GameState.elapsed_time = 42.0
	GameState.finish_bonus_awarded = 420
	GameState.secondary_objective_completed = true
	GameState.secondary_bonus_awarded = int(objective.get("reward_score", 0))
	GameState.extraction_bonus_awarded = 0
	GameState.pending_extraction_bonus = 0
	GameState.extraction_bonus_active = true
	GameState.extraction_bonus_kills = 0
	GameState.hits_taken = 1
	GameState.hazard_hits_taken = 1
	var success_report := GameState.get_run_rank_report_lines()
	_expect(success_report.size() >= 5, "rank report includes enough result coaching detail")
	_expect(success_report[0].contains("200 score to S"), "rank report explains near-S score gap")
	_expect(_has_line(success_report, "Pace 00:42"), "rank report includes pace and exit package")
	_expect(_has_line(success_report, "Damage 1 hit"), "rank report includes damage pressure")
	_expect(_has_line(success_report, "Optional complete +640"), "rank report includes optional objective payout")

	GameState.run_success = false
	GameState.final_rank = "FAIL"
	GameState.pending_extraction_bonus = 390
	var failure_report := GameState.get_run_rank_report_lines()
	_expect(failure_report[0].contains("Extraction failed"), "failed rank report prioritizes extraction over score chasing")
	_expect(_has_line(failure_report, "lost +390"), "failed rank report calls out lost cashout value")

	_finish()


func _count_control_enemies(spawn_list: Array) -> int:
	var count := 0
	for spawn_data in spawn_list:
		var scene: PackedScene = spawn_data.get("scene")
		if scene == null:
			continue
		if scene.resource_path in [
			"res://scenes/actors/enemy_suppressor.tscn",
			"res://scenes/actors/enemy_bastion.tscn",
			"res://scenes/actors/enemy_stalker.tscn",
		]:
			count += 1
	return count


func _has_line(lines: Array[String], needle: String) -> bool:
	for line in lines:
		if line.contains(needle):
			return true
	return false


func _finish() -> void:
	if failures.is_empty():
		print("Overdrive greed profile regression passed.")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
