extends Node

const RunCatalogScript := preload("res://scripts/game/run_catalog.gd")

var failures: Array[String] = []


func _ready() -> void:
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
	GameState.activate_extraction_bonus()
	_expect(GameState.get_next_extraction_bonus_value() == int(round(float(base_bounty) * 1.5 * float(base_modifiers.get("extraction_bonus_multiplier", 1.0)))), "cashout multiplier affects first bounty")
	GameState.extraction_bonus_kills = 2
	_expect(GameState.get_next_extraction_bonus_value() == int(round(float(base_bounty + step_bounty) * 1.5 * float(base_modifiers.get("extraction_bonus_multiplier", 1.0)))), "cashout multiplier affects step bounty")

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
