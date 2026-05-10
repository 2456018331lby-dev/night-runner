extends Node2D

const DATA_CORE_SCENE := preload("res://scenes/game/data_core.tscn")
const BOOST_PAD_SCENE := preload("res://scenes/game/boost_pad.tscn")

@onready var presentation: Node2D = $Presentation
@onready var ground_container: Node2D = $Geometry
@onready var player: Node = $Player
@onready var enemy_container: Node2D = $Enemies
@onready var data_core_container: Node2D = $DataCores
@onready var boost_pad_container: Node2D = $BoostPads
@onready var extraction_gate: Area2D = $ExtractionGate
@onready var hud: CanvasLayer = $HUD
@onready var touch_controls: CanvasLayer = $TouchControls

var active_operation: Dictionary = {}
var current_objective: String = ""
var reinforcements_spawned: bool = false
var triggered_timeline_events: Dictionary = {}
var triggered_core_events: Dictionary = {}
var generated_platforms: Array[Node2D] = []


func _ready() -> void:
	GameState.run_failed.connect(_on_run_failed)
	GameState.run_finished.connect(_on_run_finished)
	GameState.state_changed.connect(_on_state_changed)
	player.player_fell.connect(_on_player_fell)
	player.player_hit.connect(_on_player_hit)
	extraction_gate.extraction_entered.connect(_on_extraction_entered)
	extraction_gate.extraction_blocked.connect(_on_extraction_blocked)
	configure_touch_controls()


func configure_touch_controls() -> void:
	if touch_controls.has_method("configure"):
		touch_controls.call("configure", PlatformProfile.should_show_touch_controls())


func begin(operation: Dictionary) -> void:
	reset_world()
	active_operation = operation.duplicate(true)
	reinforcements_spawned = false
	triggered_timeline_events.clear()
	triggered_core_events.clear()
	_build_platforms()
	_apply_operation_theme()
	_position_player()
	_spawn_initial_encounters()
	GameState.set_data_core_total(_get_data_core_positions().size())
	for core_position in _get_data_core_positions():
		_spawn_data_core(core_position)
	for pad_setup in _get_boost_pads():
		_spawn_boost_pad(pad_setup["position"], pad_setup["boost_velocity"])
	if extraction_gate.has_method("set_unlocked"):
		extraction_gate.call("set_unlocked", false)
	extraction_gate.global_position = Vector2(active_operation.get("extraction_position", Vector2(2124, 128)))
	_set_objective(String(active_operation.get("objective_intro", "Steal the data cores and extract.")))
	_show_toast(String(active_operation.get("intro_toast", "Route live.")), 3.0)
	if hud.has_method("set_operation_context"):
		hud.call("set_operation_context", active_operation, GameState.current_directive)


func reset_world() -> void:
	for node in enemy_container.get_children():
		node.queue_free()
	for node in data_core_container.get_children():
		node.queue_free()
	for node in boost_pad_container.get_children():
		node.queue_free()
	for platform in generated_platforms:
		if is_instance_valid(platform):
			platform.queue_free()
	generated_platforms.clear()
	active_operation.clear()
	current_objective = ""
	if hud.has_method("set_operation_context"):
		hud.call("set_operation_context", {}, {})
	if hud.has_method("set_objective"):
		hud.call("set_objective", "")


func _process(_delta: float) -> void:
	if not GameState.is_run_active or GameState.is_run_failed:
		return
	_check_timeline_events()


func _spawn_initial_encounters() -> void:
	for setup in active_operation.get("encounters", []):
		_spawn_enemy(setup["scene"], setup["position"])


func _build_platforms() -> void:
	for platform_data in active_operation.get("platforms", []):
		var static_body := StaticBody2D.new()
		static_body.collision_layer = 4
		static_body.collision_mask = 0
		static_body.position = platform_data["position"]
		var shape := RectangleShape2D.new()
		shape.size = platform_data["size"]
		var collider := CollisionShape2D.new()
		collider.shape = shape
		static_body.add_child(collider)
		var visual := Polygon2D.new()
		var half: Vector2 = shape.size * 0.5
		visual.polygon = PackedVector2Array([
			Vector2(-half.x, -half.y),
			Vector2(half.x, -half.y),
			Vector2(half.x, half.y),
			Vector2(-half.x, half.y),
		])
		visual.color = platform_data["color"]
		static_body.add_child(visual)
		ground_container.add_child(static_body)
		generated_platforms.append(static_body)


func _position_player() -> void:
	player.global_position = Vector2(active_operation.get("spawn_position", Vector2(140, 590)))
	player.velocity = Vector2.ZERO


func _apply_operation_theme() -> void:
	var theme: Dictionary = active_operation.get("theme", {})
	if presentation.has_method("set_theme"):
		presentation.call("set_theme", theme)


func _spawn_enemy(scene: PackedScene, at_position: Vector2) -> void:
	var enemy: Node2D = scene.instantiate() as Node2D
	if enemy == null:
		return
	enemy.global_position = at_position
	enemy.set("player", player)
	if enemy.has_signal("defeated"):
		enemy.connect("defeated", Callable(self, "_on_enemy_defeated"))
	enemy_container.add_child(enemy)


func _spawn_data_core(at_position: Vector2) -> void:
	var core: Area2D = DATA_CORE_SCENE.instantiate() as Area2D
	if core == null:
		return
	core.global_position = at_position
	core.collected.connect(_on_data_core_collected)
	data_core_container.add_child(core)


