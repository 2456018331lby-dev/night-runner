extends Node

const RunCatalogScript := preload("res://scripts/game/run_catalog.gd")

const KIND_BY_SCENE_PATH := {
	"res://scenes/actors/enemy_runner.tscn": "runner",
	"res://scenes/actors/enemy_suppressor.tscn": "suppressor",
	"res://scenes/actors/enemy_bastion.tscn": "bastion",
	"res://scenes/actors/enemy_phantom.tscn": "phantom",
	"res://scenes/actors/enemy_stalker.tscn": "stalker",
}

const CONTROL_KINDS := ["suppressor", "bastion", "stalker"]
const PAIR_LIMITS := {
	"bastion|stalker": Vector2(220.0, 150.0),
	"bastion|suppressor": Vector2(220.0, 125.0),
	"stalker|suppressor": Vector2(260.0, 135.0),
}
const COMPRESSED_CONTROL_COUNT := 3
const COMPRESSED_CONTROL_SPAN := Vector2(540.0, 220.0)

var failures: Array[String] = []


func _ready() -> void:
	for operation in RunCatalogScript.get_operations():
		var operation_id := String(operation.get("id", "unknown_operation"))
		_verify_operation_phase_profile(operation_id, operation)
		_scan_bucket(operation_id, "initial encounters", operation.get("encounters", []))
		_scan_event_array(operation_id, "timeline", operation.get("timeline_events", []))
		_scan_event_array(operation_id, "core", operation.get("core_events", []))
		_scan_bucket(operation_id, "completion", operation.get("completion_spawns", []))
		_scan_event_array(operation_id, "cashout", operation.get("cashout_events", []))
		var setpiece: Dictionary = operation.get("phase_setpiece", {})
		if not setpiece.is_empty():
			_scan_bucket(operation_id, "phase_setpiece", setpiece.get("spawn", []))

	if failures.is_empty():
		print("Encounter pressure regression passed.")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _scan_event_array(operation_id: String, label: String, events: Array) -> void:
	for index in events.size():
		var event: Dictionary = events[index]
		_scan_bucket(operation_id, "%s_%d" % [label, index], event.get("spawn", []))


func _verify_operation_phase_profile(operation_id: String, operation: Dictionary) -> void:
	_expect(Array(operation.get("lane_signals", [])).size() >= 2, "%s keeps at least two route identity signals" % operation_id)
	_expect(Array(operation.get("timeline_events", [])).size() >= 2, "%s keeps multiple time-based phase events" % operation_id)
	_expect(Array(operation.get("core_events", [])).size() >= 2, "%s keeps multiple core-triggered phase events" % operation_id)
	_expect(Array(operation.get("cashout_events", [])).size() >= 2, "%s keeps multiple cashout escalation events" % operation_id)
	var setpiece: Dictionary = operation.get("phase_setpiece", {})
	_expect(not setpiece.is_empty(), "%s has a named phase setpiece" % operation_id)
	if setpiece.is_empty():
		return
	_expect(not String(setpiece.get("trigger", "")).is_empty(), "%s phase setpiece has a trigger" % operation_id)
	_expect(not String(setpiece.get("label", "")).is_empty(), "%s phase setpiece has a label" % operation_id)
	_expect(not String(setpiece.get("toast", "")).is_empty(), "%s phase setpiece has a player-facing toast" % operation_id)
	_expect(not String(setpiece.get("pressure_text", "")).is_empty(), "%s phase setpiece updates route pressure text" % operation_id)
	_expect(Array(setpiece.get("spawn", [])).size() >= 2, "%s phase setpiece has enough encounter texture" % operation_id)


func _scan_bucket(operation_id: String, label: String, spawn_list: Array) -> void:
	var entries: Array[Dictionary] = []
	for spawn_data in spawn_list:
		var entry := _build_spawn_entry(spawn_data)
		if entry.is_empty():
			continue
		entries.append(entry)

	for left_index in entries.size():
		for right_index in range(left_index + 1, entries.size()):
			_check_pair(operation_id, label, entries[left_index], entries[right_index])
	_check_compressed_controls(operation_id, label, entries)


func _build_spawn_entry(spawn_data: Dictionary) -> Dictionary:
	var scene: PackedScene = spawn_data.get("scene")
	if scene == null:
		failures.append("Spawn entry is missing a scene.")
		return {}
	var kind := String(KIND_BY_SCENE_PATH.get(scene.resource_path, ""))
	if kind.is_empty():
		failures.append("Spawn entry uses unknown enemy scene: %s" % scene.resource_path)
		return {}
	return {
		"kind": kind,
		"position": Vector2(spawn_data.get("position", Vector2.ZERO)),
		"scene_path": scene.resource_path,
	}


func _check_pair(operation_id: String, label: String, left: Dictionary, right: Dictionary) -> void:
	var limit := _get_pair_limit(String(left["kind"]), String(right["kind"]))
	if limit == Vector2.ZERO:
		return
	var left_position: Vector2 = left["position"]
	var right_position: Vector2 = right["position"]
	var delta := (right_position - left_position).abs()
	if delta.x < limit.x and delta.y < limit.y:
		failures.append(
			"%s %s stacks %s at %s with %s at %s inside %.0fx%.0f pressure budget." % [
				operation_id,
				label,
				left["kind"],
				_format_position(left_position),
				right["kind"],
				_format_position(right_position),
				limit.x,
				limit.y,
			]
		)


func _get_pair_limit(left_kind: String, right_kind: String) -> Vector2:
	var pair := [left_kind, right_kind]
	pair.sort()
	return Vector2(PAIR_LIMITS.get("%s|%s" % [pair[0], pair[1]], Vector2.ZERO))


func _check_compressed_controls(operation_id: String, label: String, entries: Array[Dictionary]) -> void:
	var control_count := 0
	var min_position := Vector2(INF, INF)
	var max_position := Vector2(-INF, -INF)
	for entry in entries:
		if not CONTROL_KINDS.has(String(entry["kind"])):
			continue
		control_count += 1
		var position: Vector2 = entry["position"]
		min_position.x = minf(min_position.x, position.x)
		min_position.y = minf(min_position.y, position.y)
		max_position.x = maxf(max_position.x, position.x)
		max_position.y = maxf(max_position.y, position.y)
	if control_count < COMPRESSED_CONTROL_COUNT:
		return
	var span := max_position - min_position
	if span.x < COMPRESSED_CONTROL_SPAN.x and span.y < COMPRESSED_CONTROL_SPAN.y:
		failures.append(
			"%s %s compresses %d control enemies into %.0fx%.0f px; spread one into another lane or convert it to runner pressure." % [
				operation_id,
				label,
				control_count,
				span.x,
				span.y,
			]
		)


func _format_position(position: Vector2) -> String:
	return "(%d,%d)" % [int(position.x), int(position.y)]


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
