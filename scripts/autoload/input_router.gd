extends Node

var move_axis: float = 0.0
var jump_pressed: bool = false
var attack_pressed: bool = false
var dash_pressed: bool = false
var move_left_held: bool = false
var move_right_held: bool = false
var preferred_move_axis: float = 0.0


func set_move_axis(value: float) -> void:
	move_left_held = false
	move_right_held = false
	preferred_move_axis = 0.0
	move_axis = clampf(value, -1.0, 1.0)


func set_move_button(axis: float, pressed: bool) -> void:
	if axis < 0.0:
		move_left_held = pressed
	elif axis > 0.0:
		move_right_held = pressed
	if pressed and axis != 0.0:
		preferred_move_axis = signf(axis)
	_refresh_move_axis()


func clear_move_buttons() -> void:
	move_left_held = false
	move_right_held = false
	preferred_move_axis = 0.0
	move_axis = 0.0


func press_action(action_name: String) -> void:
	match action_name:
		"jump":
			jump_pressed = true
		"attack":
			attack_pressed = true
		"dash":
			dash_pressed = true


func release_action(action_name: String) -> void:
	match action_name:
		"jump":
			jump_pressed = false
		"attack":
			attack_pressed = false
		"dash":
			dash_pressed = false


func consume_jump() -> bool:
	if jump_pressed:
		jump_pressed = false
		return true
	return false


func consume_attack() -> bool:
	if attack_pressed:
		attack_pressed = false
		return true
	return false


func consume_dash() -> bool:
	if dash_pressed:
		dash_pressed = false
		return true
	return false


func _refresh_move_axis() -> void:
	if move_left_held and move_right_held:
		move_axis = preferred_move_axis
	elif move_left_held:
		move_axis = -1.0
	elif move_right_held:
		move_axis = 1.0
	else:
		move_axis = 0.0
