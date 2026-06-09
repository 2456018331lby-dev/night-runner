extends Node

const SESSION_SCREEN_SCENE := preload("res://scenes/ui/session_screen.tscn")
const RunCatalogScript := preload("res://scripts/game/run_catalog.gd")

var failures: Array[String] = []


func _ready() -> void:
	var original_mobile := PlatformProfile.is_mobile
	var original_volume := GameState.get_master_volume()
	var original_haptics := GameState.are_haptics_enabled()
	var original_unlocked: Array = GameState.meta_progress.get("unlocked_operations", []).duplicate(true)
	var original_records: Dictionary = GameState.meta_progress.get("operation_records", {}).duplicate(true)
	var original_run_success := GameState.run_success
	var original_run_failed := GameState.is_run_failed
	var original_elapsed := GameState.elapsed_time
	var original_combo := GameState.combo_count
	var original_health := GameState.health
	var original_extraction_unlocked := GameState.extraction_unlocked
	var original_extraction_active := GameState.extraction_bonus_active
	var original_extraction_label := GameState.extraction_bonus_label
	var original_extraction_unlock_time := GameState.extraction_unlock_time
	var original_pending_bonus := GameState.pending_extraction_bonus
	var original_extraction_kills := GameState.extraction_bonus_kills
	var original_route_phase := GameState.get_route_phase_text()
	var original_route_pressure := GameState.get_route_pressure_text()
	var original_hazard_status := GameState.get_hazard_status_text()
	PlatformProfile.is_mobile = true
	GameState.meta_progress["unlocked_operations"] = ["blitz_pursuit"]
	GameState.meta_progress["operation_records"] = {
		"blitz_pursuit": {
			"runs": 3,
			"successes": 2,
			"best_score": 1780,
			"best_rank": "A",
			"best_time": 72.0,
		},
	}
	GameState.set_master_volume(0.7, false)
	GameState.set_haptics_enabled(true, false)

	var screen := SESSION_SCREEN_SCENE.instantiate()
	add_child(screen)
	await get_tree().process_frame

	var blitz := RunCatalogScript.get_operation("blitz_pursuit")
	var knife_party := _find_directive(blitz, "knife_party")
	var directive_detail := String(screen.call("_format_hub_directive_summary", knife_party, false))
	_expect(directive_detail.contains("Longer combo window"), "directive detail should include the directive summary")
	_expect(directive_detail.contains("COMBO +25%"), "directive detail should include combo modifier impact text")
	_expect(directive_detail.contains("ATK +12%"), "directive detail should keep multi-modifier impact text")
	_verify_route_button_state(screen, blitz, RunCatalogScript.get_operation("ghost_circuit"))
	_verify_directive_button_state(screen, blitz, knife_party)

	GameState.run_success = false
	GameState.is_run_failed = false
	GameState.elapsed_time = 74.0
	GameState.combo_count = 4
	GameState.health = 2
	GameState.extraction_unlocked = true
	GameState.extraction_bonus_active = true
	GameState.extraction_bonus_label = "Pursuit Bonus"
	GameState.extraction_unlock_time = 62.0
	GameState.pending_extraction_bonus = 180
	GameState.extraction_bonus_kills = 2
	GameState.set_live_route_status("CASHOUT", "Extraction open. Greed converts survival into payout.", "Hot zone // Convoy shear line")
	screen.call("build_pause", RunCatalogScript.get_operation("blitz_pursuit"))
	await get_tree().process_frame

	var route_list: VBoxContainer = screen.get_node("Content/Root/Body/LeftPanel/LeftCol/RouteScroll/RouteList")
	var directive_list: VBoxContainer = screen.get_node("Content/Root/Body/RightPanel/RightCol/DirectiveScroll/DirectiveList")
	var primary_button: Button = screen.get_node("Content/Root/Footer/ActionRow/Primary")
	var secondary_button: Button = screen.get_node("Content/Root/Footer/ActionRow/Secondary")
	var volume_slider := _find_first_child_of_type(route_list, HSlider) as HSlider
	var haptics_toggle := _find_first_child_of_type(route_list, CheckButton) as CheckButton
	var optional_note := _find_label_starting_with(directive_list, "Optional:")
	var route_note := _find_label_starting_with(route_list, "Route ")
	var cashout_note := _find_label_starting_with(route_list, "Cashout ")
	var hazard_note := _find_label_starting_with(route_list, "Hazard ")
	_expect(volume_slider != null, "pause settings did not create a volume slider")
	_expect(haptics_toggle != null, "pause settings did not create a haptics toggle")
	_expect(optional_note != null, "pause screen did not add optional objective note")
	_expect(route_note != null, "pause screen did not add live route note")
	_expect(cashout_note != null, "pause screen did not add live cashout note")
	_expect(hazard_note != null, "pause screen did not add live hazard note")
	_expect(primary_button.custom_minimum_size.y >= 56.0, "pause resume button is below mobile touch target height")
	_expect(secondary_button.custom_minimum_size.y >= 56.0, "pause hub button is below mobile touch target height")
	if optional_note != null:
		_expect(optional_note.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART, "pause optional objective note should wrap on mobile")
		_expect(optional_note.size_flags_horizontal == Control.SIZE_EXPAND_FILL, "pause optional objective note should fill available width")
	if route_note != null:
		_expect(route_note.text.contains("CASHOUT"), "pause route note should show live route phase")
		_expect(route_note.text.contains("Extraction open"), "pause route note should show compact route pressure")
		_expect(not route_note.text.contains("Greed converts"), "pause route note should avoid full route coaching copy")
	if cashout_note != null:
		_expect(cashout_note.text.contains("Pursuit Bonus 00:12 +180 banked"), "pause cashout note should show live timer and banked value")
	if hazard_note != null:
		_expect(hazard_note.text.contains("Hazard Hot zone · Convoy shear line"), "pause hazard note should compact hazard separators")

	if volume_slider != null:
		_expect(volume_slider.custom_minimum_size.y >= 56.0, "volume slider is below mobile touch target height")
		_expect(is_equal_approx(volume_slider.value, 0.7), "volume slider did not mirror GameState volume")
		volume_slider.value = 0.45
		await get_tree().process_frame
		_expect(is_equal_approx(GameState.get_master_volume(), 0.45), "volume slider did not update GameState volume")

	if haptics_toggle != null:
		_expect(haptics_toggle.custom_minimum_size.y >= 56.0, "haptics toggle is below mobile touch target height")
		_expect(haptics_toggle.size_flags_horizontal == Control.SIZE_EXPAND_FILL, "haptics toggle should fill the pause settings column")
		_expect(haptics_toggle.button_pressed, "haptics toggle did not mirror GameState haptics")
		_expect(not haptics_toggle.disabled, "haptics toggle should be enabled on mobile profile")
		haptics_toggle.button_pressed = false
		await get_tree().process_frame
		_expect(not GameState.are_haptics_enabled(), "haptics toggle did not update GameState haptics")

	GameState.run_success = false
	GameState.is_run_failed = true
	GameState.score = 1260
	GameState.final_rank = "FAIL"
	GameState.health = 1
	GameState.data_cores_collected = 2
	GameState.data_cores_total = 5
	GameState.extraction_unlocked = false
	screen.call("build_results", blitz)
	await get_tree().process_frame
	var result_why_note := _find_label_starting_with(route_list, "Why:")
	var result_try_note := _find_label_starting_with(route_list, "Try next:")
	_expect(result_why_note != null, "result screen did not add why note")
	_expect(result_try_note != null, "result screen did not add try-next note")
	if result_why_note != null:
		_expect(result_why_note.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART, "result why note should wrap on mobile")
		_expect(result_why_note.size_flags_horizontal == Control.SIZE_EXPAND_FILL, "result why note should fill available width")
	if result_try_note != null:
		_expect(result_try_note.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART, "result try-next note should wrap on mobile")
		_expect(result_try_note.size_flags_horizontal == Control.SIZE_EXPAND_FILL, "result try-next note should fill available width")

	PlatformProfile.is_mobile = original_mobile
	GameState.meta_progress["unlocked_operations"] = original_unlocked
	GameState.meta_progress["operation_records"] = original_records
	GameState.run_success = original_run_success
	GameState.is_run_failed = original_run_failed
	GameState.elapsed_time = original_elapsed
	GameState.combo_count = original_combo
	GameState.health = original_health
	GameState.extraction_unlocked = original_extraction_unlocked
	GameState.extraction_bonus_active = original_extraction_active
	GameState.extraction_bonus_label = original_extraction_label
	GameState.extraction_unlock_time = original_extraction_unlock_time
	GameState.pending_extraction_bonus = original_pending_bonus
	GameState.extraction_bonus_kills = original_extraction_kills
	GameState.set_live_route_status(original_route_phase, original_route_pressure, original_hazard_status)
	GameState.set_master_volume(original_volume, false)
	GameState.set_haptics_enabled(original_haptics, false)
	screen.queue_free()

	if failures.is_empty():
		print("Pause settings regression passed.")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _find_first_child_of_type(root: Node, type_hint: Variant) -> Node:
	for child in root.get_children():
		if is_instance_of(child, type_hint):
			return child
		var nested := _find_first_child_of_type(child, type_hint)
		if nested != null:
			return nested
	return null


