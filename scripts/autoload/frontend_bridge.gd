extends Node

signal bootstrapped
signal phase_changed(phase: String)
signal operation_selected(operation_id: String)
signal directive_selected(operation_id: String, directive_id: String)
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
var selected_directives: Dictionary = {}


func bootstrap() -> void:
	operations = RunCatalog.get_operations()
	if operations.is_empty():
		selected_operation_id = ""
		bootstrapped.emit()
		return
	var remembered_id := String(GameState.meta_progress.get("selected_operation_id", ""))
	selected_directives = GameState.meta_progress.get("selected_directives", {}).duplicate(true)
	if remembered_id.is_empty() or not GameState.is_operation_unlocked(remembered_id):
		remembered_id = _get_first_unlocked_operation_id()
	selected_operation_id = remembered_id
	var changed := _ensure_directive_selection(selected_operation_id)
	if changed:
		GameState.meta_progress["selected_directives"] = selected_directives.duplicate(true)
		GameState.save_progress()
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
	_ensure_directive_selection(selected_operation_id)
	GameState.meta_progress["selected_operation_id"] = selected_operation_id
	GameState.meta_progress["selected_directives"] = selected_directives.duplicate(true)
	GameState.save_progress()
	operation_selected.emit(selected_operation_id)


func select_directive(operation_id: String, directive_id: String) -> void:
	if operation_id.is_empty() or directive_id.is_empty():
		return
	selected_directives[operation_id] = directive_id
	GameState.meta_progress["selected_directives"] = selected_directives.duplicate(true)
	GameState.save_progress()
	directive_selected.emit(operation_id, directive_id)


func get_selected_directive(operation_id: String) -> Dictionary:
	var operation := get_operation(operation_id)
	if operation.is_empty():
		return {}
	var directive_pool: Array = operation.get("directive_pool", [])
	if directive_pool.is_empty():
		return {}
	var selected_id := String(selected_directives.get(operation_id, ""))
	for directive in directive_pool:
		if String(directive.get("id", "")) == selected_id:
			return directive.duplicate(true)
	return directive_pool[0].duplicate(true)


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


func _ensure_directive_selection(operation_id: String) -> bool:
	if operation_id.is_empty():
		return false
	if selected_directives.has(operation_id):
		return false
	var operation := get_operation(operation_id)
	var directive_pool: Array = operation.get("directive_pool", [])
	if directive_pool.is_empty():
		return false
	selected_directives[operation_id] = String(directive_pool[0].get("id", ""))
	return true
