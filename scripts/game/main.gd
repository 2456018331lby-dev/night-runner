extends Node

@onready var world: Node = $World
@onready var session_screen: CanvasLayer = $SessionScreen
@onready var rotate_prompt: CanvasLayer = null

var _run_catalog: RunCatalog


func _ready() -> void:
	_run_catalog = RunCatalog.shared()
	_build_rotate_prompt()
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	_set_run_ui_visible(false)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if FrontendBridge.app_phase == FrontendBridge.PHASE_RUN:
			FrontendBridge.toggle_pause()
		elif FrontendBridge.app_phase == FrontendBridge.PHASE_PAUSE:
			FrontendBridge.resume_run()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_auto_pause_on_focus_out()


func _auto_pause_on_focus_out() -> void:
	if FrontendBridge.app_phase != FrontendBridge.PHASE_RUN:
		return
	InputRouter.clear_move_buttons()
	InputRouter.release_action("jump")
	InputRouter.release_action("attack")
	InputRouter.release_action("dash")
	FrontendBridge.toggle_pause()


func _on_frontend_operation_selected(operation_id: String) -> void:
	session_screen.build_hub(FrontendBridge.get_operations(), operation_id)


func _on_frontend_directive_selected(_operation_id: String, _directive_id: String) -> void:
	if FrontendBridge.app_phase == FrontendBridge.PHASE_HUB:
		session_screen.build_hub(FrontendBridge.get_operations(), FrontendBridge.selected_operation_id)


func _on_launch_requested() -> void:
	FrontendBridge.request_start_selected_operation()


func _on_start_requested(operation_id: String) -> void:
	var operation := _run_catalog.get_operation(operation_id)
	if operation.is_empty():
		return
	var directive := FrontendBridge.get_selected_directive(operation_id)
	GameState.start_run(operation, directive)
	if world.has_method("begin"):
		world.call("begin", operation)
	FrontendBridge.notify_run_started()
	session_screen.hide_for_run()
	_set_run_ui_visible(true)


func _on_retry_requested(operation_id: String = "") -> void:
	if operation_id.is_empty():
		operation_id = GameState.current_operation_id if not GameState.current_operation_id.is_empty() else FrontendBridge.selected_operation_id
	_on_start_requested(operation_id)


func _on_pause_state_changed(paused: bool) -> void:
	get_tree().paused = paused
	if paused:
		_set_run_ui_visible(false)
		var operation := _run_catalog.get_operation(GameState.current_operation_id)
		session_screen.build_pause(operation)
	else:
		if FrontendBridge.app_phase == FrontendBridge.PHASE_RESULTS:
			return
		session_screen.hide_for_run()
		_set_run_ui_visible(true)


func _on_resume_requested() -> void:
	FrontendBridge.resume_run()


func _on_return_to_hub_requested() -> void:
	get_tree().paused = false
	_set_run_ui_visible(false)
	FrontendBridge.set_phase(FrontendBridge.PHASE_HUB)
	if world.has_method("reset_world"):
		world.call("reset_world")
	session_screen.build_hub(FrontendBridge.get_operations(), FrontendBridge.selected_operation_id)


func _on_run_finished(_success: bool) -> void:
	get_tree().paused = false
	_set_run_ui_visible(false)
	FrontendBridge.notify_run_finished()
	var operation := _run_catalog.get_operation(GameState.current_operation_id)
	session_screen.build_results(operation)


func _set_run_ui_visible(run_visible: bool) -> void:
	if world.has_method("set_run_ui_visible"):
		world.call("set_run_ui_visible", run_visible)


func _build_rotate_prompt() -> void:
	if not PlatformProfile.is_mobile:
		return
	rotate_prompt = CanvasLayer.new()
	rotate_prompt.layer = 999
	rotate_prompt.visible = false
	add_child(rotate_prompt)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.85)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	rotate_prompt.add_child(backdrop)
	var label := Label.new()
	label.text = "ROTATE YOUR DEVICE"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	rotate_prompt.add_child(label)
	get_tree().root.size_changed.connect(_check_orientation)
	_check_orientation()


func _check_orientation() -> void:
	if rotate_prompt == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var aspect: float = viewport_size.x / maxf(1.0, viewport_size.y)
	rotate_prompt.visible = aspect < 1.2
