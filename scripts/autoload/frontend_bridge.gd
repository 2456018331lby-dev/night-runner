extends Node

signal bootstrapped
signal phase_changed(phase: String)
signal operation_selected(operation_id: String)
signal start_requested(operation_id: String)
signal retry_requested(operation_id: String)
signal return_to_hub_requested
signal pause_state_changed(paused: bool)

const RunCatalog := preload("res://scripts/game/run_catalog.gd")

const PHASE_HUB := "hub"
const PHASE_RUN := "run"
const PHASE_RESULTS := "results"
const PHASE_PAUSE := "pause"

var app_phase: String = PHASE_HUB
var previous_phase: String = PHASE_HUB
var selected_operation_id: String = ""
var operations: Array[Dictionary] = []


func bootstrap() -> void:
	operations = RunCatalog.get_operations()
	if operations.is_empty():
		selected_operation_id = ""
		bootstrapped.emit()
		return
	var remembered_id := String(GameState.meta_progress.get("selected_operation_id", ""))
	if remembered_id.is_empty() or not GameState.is_operation_unlocked(remembered_id):
		remembered_id = _get_first_unlocked_operation_id()
	selected_operation_id = remembered_id
	app_phase = PHASE_HUB
	phase_changed.emit(app_phase)
	operation_selected.emit(selected_operation_id)
	bootstrapped.emit()


func get_operations() -> Array[Dictionary]:
	return operations.duplicate(true)


func get_selected_operation() -> Dictionary:
	return get_operation(selected_operation_id)


func get_operation(operation_id: String) -> Dictionary:
	for operation in operations:
		if String(operation.get("id", "")) == operation_id:
			return operation.duplicate(true)
	return {}


func select_operation(operation_id: String) -> void:
	if operation_id.is_empty():
		return
	selected_operation_id = operation_id
	GameState.meta_progress["selected_operation_id"] = selected_operation_id
	GameState.save_progress()
	operation_selected.emit(selected_operation_id)


func request_start_selected_operation() -> void:
	if selected_operation_id.is_empty() or not GameState.is_operation_unlocked(selected_operation_id):
		return
	start_requested.emit(selected_operation_id)


func request_retry_current_operation() -> void:
	if GameState.current_operation_id.is_empty():
		request_start_selected_operation()
		return
	retry_requested.emit(GameState.current_operation_id)


func request_return_to_hub() -> void:
	set_phase(PHASE_HUB)
	return_to_hub_requested.emit()


func set_phase(phase: String) -> void:
	if app_phase == phase:
		return
	previous_phase = app_phase
	app_phase = phase
	phase_changed.emit(app_phase)


func set_results_phase() -> void:
	set_phase(PHASE_RESULTS)
	pause_state_changed.emit(false)


func toggle_pause() -> void:
	if app_phase == PHASE_RUN:
		set_phase(PHASE_PAUSE)
		pause_state_changed.emit(true)
	elif app_phase == PHASE_PAUSE:
		set_phase(PHASE_RUN)
		pause_state_changed.emit(false)


func resume_run() -> void:
	if app_phase != PHASE_PAUSE:
		return
	set_phase(PHASE_RUN)
	pause_state_changed.emit(false)


func notify_run_started() -> void:
	set_phase(PHASE_RUN)
	pause_state_changed.emit(false)


func notify_run_finished() -> void:
	set_results_phase()


func _get_first_unlocked_operation_id() -> String:
	for operation in operations:
		var operation_id := String(operation.get("id", ""))
		if GameState.is_operation_unlocked(operation_id):
			return operation_id
	return RunCatalog.get_first_operation_id()
