extends Node

const TOUCH_CONTROLS_SCENE := preload("res://scenes/ui/touch_controls.tscn")


func _ready() -> void:
	if not _verify_input_router_semantics():
		return

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
	pause_button.button_pressed = true
	pause_button.scale = Vector2.ONE * 0.94
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
	if pause_button.button_pressed:
		_fail("Pause button left stale pressed state after routing pause.")
		return
	if not _vector_approx(pause_button.scale, Vector2.ONE):
		_fail("Pause button visual scale did not reset after routing pause.")
		return

	print("Touch pause regression passed.")
	get_tree().quit(0)


func _verify_input_router_semantics() -> bool:
	InputRouter.clear_move_buttons()
	InputRouter.release_action("jump")
	InputRouter.release_action("attack")
	InputRouter.release_action("dash")

	InputRouter.set_move_button(-1.0, true)
	if not _expect_axis(-1.0, "left press drives left"):
		return false
	InputRouter.set_move_button(1.0, true)
	if not _expect_axis(1.0, "right press overrides held left"):
		return false
	InputRouter.set_move_button(1.0, false)
	if not _expect_axis(-1.0, "releasing right restores held left"):
		return false
	InputRouter.set_move_button(-1.0, false)
	if not _expect_axis(0.0, "releasing final direction clears axis"):
		return false

	InputRouter.set_move_button(1.0, true)
	if not _expect_axis(1.0, "right press drives right"):
		return false
	InputRouter.set_move_button(-1.0, true)
	if not _expect_axis(-1.0, "left press overrides held right"):
		return false
	InputRouter.clear_move_buttons()
	if not _expect_axis(0.0, "clear_move_buttons releases movement"):
		return false

	InputRouter.press_action("jump")
	if not InputRouter.consume_jump():
		_fail("jump press was not consumable")
		return false
	if InputRouter.consume_jump():
		_fail("jump press consumed more than once")
		return false

	InputRouter.press_action("attack")
	if not InputRouter.consume_attack():
		_fail("attack press was not consumable")
		return false
	if InputRouter.consume_attack():
		_fail("attack press consumed more than once before repeat")
		return false
	if not InputRouter.is_action_held("attack"):
		_fail("attack hold state did not survive one-shot consumption")
		return false
	InputRouter.release_held_action("attack")
	if InputRouter.is_action_held("attack"):
		_fail("release_held_action did not release attack hold")
		return false

	InputRouter.press_action("dash")
	InputRouter.release_action("dash")
	if InputRouter.consume_dash():
		_fail("release_action should cancel pending dash")
		return false
	if InputRouter.is_action_held("dash"):
		_fail("release_action should clear held dash")
		return false

	return true


func _expect_axis(expected: float, label: String) -> bool:
	if is_equal_approx(InputRouter.move_axis, expected):
		return true
	_fail("%s: expected %.1f, got %.1f" % [label, expected, InputRouter.move_axis])
	return false


func _vector_approx(a: Vector2, b: Vector2) -> bool:
	return is_equal_approx(a.x, b.x) and is_equal_approx(a.y, b.y)


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
