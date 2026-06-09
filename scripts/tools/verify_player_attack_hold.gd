extends Node

const PLAYER_SCENE := preload("res://scenes/actors/player.tscn")

var failures: Array[String] = []


func _ready() -> void:
	var original_mobile := PlatformProfile.is_mobile
	PlatformProfile.is_mobile = true

	var player := PLAYER_SCENE.instantiate()
	player.set_physics_process(false)
	add_child(player)
	await get_tree().process_frame

	InputRouter.press_action("attack")
	player.set("attack_timer", 0.0)
	player.call("_collect_actions")
	_expect(float(player.get("attack_timer")) > 0.0, "initial touch attack starts attack cooldown")

	player.set("attack_timer", 0.0)
	player.call("_collect_actions")
	_expect(float(player.get("attack_timer")) > 0.0, "held touch attack re-triggers after cooldown")

	InputRouter.release_held_action("attack")
	player.set("attack_timer", 0.0)
	player.call("_collect_actions")
	_expect(is_equal_approx(float(player.get("attack_timer")), 0.0), "released attack hold stops automatic attacks")

	InputRouter.press_action("attack")
	InputRouter.release_action("attack")
	player.call("_collect_actions")
	_expect(is_equal_approx(float(player.get("attack_timer")), 0.0), "cancelled attack does not fire later")

	InputRouter.release_action("jump")
	InputRouter.release_action("attack")
	InputRouter.release_action("dash")
	InputRouter.clear_move_buttons()
	PlatformProfile.is_mobile = original_mobile
	player.queue_free()

	if failures.is_empty():
		print("Player attack hold regression passed.")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
