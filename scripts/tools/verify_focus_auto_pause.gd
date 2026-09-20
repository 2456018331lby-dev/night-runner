extends Node

const MAIN_SCENE := preload("res://scenes/app/main.tscn")

var failures: Array[String] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame

	var frontend_bridge := get_node("/root/FrontendBridge")
	_expect(String(frontend_bridge.get("app_phase")) == "hub", "main scene should bootstrap into hub phase")

	InputRouter.set_move_button(-1.0, true)
	main.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	await get_tree().process_frame
	_expect(String(frontend_bridge.get("app_phase")) == "hub", "focus-out in hub phase should not change phase")
	_expect(not get_tree().paused, "focus-out in hub phase should not pause the tree")
	_expect(is_equal_approx(InputRouter.move_axis, -1.0), "focus-out in hub phase should leave inputs untouched")
	InputRouter.clear_move_buttons()

	frontend_bridge.set("app_phase", "run")
	InputRouter.set_move_button(-1.0, true)
	InputRouter.press_action("jump")
	InputRouter.press_action("attack")
	InputRouter.press_action("dash")

	main.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	await get_tree().process_frame
	_expect(String(frontend_bridge.get("app_phase")) == "pause", "focus-out during run should pause via FrontendBridge.toggle_pause()")
	_expect(get_tree().paused, "focus-out during run should pause the tree")
	_expect(is_equal_approx(InputRouter.move_axis, 0.0), "focus-out auto-pause should clear held movement input")
	_expect(not InputRouter.consume_jump(), "focus-out auto-pause should clear pending jump input")
	_expect(not InputRouter.consume_attack(), "focus-out auto-pause should clear pending attack input")
	_expect(not InputRouter.consume_dash(), "focus-out auto-pause should clear pending dash input")
	_expect(not InputRouter.is_action_held("jump"), "focus-out auto-pause should release held jump")
	_expect(not InputRouter.is_action_held("attack"), "focus-out auto-pause should release held attack")
	_expect(not InputRouter.is_action_held("dash"), "focus-out auto-pause should release held dash")

	main.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	await get_tree().process_frame
	_expect(String(frontend_bridge.get("app_phase")) == "pause", "focus-out while already paused should not unpause")
	_expect(get_tree().paused, "focus-out while already paused should keep the tree paused")

	frontend_bridge.call("resume_run")
	await get_tree().process_frame
	_expect(String(frontend_bridge.get("app_phase")) == "run", "resume_run should return to run phase")

	InputRouter.set_move_button(1.0, true)
	main.notification(NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	await get_tree().process_frame
	_expect(String(frontend_bridge.get("app_phase")) == "pause", "window focus-out during run should pause via FrontendBridge.toggle_pause()")
	_expect(is_equal_approx(InputRouter.move_axis, 0.0), "window focus-out auto-pause should clear held movement input")

	get_tree().paused = false
	main.queue_free()

	if failures.is_empty():
		print("Focus auto-pause regression passed.")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
