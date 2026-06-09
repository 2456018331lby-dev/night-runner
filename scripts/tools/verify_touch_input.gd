extends SceneTree

const InputRouterScript := preload("res://scripts/autoload/input_router.gd")

var failures: Array[String] = []


func _init() -> void:
	var router = InputRouterScript.new()
	root.add_child(router)

	router.set_move_button(-1.0, true)
	_expect_axis(router, -1.0, "left press drives left")
	router.set_move_button(1.0, true)
	_expect_axis(router, 1.0, "right press overrides held left")
	router.set_move_button(1.0, false)
	_expect_axis(router, -1.0, "releasing right restores held left")
	router.set_move_button(-1.0, false)
	_expect_axis(router, 0.0, "releasing final direction clears axis")

	router.set_move_button(1.0, true)
	_expect_axis(router, 1.0, "right press drives right")
	router.set_move_button(-1.0, true)
	_expect_axis(router, -1.0, "left press overrides held right")
	router.clear_move_buttons()
	_expect_axis(router, 0.0, "clear_move_buttons releases movement")

	router.press_action("jump")
	if not router.consume_jump():
		failures.append("jump press was not consumable")
	if router.consume_jump():
		failures.append("jump press consumed more than once")

	router.press_action("attack")
	if not router.consume_attack():
		failures.append("attack press was not consumable")
	if router.consume_attack():
		failures.append("attack press consumed more than once before repeat")
	if not router.is_action_held("attack"):
		failures.append("attack hold state did not survive one-shot consumption")
	router.release_held_action("attack")
	if router.is_action_held("attack"):
		failures.append("release_held_action did not release attack hold")

	router.press_action("dash")
	router.release_action("dash")
	if router.consume_dash():
		failures.append("release_action should cancel pending dash")
	if router.is_action_held("dash"):
		failures.append("release_action should clear held dash")

	if failures.is_empty():
		print("Touch input regression passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _expect_axis(router: Node, expected: float, label: String) -> void:
	if not is_equal_approx(float(router.get("move_axis")), expected):
		failures.append("%s: expected %.1f, got %.1f" % [label, expected, float(router.get("move_axis"))])
