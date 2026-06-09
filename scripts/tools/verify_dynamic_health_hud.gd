extends Node

const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const PIP_ROW_PATH := NodePath("MarginContainer/RootColumn/TopRow/TelemetryCard/Margin/VBox/HealthRow/PipRow")
const PHASE_CARD_PATH := NodePath("MarginContainer/RootColumn/ObjectiveRow/PhaseCard")
const NAV_CARD_PATH := NodePath("MarginContainer/RootColumn/CashoutRow/NavCard")
const NAV_STATUS_PATH := NodePath("MarginContainer/RootColumn/CashoutRow/NavCard/Margin/VBox/NavStatus")

var failures: Array[String] = []


func _ready() -> void:
	var original_health := GameState.health
	var original_modifiers := GameState.run_modifiers.duplicate(true)
	var original_mobile := PlatformProfile.is_mobile
	var original_run_success := GameState.run_success
	var original_run_failed := GameState.is_run_failed
	var original_secondary := GameState.current_secondary_objective.duplicate(true)
	var original_elapsed := GameState.elapsed_time
	var original_phase := GameState.get_route_phase_text()
	var original_pressure := GameState.get_route_pressure_text()
	var original_hazard := GameState.get_hazard_status_text()
	var hud := HUD_SCENE.instantiate()
	add_child(hud)
	await get_tree().process_frame

	_set_health_state(5, 2)
	await get_tree().process_frame
	_expect_pip_count(hud, 5, "positive health modifier creates extra HUD pips")

	_set_health_state(2, -1)
	await get_tree().process_frame
	_expect_pip_count(hud, 2, "negative health modifier shrinks HUD pips without stale children")

	_set_health_state(1, -5)
	await get_tree().process_frame
	_expect_pip_count(hud, 1, "health display keeps at least one pip")

	PlatformProfile.is_mobile = true
	GameState.run_success = false
	GameState.is_run_failed = false
	GameState.current_secondary_objective = {
		"name": "Shock Exit",
		"type": "time_limit",
		"target_time": 58.0,
	}
	GameState.elapsed_time = 42.0
	GameState.set_live_route_status("BREACH", "Relay Bloom. Suppressor geometry is live.", "Hazard net dormant.")
	hud.call("set_navigation_target", "data core", 180.0, Vector2(1.0, -0.2), true)
	await get_tree().process_frame
	_expect_mobile_nav_pressure(hud)

	GameState.health = original_health
	GameState.run_modifiers = original_modifiers
	GameState.run_success = original_run_success
	GameState.is_run_failed = original_run_failed
	GameState.current_secondary_objective = original_secondary
	GameState.elapsed_time = original_elapsed
	GameState.set_live_route_status(original_phase, original_pressure, original_hazard)
	PlatformProfile.is_mobile = original_mobile
	GameState.state_changed.emit()
	hud.queue_free()

	if failures.is_empty():
		print("Dynamic health HUD regression passed.")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _set_health_state(health_value: int, health_bonus: int) -> void:
	GameState.health = health_value
	GameState.run_modifiers = {"health_bonus": health_bonus}
	GameState.state_changed.emit()


func _expect_pip_count(hud: CanvasLayer, expected: int, label: String) -> void:
	var pip_row := hud.get_node(PIP_ROW_PATH) as HBoxContainer
	var internal_pips: Array = hud.get("health_pips")
	var actual := pip_row.get_child_count()
	if actual != expected:
		failures.append("%s: expected %d pip nodes, got %d" % [label, expected, actual])
	if internal_pips.size() != expected:
		failures.append("%s: expected %d tracked pips, got %d" % [label, expected, internal_pips.size()])


func _expect_mobile_nav_pressure(hud: CanvasLayer) -> void:
	var phase_card := hud.get_node(PHASE_CARD_PATH) as PanelContainer
	var nav_card := hud.get_node(NAV_CARD_PATH) as PanelContainer
	var nav_status := hud.get_node(NAV_STATUS_PATH) as Label
	if phase_card.visible:
		failures.append("mobile HUD should keep the phase card hidden for density")
	if not nav_card.visible:
		failures.append("mobile HUD should keep navigation card visible while tracking")
	if not nav_status.text.contains("DATA CORE"):
		failures.append("mobile navigation card lost the route vector label")
	if not nav_status.text.contains("Relay Bloom"):
		failures.append("mobile navigation card lost route pressure text while phase card is hidden")
	if not nav_status.text.contains("OPT "):
		failures.append("mobile navigation card should carry optional objective status while secondary card is hidden")
	if not nav_status.text.contains("00:16 LEFT"):
		failures.append("mobile navigation card lost compact optional objective remaining-time status")
	if nav_status.text.contains("Extract before"):
		failures.append("mobile navigation card should use compact optional objective copy")
