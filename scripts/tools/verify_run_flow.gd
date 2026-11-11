extends Node

## End-to-end smoke test for the shipping run loop.
## It exercises each formal operation through route assembly, core completion,
## extraction unlock and successful finish while restoring the user's save state.

const WORLD_SCENE := preload("res://scenes/game/world.tscn")
const EXPECTED_OPERATION_IDS := ["blitz_pursuit", "ghost_circuit", "overdrive_protocol"]

var failures: Array[String] = []
var save_existed := false
var save_contents := ""
var meta_snapshot: Dictionary = {}


func _ready() -> void:
	_snapshot_persistent_state()
	await _run_all_operations()
	_restore_persistent_state()
	if failures.is_empty():
		print("Run flow regression passed.")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _run_all_operations() -> void:
	var catalog := RunCatalog.shared()
	for operation_id in EXPECTED_OPERATION_IDS:
		var operation := catalog.get_operation(operation_id)
		_expect(not operation.is_empty(), "%s exists for run flow" % operation_id)
		if operation.is_empty():
			continue
		var directive := FrontendBridge.get_selected_directive(operation_id)
		if directive.is_empty():
			var pool: Array = operation.get("directive_pool", [])
			if not pool.is_empty():
				directive = Dictionary(pool[0]).duplicate(true)
		await _run_operation(operation, directive)


func _run_operation(operation: Dictionary, directive: Dictionary) -> void:
	GameState.start_run(operation, directive)
	var world := WORLD_SCENE.instantiate()
	add_child(world)
	await get_tree().process_frame
	world.call("begin", operation)
	await get_tree().process_frame
	await get_tree().process_frame

	var operation_id := String(operation.get("id", ""))
	_expect(GameState.is_run_active, "%s starts an active run" % operation_id)
	_expect(GameState.data_cores_total == Array(operation.get("data_cores", [])).size(), "%s core total matches route data" % operation_id)
	_expect(world.get_node("Geometry").get_child_count() == Array(operation.get("platforms", [])).size() + 2, "%s assembles route geometry and reference effects" % operation_id)
	_expect(world.get_node("DataCores").get_child_count() == GameState.data_cores_total, "%s spawns every data core" % operation_id)
	_verify_hazard_assembly(world, operation)

	var cores := world.get_node("DataCores").get_children()
	for core in cores:
		world.call("_on_data_core_collected", core)
	await get_tree().process_frame
	_expect(GameState.extraction_unlocked, "%s unlocks extraction after all cores" % operation_id)
	_expect(GameState.data_cores_collected == GameState.data_cores_total, "%s records every collected core" % operation_id)

	world.call("_update_hazard_states")
	for hazard in world.get_node("Hazards").get_children():
		var activation := String(Dictionary(hazard.get("setup")).get("activate_on", "always"))
		if activation == "always" or activation.begins_with("core_"):
			_expect(bool(hazard.get("stage_enabled")), "%s enables %s hazards after core completion" % [operation_id, String(hazard.get("hazard_id"))])

	world.call("_on_extraction_entered")
	await get_tree().process_frame
	_expect(GameState.run_success, "%s completes through extraction" % operation_id)
	_expect(not GameState.is_run_active, "%s closes the run exactly once" % operation_id)

	world.call("reset_world")
	world.queue_free()
	await get_tree().process_frame


func _verify_hazard_assembly(world: Node, operation: Dictionary) -> void:
	var expected_hazards: Array = operation.get("hazards", [])
	var hazards := world.get_node("Hazards").get_children()
	var operation_id := String(operation.get("id", ""))
	_expect(hazards.size() == expected_hazards.size(), "%s spawns every configured route hazard" % operation_id)
	for index in mini(hazards.size(), expected_hazards.size()):
		var hazard: Node = hazards[index]
		var expected: Dictionary = expected_hazards[index]
		var collision_shape := hazard.get_node_or_null("CollisionShape2D") as CollisionShape2D
		var rectangle := collision_shape.shape as RectangleShape2D if collision_shape != null else null
		var beam := hazard.get_node_or_null("Beam") as Polygon2D
		var halo := hazard.get_node_or_null("Halo") as Polygon2D
		_expect(bool(hazard.get("configured")), "%s configures hazard %s after entering the scene tree" % [operation_id, String(expected.get("id", index))])
		_expect(rectangle != null, "%s creates a collision shape for hazard %s" % [operation_id, String(expected.get("id", index))])
		if rectangle != null:
			var expected_size := Vector2(expected.get("size", Vector2(120.0, 18.0)))
			if String(expected.get("type", "pulse_beam")) == "collapse_zone":
				expected_size *= Vector2(0.92, 0.86)
			_expect(rectangle.size.is_equal_approx(expected_size), "%s collision size matches hazard %s" % [operation_id, String(expected.get("id", index))])
		_expect(beam != null and beam.polygon.size() >= 4, "%s builds visual beam geometry for hazard %s" % [operation_id, String(expected.get("id", index))])
		_expect(halo != null and halo.polygon.size() >= 4, "%s builds warning halo geometry for hazard %s" % [operation_id, String(expected.get("id", index))])


func _snapshot_persistent_state() -> void:
	meta_snapshot = GameState.meta_progress.duplicate(true)
	var path := ProjectSettings.globalize_path(GameState.SAVE_PATH)
	save_existed = FileAccess.file_exists(GameState.SAVE_PATH)
	if save_existed:
		var file := FileAccess.open(GameState.SAVE_PATH, FileAccess.READ)
		if file != null:
			save_contents = file.get_as_text()


func _restore_persistent_state() -> void:
	GameState.meta_progress = meta_snapshot.duplicate(true)
	var path := ProjectSettings.globalize_path(GameState.SAVE_PATH)
	if save_existed:
		var file := FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
		if file != null:
			file.store_string(save_contents)
	else:
		if FileAccess.file_exists(GameState.SAVE_PATH):
			DirAccess.remove_absolute(path)
	GameState.is_run_active = false
	GameState.is_run_failed = false
	GameState.run_success = false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