func _find_label_starting_with(root: Node, prefix: String) -> Label:
	for child in root.get_children():
		if child is Label and String((child as Label).text).begins_with(prefix):
			return child as Label
		var nested := _find_label_starting_with(child, prefix)
		if nested != null:
			return nested
	return null


func _find_directive(operation: Dictionary, directive_id: String) -> Dictionary:
	for directive in operation.get("directive_pool", []):
		if String(directive.get("id", "")) == directive_id:
			return directive
	return {}


func _verify_directive_button_state(screen: Node, operation: Dictionary, next_directive: Dictionary) -> void:
	var first_directive: Dictionary = operation.get("directive_pool", [])[0]
	screen.call("_clear_directive_list")
	screen.call("_add_directive_button", operation, first_directive, true)
	screen.call("_add_directive_button", operation, next_directive, false)
	var buttons: Dictionary = screen.get("directive_buttons")
	var first_button := buttons.get(String(first_directive.get("id", ""))) as Button
	var next_button := buttons.get(String(next_directive.get("id", ""))) as Button
	_expect(first_button != null, "first directive button was not registered")
	_expect(next_button != null, "next directive button was not registered")
	if first_button == null or next_button == null:
		return
	_expect(first_button.text.begins_with("ACTIVE"), "initial directive button should show active state")
	_expect(next_button.text.begins_with("OPTION"), "inactive directive button should show option state")
	screen.call("_set_directive_button_state", first_button, first_directive, false)
	screen.call("_set_directive_button_state", next_button, next_directive, true)
	_expect(first_button.text.begins_with("OPTION"), "previous directive button should update to option state")
	_expect(next_button.text.begins_with("ACTIVE"), "selected directive button should update to active state")
	_expect(next_button.text.contains("COMBO +25%"), "selected directive button should keep modifier text")


