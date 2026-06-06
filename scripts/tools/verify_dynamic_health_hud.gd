extends Node

const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const PIP_ROW_PATH := NodePath("MarginContainer/RootColumn/TopRow/TelemetryCard/Margin/VBox/HealthRow/PipRow")

var failures: Array[String] = []


func _ready() -> void:
	var original_health := GameState.health
	var original_modifiers := GameState.run_modifiers.duplicate(true)
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

	GameState.health = original_health
	GameState.run_modifiers = original_modifiers
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
