extends Node

## 验证路线几何只来自 RunCatalog 的 route data，World 不继承隐藏静态平台。
## 改 scenes/game/world.tscn 或 data/run_operations.tres 后先跑本场景。

const WORLD_SCENE := preload("res://scenes/game/world.tscn")
const EXPECTED_OPERATION_IDS := ["blitz_pursuit", "ghost_circuit", "overdrive_protocol"]

var failures: Array[String] = []


func _ready() -> void:
	await _verify_route_geometry()
	if failures.is_empty():
		print("Route geometry regression passed.")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _verify_route_geometry() -> void:
	var operations := RunCatalog.shared().get_operations()
	_expect(operations.size() == EXPECTED_OPERATION_IDS.size(), "route data contains exactly three operations")

	for operation_id in EXPECTED_OPERATION_IDS:
		var operation := RunCatalog.shared().get_operation(operation_id)
		_expect(not operation.is_empty(), "%s exists in route data" % operation_id)
		if operation.is_empty():
			continue
		var platform_data: Array = operation.get("platforms", [])
		_expect(not platform_data.is_empty(), "%s has route platform data" % operation_id)
		await _verify_operation_geometry(operation_id, operation, platform_data)


func _verify_operation_geometry(operation_id: String, operation: Dictionary, platform_data: Array) -> void:
	var world := WORLD_SCENE.instantiate()
	add_child(world)
	await get_tree().process_frame

	var geometry: Node = world.get_node("Geometry")
	var static_children_before_begin := _get_static_children(geometry)
	_expect(static_children_before_begin.is_empty(),
		"%s starts without hidden static Geometry platforms" % operation_id)

	world.set("active_operation", operation)
	world.call("_build_platforms")
	await get_tree().process_frame

	var route_platforms := _get_route_platforms(geometry)
	_expect(route_platforms.size() == platform_data.size(),
		"%s dynamically assembles exactly %d route platforms" % [operation_id, platform_data.size()])
	_expect(_get_static_children(geometry).size() == platform_data.size(),
		"%s has no non-route StaticBody2D under Geometry after assembly" % operation_id)

	var compare_count := mini(route_platforms.size(), platform_data.size())
	for index in compare_count:
		var platform: StaticBody2D = route_platforms[index]
		var expected: Dictionary = platform_data[index]
		var expected_position := Vector2(expected.get("position", Vector2.ZERO))
		_expect(platform.position.is_equal_approx(expected_position),
			"%s platform %d position matches route data" % [operation_id, index])

		var collision: CollisionShape2D = null
		for child in platform.get_children():
			if child is CollisionShape2D:
				collision = child as CollisionShape2D
				break
		_expect(collision != null and collision.shape is RectangleShape2D,
			"%s platform %d has a rectangle collision" % [operation_id, index])
		if collision != null and collision.shape is RectangleShape2D:
			var expected_size := Vector2(expected.get("size", Vector2.ZERO))
			_expect((collision.shape as RectangleShape2D).size.is_equal_approx(expected_size),
				"%s platform %d collision size matches route data" % [operation_id, index])

	world.queue_free()
	await get_tree().process_frame


func _get_static_children(parent: Node) -> Array[StaticBody2D]:
	var result: Array[StaticBody2D] = []
	for child in parent.get_children():
		if child is StaticBody2D:
			result.append(child as StaticBody2D)
	return result


func _get_route_platforms(parent: Node) -> Array[StaticBody2D]:
	var result: Array[StaticBody2D] = []
	for child in parent.get_children():
		if child is StaticBody2D and child.is_in_group("platform"):
			result.append(child as StaticBody2D)
	return result


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
