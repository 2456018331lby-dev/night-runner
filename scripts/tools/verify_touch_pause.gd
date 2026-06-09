extends Node

const TOUCH_CONTROLS_SCENE := preload("res://scenes/ui/touch_controls.tscn")


func _ready() -> void:
	var frontend_bridge := get_node("/root/FrontendBridge")
	frontend_bridge.set("app_phase", "run")
	var controls := TOUCH_CONTROLS_SCENE.instantiate()
	add_child(controls)
	await get_tree().process_frame

	controls.call("configure", true)
	if not bool(controls.get("visible")):
		_fail("Touch controls did not become visible when configured on.")
		return

	InputRouter.set_move_button(-1.0, true)
	InputRouter.press_action("jump")
	InputRouter.press_action("attack")
	InputRouter.press_action("dash")

	var pause_button: Button = controls.get_node("Controls/PauseButton")
	pause_button.pressed.emit()
	await get_tree().process_frame

	if String(frontend_bridge.get("app_phase")) != "pause":
		_fail("Pause button did not route through FrontendBridge.toggle_pause().")
		return
	if not is_equal_approx(InputRouter.move_axis, 0.0):
		_fail("Pause button did not release held movement input.")
		return
	if InputRouter.consume_jump() or InputRouter.consume_attack() or InputRouter.consume_dash():
		_fail("Pause button did not clear pending action inputs.")
		return

	print("Touch pause regression passed.")
	get_tree().quit(0)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
