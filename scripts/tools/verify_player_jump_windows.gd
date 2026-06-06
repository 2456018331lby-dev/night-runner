extends Node

const PLAYER_SCENE := preload("res://scenes/actors/player.tscn")

var failures: Array[String] = []


func _ready() -> void:
	var player := PLAYER_SCENE.instantiate()
	player.set_physics_process(false)
	add_child(player)
	await get_tree().process_frame

	player.velocity = Vector2.ZERO
	player.set("jumps_remaining", 0)
	player.set("jump_buffer_timer", 0.0)
	_expect(int(player.get("jumps_remaining")) == 0, "test setup can exhaust jumps")
	player.call("_queue_jump")
	_expect(float(player.get("jump_buffer_timer")) > 0.0, "jump input enters buffer")

	player.call("_consume_jump_buffer_if_possible")
	_expect(float(player.get("jump_buffer_timer")) > 0.0, "buffer survives while no jump is available")
	_expect(is_equal_approx(player.velocity.y, 0.0), "failed buffered jump does not move player")

	player.set("jumps_remaining", 2)
	player.call("_consume_jump_buffer_if_possible")
	_expect(player.velocity.y < -100.0, "buffered jump fires when a jump becomes available")
	_expect(int(player.get("jumps_remaining")) == 1, "buffered jump spends one jump")
	_expect(is_equal_approx(float(player.get("jump_buffer_timer")), 0.0), "successful jump clears buffer")

	player.set("jumps_remaining", 2)
	player.set("coyote_timer", 0.0)
	player.call("_refresh_jump_windows", 1.0, false)
	_expect(int(player.get("jumps_remaining")) == 1, "expired coyote window leaves only the air jump")

	player.set("jumps_remaining", 2)
	player.set("coyote_timer", 0.1)
	player.call("_queue_jump")
	player.call("_refresh_jump_windows", 0.03, false)
	player.call("_consume_jump_buffer_if_possible")
	_expect(int(player.get("jumps_remaining")) == 1, "coyote jump preserves one remaining air jump")
	_expect(float(player.get("coyote_timer")) == 0.0, "coyote jump closes the coyote window")

	player.queue_free()
	if failures.is_empty():
		print("Player jump window regression passed.")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
