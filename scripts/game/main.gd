extends Node

const RunCatalog := preload("res://scripts/game/run_catalog.gd")

@onready var world: Node = $World
@onready var session_screen: CanvasLayer = $SessionScreen


func _ready() -> void:
	FrontendBridge.start_requested.connect(_on_start_requested)
	FrontendBridge.retry_requested.connect(_on_retry_requested)
	FrontendBridge.return_to_hub_requested.connect(_on_return_to_hub_requested)
	FrontendBridge.pause_state_changed.connect(_on_pause_state_changed)
	FrontendBridge.operation_selected.connect(_on_frontend_operation_selected)
	FrontendBridge.directive_selected.connect(_on_frontend_directive_selected)
	GameState.run_finished.connect(_on_run_finished)
	session_screen.launch_requested.connect(_on_launch_requested)
	session_screen.retry_requested.connect(_on_retry_requested)
	session_screen.resume_requested.connect(_on_resume_requested)
	session_screen.hub_requested.connect(_on_return_to_hub_requested)
	FrontendBridge.bootstrap()
	session_screen.build_hub(FrontendBridge.get_operations(), FrontendBridge.selected_operation_id)
	if world.has_method("configure_touch_controls"):
		world.call("configure_touch_controls")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if FrontendBridge.app_phase == FrontendBridge.PHASE_RUN:
			FrontendBridge.toggle_pause()
		elif FrontendBridge.app_phase == FrontendBridge.PHASE_PAUSE:
			FrontendBridge.resume_run()


func _on_frontend_operation_selected(operation_id: String) -> void:
	session_screen.build_hub(FrontendBridge.get_operations(), operation_id)


func _on_frontend_directive_selected(_operation_id: String, _directive_id: String) -> void:
	if FrontendBridge.app_phase == FrontendBridge.PHASE_HUB:
		session_screen.build_hub(FrontendBridge.get_operations(), FrontendBridge.selected_operation_id)


func _on_launch_requested() -> void:
	FrontendBridge.request_start_selected_operation()


func _on_start_requested(operation_id: String) -> void:
	var operation := RunCatalog.get_operation(operation_id)
	if operation.is_empty():
		return
	var directive := FrontendBridge.get_selected_directive(operation_id)
	GameState.start_run(operation, directive)
	if world.has_method("begin"):
		world.call("begin", operation)
	FrontendBridge.notify_run_started()
	session_screen.hide_for_run()


func _on_retry_requested(operation_id: String) -> void:
	_on_start_requested(operation_id)


func _on_pause_state_changed(paused: bool) -> void:
	get_tree().paused = paused
	if paused:
		var operation := RunCatalog.get_operation(GameState.current_operation_id)
		session_screen.build_pause(operation)
	else:
		if FrontendBridge.app_phase == FrontendBridge.PHASE_RESULTS:
			return
		session_screen.hide_for_run()


func _on_resume_requested() -> void:
	FrontendBridge.resume_run()


func _on_return_to_hub_requested() -> void:
	get_tree().paused = false
	if world.has_method("reset_world"):
		world.call("reset_world")
	session_screen.build_hub(FrontendBridge.get_operations(), FrontendBridge.selected_operation_id)


func _on_run_finished(_success: bool) -> void:
	get_tree().paused = false
	FrontendBridge.notify_run_finished()
	var operation := RunCatalog.get_operation(GameState.current_operation_id)
	session_screen.build_results(operation)