func _verify_route_button_state(screen: Node, active_operation: Dictionary, locked_operation: Dictionary) -> void:
	var active_button := Button.new()
	var ready_button := Button.new()
	var locked_button := Button.new()
	screen.call("_set_route_button_state", active_button, active_operation, true)
	screen.call("_set_route_button_state", ready_button, active_operation, false)
	screen.call("_set_route_button_state", locked_button, locked_operation, false)
	_expect(active_button.text.begins_with("ACTIVE"), "selected route button should show active state")
	_expect(active_button.button_pressed, "selected route button should be pressed")
	_expect(active_button.text.contains("BEST 1780 // RANK A"), "mobile selected route button should show compact score and rank record")
	_expect(active_button.text.contains("TIME 01:12 // RUNS 3"), "mobile selected route button should show best clear time and run count")
	_expect(active_button.custom_minimum_size.y >= 124.0, "mobile selected route button should reserve height for two-line records")
	_expect(ready_button.text.begins_with("READY"), "available unselected route button should show ready state")
	_expect(not ready_button.button_pressed, "available unselected route button should not be pressed")
	_expect(ready_button.text.contains("BEST 1780 // RANK A"), "mobile ready route button should keep compact score and rank record")
	_expect(ready_button.text.contains("TIME 01:12 // RUNS 3"), "mobile ready route button should keep best clear time and run count")
	_expect(locked_button.text.begins_with("LOCKED"), "locked route button should show locked state")
	_expect(locked_button.disabled, "locked route button should be disabled")
	_expect(locked_button.text.contains("TIME -- // RUNS 0"), "locked route button should not fake a best clear time")
	_expect(locked_button.custom_minimum_size.y >= 146.0, "mobile locked route button should reserve height for records plus lock copy")
	active_button.queue_free()
	ready_button.queue_free()
	locked_button.queue_free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
