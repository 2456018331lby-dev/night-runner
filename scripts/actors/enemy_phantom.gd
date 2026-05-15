extends CharacterBody2D

signal defeated(points: int)

const WALK_SPEED := 128.0
const GRAVITY := 1500.0
const CONTACT_RANGE := 30.0
const DIVE_RANGE_X := 420.0
const DIVE_RANGE_Y := 210.0
const DIVE_SPEED_X := 460.0
const DIVE_SPEED_Y := -250.0
const DIVE_COOLDOWN := 1.95
const DIVE_RECOVERY_TIME := 0.18
const POINTS_AWARD := 220

@onready var rig: Node2D = $Rig
@onready var body_visual: Polygon2D = $Rig/Body
@onready var blade_visual: Polygon2D = $Rig/Blade
@onready var eye_visual: Polygon2D = $Rig/Eye
@onready var trail: Polygon2D = $Rig/Trail

var player: Node2D
var knocked_velocity: Vector2 = Vector2.ZERO
var defeated_once: bool = false
var hit_flash_timer: float = 0.0
var dive_cooldown_timer: float = 0.8
var windup_timer: float = 0.0
var dive_timer: float = 0.0
var facing: float = -1.0
var stride_phase: float = randf() * TAU


func _ready() -> void:
	add_to_group("enemy")


func _physics_process(delta: float) -> void:
	if defeated_once:
		return
	_update_timers(delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	_update_motion(delta)
	move_and_slide()
	_try_contact_damage()
	_try_begin_dive()
	_refresh_visuals()
	if global_position.y > 920.0:
		_defeat(false)


func receive_hit(force: Vector2) -> void:
	knocked_velocity = force * 1.1
	hit_flash_timer = 0.2
	windup_timer = 0.0
	dive_timer = 0.0
	dive_cooldown_timer = maxf(dive_cooldown_timer, 0.55)


func _update_timers(delta: float) -> void:
	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
	if dive_cooldown_timer > 0.0:
		dive_cooldown_timer -= delta
	if windup_timer > 0.0:
		windup_timer -= delta
		if windup_timer <= 0.0:
			_launch_dive()
	if dive_timer > 0.0:
		dive_timer -= delta
		if dive_timer <= 0.0:
			dive_timer = 0.0
		elif is_on_wall() or (is_on_floor() and velocity.y >= 0.0):
			dive_timer = minf(dive_timer, DIVE_RECOVERY_TIME)


func _update_motion(delta: float) -> void:
	if knocked_velocity.length() > 1.0:
		velocity = knocked_velocity
		knocked_velocity = knocked_velocity.move_toward(Vector2.ZERO, 940.0 * delta)
		return
	if dive_timer > 0.0:
		if velocity.x != 0.0:
			facing = signf(velocity.x)
		return
	if windup_timer > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * delta * 12.0)
		return
	if not is_instance_valid(player) or GameState.is_run_failed:
		velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * delta * 4.0)
		return
	var delta_pos := player.global_position - global_position
	if absf(delta_pos.x) > 1.0:
		facing = signf(delta_pos.x)
	var desired_speed := facing * WALK_SPEED
	if absf(delta_pos.x) < 110.0:
		desired_speed = -facing * WALK_SPEED * 0.45
	velocity.x = move_toward(velocity.x, desired_speed, WALK_SPEED * delta * 7.0)
	stride_phase += delta * clampf(absf(velocity.x) / 90.0, 0.7, 2.4)


func _try_begin_dive() -> void:
	if dive_cooldown_timer > 0.0 or windup_timer > 0.0 or dive_timer > 0.0:
		return
	if knocked_velocity.length() > 1.0:
		return
	if not is_instance_valid(player) or GameState.is_run_failed:
		return
	if not is_on_floor():
		return
	var delta_pos := player.global_position - global_position
	if absf(delta_pos.x) > DIVE_RANGE_X or absf(delta_pos.y) > DIVE_RANGE_Y:
		return
	facing = signf(delta_pos.x) if absf(delta_pos.x) > 1.0 else facing
	windup_timer = 0.32


func _launch_dive() -> void:
	dive_timer = 0.34
	dive_cooldown_timer = DIVE_COOLDOWN
	velocity.x = facing * DIVE_SPEED_X
	velocity.y = DIVE_SPEED_Y


func _try_contact_damage() -> void:
	if not is_instance_valid(player) or GameState.is_run_failed:
		return
	if global_position.distance_to(player.global_position) <= CONTACT_RANGE:
		var detail := "phantom_dive" if dive_timer > 0.0 else "phantom_body"
		var push_direction := signf(player.global_position.x - global_position.x)
		if push_direction == 0.0:
			push_direction = facing if facing != 0.0 else 1.0
		player.take_contact_hit(push_direction, "enemy", detail)
		if dive_timer > 0.0:
			dive_timer = minf(dive_timer, DIVE_RECOVERY_TIME)


func _refresh_visuals() -> void:
	if facing != 0.0:
		rig.scale.x = facing
	var windup_mix := clampf(1.0 - windup_timer / 0.32, 0.0, 1.0) if windup_timer > 0.0 else 0.0
	var dive_mix := clampf(dive_timer / 0.34, 0.0, 1.0)
	var stride := 1.0 + sin(stride_phase) * 0.05 if absf(velocity.x) > 8.0 and is_on_floor() else 1.0
	if hit_flash_timer > 0.0:
		body_visual.color = Color(0.96, 1.0, 1.0)
		blade_visual.color = Color(1.0, 0.92, 0.8)
		eye_visual.color = Color(1.0, 0.86, 0.7)
	elif dive_timer > 0.0:
		body_visual.color = Color(0.5, 1.0, 0.94)
		blade_visual.color = Color(0.96, 1.0, 0.9)
		eye_visual.color = Color(1.0, 0.9, 0.62)
	elif windup_timer > 0.0:
		body_visual.color = Color(0.34, 0.96, 0.9 + windup_mix * 0.08)
		blade_visual.color = Color(0.9, 1.0, 0.88)
		eye_visual.color = Color(1.0, 0.84 + windup_mix * 0.08, 0.52)
	else:
		body_visual.color = Color(0.24, 0.92, 0.86)
		blade_visual.color = Color(0.78, 1.0, 0.92)
		eye_visual.color = Color(0.94, 1.0, 0.86)
	body_visual.scale.y = stride
	blade_visual.rotation = -0.06 - windup_mix * 0.16 - dive_mix * 0.22
	trail.scale.x = 1.0 + dive_mix * 1.4 + windup_mix * 0.4
	trail.modulate.a = 0.08 + windup_mix * 0.14 + dive_mix * 0.3


func _defeat(award_points: bool = true) -> void:
	if defeated_once:
		return
	defeated_once = true
	if award_points:
		defeated.emit(POINTS_AWARD)
	queue_free()
