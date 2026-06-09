extends Node

const TOUCH_CONTROLS_SCENE := preload("res://scenes/ui/touch_controls.tscn")
const MIN_PRIMARY_TOUCH_SIZE := Vector2(120.0, 120.0)
const MIN_JUMP_HEIGHT := 80.0
const MIN_PAUSE_SIZE := Vector2(58.0, 56.0)

var failures: Array[String] = []


func _ready() -> void:
	var original_mobile := PlatformProfile.is_mobile
	PlatformProfile.is_mobile = true

	var controls := TOUCH_CONTROLS_SCENE.instantiate()
	add_child(controls)
	await get_tree().process_frame

	controls.call("configure", true)
	await get_tree().process_frame

	_expect(bool(controls.get("visible")), "touch controls should be visible on mobile configure")

	var left_pad: Control = controls.get_node("Controls/LeftPad")
	var action_pad: Control = controls.get_node("Controls/ActionPad")
	var move_left: Button = controls.get_node("Controls/LeftPad/Margin/MoveRow/MoveLeft")
	var move_right: Button = controls.get_node("Controls/LeftPad/Margin/MoveRow/MoveRight")
	var jump: Button = controls.get_node("Controls/ActionPad/Margin/VBox/Jump")
	var attack: Button = controls.get_node("Controls/ActionPad/Margin/VBox/ActionRow/Attack")
	var dash: Button = controls.get_node("Controls/ActionPad/Margin/VBox/ActionRow/Dash")
	var pause: Button = controls.get_node("Controls/PauseButton")

	_expect_button_minimum(move_left, MIN_PRIMARY_TOUCH_SIZE, "left move button")
	_expect_button_minimum(move_right, MIN_PRIMARY_TOUCH_SIZE, "right move button")
	_expect(jump.custom_minimum_size.y >= MIN_JUMP_HEIGHT, "jump button is below mobile minimum height")
	_expect_button_minimum(attack, MIN_PRIMARY_TOUCH_SIZE, "attack button")
	_expect_button_minimum(dash, MIN_PRIMARY_TOUCH_SIZE, "dash button")
	_expect_button_minimum(pause, MIN_PAUSE_SIZE, "pause button")

	_expect(move_left.text == "L", "left move button label stays compact")
	_expect(move_right.text == "R", "right move button label stays compact")
	_expect(attack.text == "ATK", "attack button label stays compact")
	_expect(pause.text == "II", "pause button keeps symbolic label")

	await get_tree().process_frame
	_expect(not _rects_overlap(left_pad.get_global_rect(), action_pad.get_global_rect()), "movement and action pads should not overlap")
	_expect(not _rects_overlap(pause.get_global_rect(), action_pad.get_global_rect()), "pause button should not overlap action pad")
	_expect(not _rects_overlap(pause.get_global_rect(), left_pad.get_global_rect()), "pause button should not overlap movement pad")

	InputRouter.set_move_button(-1.0, true)
	InputRouter.press_action("jump")
	InputRouter.press_action("attack")
	InputRouter.press_action("dash")
	attack.button_pressed = true
	attack.scale = Vector2.ONE * 0.94
	dash.button_pressed = true
	dash.scale = Vector2.ONE * 0.94
	controls.call("configure", false)
	await get_tree().process_frame

	_expect(not bool(controls.get("visible")), "touch controls should hide when configured off")
	_expect(is_equal_approx(InputRouter.move_axis, 0.0), "hiding touch controls clears movement")
	_expect(not InputRouter.consume_jump(), "hiding touch controls clears pending jump")
	_expect(not InputRouter.consume_attack(), "hiding touch controls clears pending attack")
	_expect(not InputRouter.consume_dash(), "hiding touch controls clears pending dash")
	_expect(not InputRouter.is_action_held("attack"), "hiding touch controls clears held attack")
	_expect(not attack.button_pressed, "hiding touch controls clears stale attack button pressed state")
	_expect(not dash.button_pressed, "hiding touch controls clears stale dash button pressed state")
	_expect(_vector_approx(attack.scale, Vector2.ONE), "hiding touch controls restores attack button visual scale")
	_expect(_vector_approx(dash.scale, Vector2.ONE), "hiding touch controls restores dash button visual scale")

	InputRouter.release_action("jump")
	InputRouter.release_action("attack")
	InputRouter.release_action("dash")
	InputRouter.clear_move_buttons()
	PlatformProfile.is_mobile = original_mobile
	controls.queue_free()

	if failures.is_empty():
		print("Touch controls layout regression passed.")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _expect_button_minimum(button: Button, minimum_size: Vector2, label: String) -> void:
	_expect(button.custom_minimum_size.x >= minimum_size.x, "%s width is below mobile touch target" % label)
	_expect(button.custom_minimum_size.y >= minimum_size.y, "%s height is below mobile touch target" % label)


func _rects_overlap(a: Rect2, b: Rect2) -> bool:
	return a.intersects(b, true)


func _vector_approx(a: Vector2, b: Vector2) -> bool:
	return is_equal_approx(a.x, b.x) and is_equal_approx(a.y, b.y)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
