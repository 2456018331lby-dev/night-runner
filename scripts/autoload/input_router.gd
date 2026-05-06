extends Node

var move_axis: float = 0.0
var jump_pressed: bool = false
var attack_pressed: bool = false
var dash_pressed: bool = false


func set_move_axis(value: float) -> void:
	move_axis = clampf(value, -1.0, 1.0)


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