func _spawn_boost_pad(at_position: Vector2, boost_velocity: Vector2) -> void:
	var pad: Area2D = BOOST_PAD_SCENE.instantiate() as Area2D
	if pad == null:
		return
	pad.global_position = at_position
	pad.set("boost_velocity", boost_velocity * GameState.get_modifier_value("boost_multiplier", 1.0))
	boost_pad_container.add_child(pad)


func _check_timeline_events() -> void:
	var events: Array = active_operation.get("timeline_events", [])
	for index in events.size():
		if triggered_timeline_events.get(index, false):
			continue
		var event: Dictionary = events[index]
		if GameState.elapsed_time < float(event.get("time", 0.0)):
			continue
		triggered_timeline_events[index] = true
		_trigger_spawn_event(event)


func _check_core_events() -> void:
	var events: Array = active_operation.get("core_events", [])
	for index in events.size():
		if triggered_core_events.get(index, false):
			continue
		var event: Dictionary = events[index]
		if GameState.data_cores_collected < int(event.get("count", 0)):
			continue
		triggered_core_events[index] = true
		_trigger_spawn_event(event)


func _trigger_spawn_event(event: Dictionary) -> void:
	for spawn_data in event.get("spawn", []):
		_spawn_enemy(spawn_data["scene"], spawn_data["position"])
	var toast := String(event.get("toast", ""))
	if not toast.is_empty():
		_show_toast(toast, 2.4)


func _spawn_completion_wave() -> void:
	if reinforcements_spawned:
		return
	reinforcements_spawned = true
	for spawn_data in active_operation.get("completion_spawns", []):
		_spawn_enemy(spawn_data["scene"], spawn_data["position"])


func _on_enemy_defeated(points: int) -> void:
	GameState.register_enemy_defeat(points)
	if GameState.combo_count >= 3:
		_show_toast("Combo x%d. Keep pressure for bonus score." % GameState.combo_count, 1.6)


func _on_player_hit() -> void:
	GameState.lose_health(1)
	_show_toast("Hit taken. Protect your health for the extraction payout.", 1.8)


func _on_player_fell() -> void:
	GameState.set_result("FAIL", "Route collapse. Re-enter the operation from hub or retry immediately.")
	GameState.finish_run(false)
	_set_objective("Route failed. Rebuild your line and try again.")
	_show_toast("You lost the rooftop route.", 2.0)


func _on_run_failed() -> void:
	_set_objective("Operation failed.")


func _on_run_finished(success: bool) -> void:
	if success:
		_set_objective("Extraction complete. The dossier has been archived.")
		_show_toast(GameState.result_summary, 3.0)


func _on_data_core_collected() -> void:
	GameState.collect_data_core(250)
	_check_core_events()
	var remaining := GameState.data_cores_total - GameState.data_cores_collected
	if remaining > 0:
		_set_objective("Secure the remaining %d data core(s)." % remaining)
		_show_toast("Core secured. Keep the route alive.", 1.9)
		return
	if extraction_gate.has_method("set_unlocked"):
		extraction_gate.call("set_unlocked", true)
	_spawn_completion_wave()
	_set_objective(String(active_operation.get("objective_complete", "Extraction is now available.")))
	_show_toast(String(active_operation.get("completion_toast", "Extraction route is live.")), 2.5)


func _on_extraction_blocked() -> void:
	var remaining := GameState.data_cores_total - GameState.data_cores_collected
	var default_text := "Extraction locked. %d more data core(s) needed." % remaining
	var operation_text := String(active_operation.get("block_toast", default_text))
	if operation_text.contains("%d"):
		operation_text = operation_text % remaining
	_show_toast(operation_text, 1.9)


func _on_extraction_entered() -> void:
	if GameState.is_run_failed or GameState.run_success:
		return
	var finish_bonus: int = GameState.health * 120 + max(0, 420 - int(GameState.elapsed_time * 18.0))
	finish_bonus = int(round(float(finish_bonus) * GameState.get_modifier_value("finish_bonus_multiplier", 1.0)))
	if GameState.health == max(1, 3 + int(GameState.run_modifiers.get("health_bonus", 0))):
		finish_bonus += int(GameState.run_modifiers.get("silent_bonus", 0))
	GameState.add_score(finish_bonus)
	var rank := _calculate_rank()
	var summary := "Rank %s // Score %04d // Directive %s" % [
		rank,
		GameState.score,
		GameState.get_current_directive_name() if not GameState.get_current_directive_name().is_empty() else "Base Protocol",
	]
	GameState.set_result(rank, summary)
	GameState.finish_run(true)


func _calculate_rank() -> String:
	if GameState.score >= 2900:
		return "S"
	if GameState.score >= 2250:
		return "A"
	if GameState.score >= 1700:
		return "B"
	if GameState.score >= 1150:
		return "C"
	return "D"


func _on_state_changed() -> void:
	if hud.has_method("set_objective"):
		hud.call("set_objective", current_objective)


func _set_objective(text: String) -> void:
	if current_objective == text:
		return
	current_objective = text
	if hud.has_method("set_objective"):
		hud.call("set_objective", text)


func _show_toast(text: String, duration: float = 2.3) -> void:
	if hud.has_method("show_toast"):
		hud.call("show_toast", text, duration)


func _get_data_core_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for value in active_operation.get("data_cores", []):
		positions.append(value)
	return positions


func _get_boost_pads() -> Array[Dictionary]:
	var pads: Array[Dictionary] = []
	for value in active_operation.get("boost_pads", []):
		pads.append(value)
	return pads
