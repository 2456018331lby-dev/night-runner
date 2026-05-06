extends CharacterBody2D

signal player_hit
signal player_fell

const SPEED := 320.0
const JUMP_VELOCITY := -560.0
const AIR_CONTROL := 0.65
const GRAVITY := 1500.0
const DASH_SPEED := 760.0
const DASH_TIME := 0.18
const DASH_COOLDOWN := 0.6
const ATTACK_RANGE_X := 110.0
const ATTACK_RANGE_Y := 56.0
const ATTACK_FORCE := 540.0

@onready var body_visual: Polygon2D = $Body
@onready var art_sprite: Sprite2D = $Art
@onready var camera: Camera2D = $Camera2D

var jumps_remaining: int = 2
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var facing: float = 1.0
var invulnerable_timer: float = 0.0
var action_pop_timer: float = 0.0
var camera_shake_timer: float = 0.0
var camera_shake_strength: float = 0.0


func _ready() -> void:
	add_to_group("player")


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_collect_actions()
	_apply_gravity(delta)
	_handle_horizontal_motion(delta)
	_handle_fall_check()
	move_and_slide()
	_refresh_visuals()


func _update_timers(delta: float) -> void:
	if is_on_floor():
		jumps_remaining = 2
	if dash_timer > 0.0:
		dash_timer -= delta
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
	if invulnerable_timer > 0.0:
		invulnerable_timer -= delta
	if action_pop_timer > 0.0:
		action_pop_timer -= delta
	if camera_shake_timer > 0.0:
		camera_shake_timer -= delta
	else:
		camera_shake_strength = move_toward(camera_shake_strength, 0.0, delta * 22.0)


func _collect_actions() -> void:
	var axis := Input.get_axis("move_left", "move_right")
	if absf(InputRouter.move_axis) > absf(axis):
		axis = InputRouter.move_axis

	if axis != 0.0:
		facing = signf(axis)

	if Input.is_action_just_pressed("jump") or InputRouter.consume_jump():
		_try_jump()
	if Input.is_action_just_pressed("dash") or InputRouter.consume_dash():
		_try_dash()
	if Input.is_action_just_pressed("attack") or InputRouter.consume_attack():
		_try_attack()

	if dash_timer <= 0.0:
		var control := 1.0 if is_on_floor() else AIR_CONTROL
		velocity.x = move_toward(velocity.x, axis * SPEED, SPEED * control * 0.18)


func _try_jump() -> void:
	if jumps_remaining <= 0:
		return
	jumps_remaining -= 1
	velocity.y = JUMP_VELOCITY


func _try_dash() -> void:
	if dash_timer > 0.0 or dash_cooldown_timer > 0.0:
		return
	dash_timer = DASH_TIME
	dash_cooldown_timer = DASH_COOLDOWN
	velocity.y = minf(velocity.y, -40.0)
	velocity.x = facing * DASH_SPEED
	action_pop_timer = 0.1
	_trigger_camera_shake(4.0, 0.1)


func _try_attack() -> void:
	var hit_any := false
	for enemy: Node in get_tree().get_nodes_in_group("enemy"):
		if not enemy.has_method("receive_hit"):
			continue
		var delta_pos: Vector2 = enemy.global_position - global_position
		if signf(delta_pos.x) == facing and absf(delta_pos.x) <= ATTACK_RANGE_X and absf(delta_pos.y) <= ATTACK_RANGE_Y:
			enemy.receive_hit(Vector2(facing * ATTACK_FORCE, -240.0))
			hit_any = true
	action_pop_timer = 0.08
	if hit_any:
		_trigger_camera_shake(5.5, 0.12)


func _apply_gravity(delta: float) -> void:
	if dash_timer > 0.0:
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta


func _handle_horizontal_motion(delta: float) -> void:
	if dash_timer > 0.0:
		velocity.x = facing * DASH_SPEED
		return
	if is_on_floor() and absf(Input.get_axis("move_left", "move_right")) < 0.1 and absf(InputRouter.move_axis) < 0.1:
		velocity.x = move_toward(velocity.x, 0.0, SPEED * delta * 5.0)


func _handle_fall_check() -> void:
	if global_position.y > 920.0:
		player_fell.emit()


func take_contact_hit(push_direction: float) -> void:
	if invulnerable_timer > 0.0 or GameState.is_run_failed:
		return
	invulnerable_timer = 0.65
	velocity = Vector2(push_direction * 260.0, -220.0)
	action_pop_timer = 0.16
	_trigger_camera_shake(8.0, 0.18)
	player_hit.emit()


func _refresh_visuals() -> void:
	body_visual.color = Color(1.0, 0.35, 0.54) if invulnerable_timer <= 0.0 else Color(1.0, 0.85, 0.42)
	var impact_strength := clampf(action_pop_timer * 8.0, 0.0, 1.0)
	body_visual.scale = Vector2(facing * (1.0 + impact_strength * 0.14), 1.0 - impact_strength * 0.08)
	art_sprite.modulate = Color(1.0, 1.0, 1.0) if invulnerable_timer <= 0.0 else Color(1.0, 0.9, 0.72)
	art_sprite.scale = Vector2(0.25 * facing * (1.0 + impact_strength * 0.08), 0.25 * (1.0 - impact_strength * 0.04))
	camera.position.x = lerpf(camera.position.x, 90.0 * facing, 0.08)
	var shake_target := Vector2.ZERO
	if camera_shake_timer > 0.0:
		shake_target = Vector2(randf_range(-camera_shake_strength, camera_shake_strength), randf_range(-camera_shake_strength, camera_shake_strength))
	camera.offset = camera.offset.lerp(shake_target, 0.32)


func _trigger_camera_shake(strength: float, duration: float) -> void:
	camera_shake_strength = maxf(camera_shake_strength, strength)
	camera_shake_timer = duration
