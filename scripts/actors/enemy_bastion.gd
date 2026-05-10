extends CharacterBody2D

signal defeated(points: int)

const WALK_SPEED := 64.0
const GRAVITY := 1500.0
const CONTACT_RANGE := 38.0
const PRESSURE_RANGE_X := 380.0
const PRESSURE_RANGE_Y := 180.0
const SHOCK_COOLDOWN := 2.1
const SHOCK_WINDUP := 0.58
const POINTS_AWARD := 260

@onready var rig: Node2D = $Rig
@onready var body_visual: Polygon2D = $Rig/Body
@onready var shield_visual: Polygon2D = $Rig/Shield
@onready var core_visual: Polygon2D = $Rig/Core
@onready var pulse_zone: Area2D = $PulseZone
@onready var pulse_shape: CollisionShape2D = $PulseZone/CollisionShape2D
@onready var pulse_ring: Polygon2D = $PulseZone/PulseRing

var player: Node2D
var knocked_velocity: Vector2 = Vector2.ZERO
var defeated_once: bool = false
var hit_flash_timer: float = 0.0
var shock_cooldown_timer: float = 1.2
var shock_windup_timer: float = 0.0
var shock_active_timer: float = 0.0
var facing: float = -1.0
var stride_phase: float = randf() * TAU


func _ready() -> void:
	add_to_group("enemy")
	pulse_zone.monitoring = true
	pulse_zone.monitorable = false
	pulse_zone.body_entered.connect(_on_pulse_zone_body_entered)
	_set_pulse_active(false)


func _physics_process(delta: float) -> void:
	if defeated_once:
		return
	_update_timers(delta)
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	_update_motion(delta)
	move_and_slide()
	_try_contact_damage()
	_try_begin_shockwave()
	_refresh_visuals()
	if global_position.y > 920.0:
		_defeat()


func receive_hit(force: Vector2) -> void:
	knocked_velocity = force * 0.82
	hit_flash_timer = 0.24
	shock_windup_timer = 0.0
	shock_active_timer = 0.0
	_set_pulse_active(false)


func _update_timers(delta: float) -> void:
	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
	if shock_cooldown_timer > 0.0:
		shock_cooldown_timer -= delta
	if shock_windup_timer > 0.0:
		shock_windup_timer -= delta
		if shock_windup_timer <= 0.0:
			_activate_shockwave()
	if shock_active_timer > 0.0:
		shock_active_timer -= delta
		if shock_active_timer <= 0.0:
			_set_pulse_active(false)


func _update_motion(delta: float) -> void:
	if knocked_velocity.length() > 1.0:
		velocity = knocked_velocity
		knocked_velocity = knocked_velocity.move_toward(Vector2.ZERO, 820.0 * delta)
		return
	if shock_windup_timer > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * delta * 10.0)
		return
	if not is_instance_valid(player) or GameState.is_run_failed:
		velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * delta * 4.0)
		return
	var delta_pos := player.global_position - global_position
	if absf(delta_pos.x) > 1.0:
		facing = signf(delta_pos.x)
	var desired_speed := facing * WALK_SPEED
	if absf(delta_pos.x) < 148.0:
		desired_speed = -facing * WALK_SPEED * 0.5
	velocity.x = move_toward(velocity.x, desired_speed, WALK_SPEED * delta * 5.0)
	stride_phase += delta * clampf(absf(velocity.x) / 60.0, 0.5, 1.7)


func _try_begin_shockwave() -> void:
	if shock_cooldown_timer > 0.0 or shock_windup_timer > 0.0 or shock_active_timer > 0.0:
		return
	if knocked_velocity.length() > 1.0:
		return
	if not is_instance_valid(player) or GameState.is_run_failed:
		return
	var delta_pos := player.global_position - global_position
	if absf(delta_pos.x) > PRESSURE_RANGE_X or absf(delta_pos.y) > PRESSURE_RANGE_Y:
		return
	shock_windup_timer = SHOCK_WINDUP


func _activate_shockwave() -> void:
	shock_cooldown_timer = SHOCK_COOLDOWN
	shock_active_timer = 0.32
	_set_pulse_active(true)
	_damage_players_in_pulse_zone()


func _set_pulse_active(active: bool) -> void:
	pulse_zone.monitoring = active
	pulse_shape.disabled = not active
	pulse_ring.visible = active or shock_windup_timer > 0.0


func _damage_players_in_pulse_zone() -> void:
	for body in pulse_zone.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_contact_hit"):
			body.take_contact_hit(facing, "enemy", "bastion_shockwave")


func _try_contact_damage() -> void:
	if not is_instance_valid(player) or GameState.is_run_failed:
		return
	if global_position.distance_to(player.global_position) <= CONTACT_RANGE:
		player.take_contact_hit(signf(player.global_position.x - global_position.x), "enemy", "bastion_body")


func _refresh_visuals() -> void:
	if facing != 0.0:
		rig.scale.x = facing
	var stride := 1.0 + sin(stride_phase) * 0.04 if absf(velocity.x) > 6.0 and is_on_floor() else 1.0
	var windup_mix := clampf(1.0 - shock_windup_timer / SHOCK_WINDUP, 0.0, 1.0) if shock_windup_timer > 0.0 else 0.0
	if hit_flash_timer > 0.0:
		body_visual.color = Color(1.0, 0.92, 0.76)
		shield_visual.color = Color(1.0, 0.94, 0.82)
		core_visual.color = Color(1.0, 0.82, 0.52)
	elif shock_active_timer > 0.0:
		body_visual.color = Color(1.0, 0.48, 0.36)
		shield_visual.color = Color(1.0, 0.78, 0.52)
		core_visual.color = Color(1.0, 0.92, 0.7)
	elif shock_windup_timer > 0.0:
		body_visual.color = Color(0.96, 0.46 + windup_mix * 0.2, 0.36)
		shield_visual.color = Color(1.0, 0.7 + windup_mix * 0.18, 0.48)
		core_visual.color = Color(1.0, 0.86, 0.62)
	else:
		body_visual.color = Color(0.96, 0.42, 0.34)
		shield_visual.color = Color(1.0, 0.72, 0.42)
		core_visual.color = Color(1.0, 0.9, 0.68)
	body_visual.scale.y = stride
	core_visual.scale = Vector2.ONE * (1.0 + windup_mix * 0.2 + sin(Time.get_ticks_msec() / 120.0) * 0.02)
	if shock_active_timer > 0.0:
		pulse_ring.scale = Vector2.ONE * (1.0 + (0.32 - shock_active_timer) * 3.2)
		pulse_ring.modulate.a = clampf(shock_active_timer * 3.0, 0.0, 0.75)
	elif shock_windup_timer > 0.0:
		pulse_ring.scale = Vector2.ONE * (0.82 + windup_mix * 0.28)
		pulse_ring.modulate.a = 0.14 + windup_mix * 0.22
	else:
		pulse_ring.scale = Vector2.ONE
		pulse_ring.modulate.a = 0.0


func _on_pulse_zone_body_entered(body: Node) -> void:
	if shock_active_timer <= 0.0:
		return
	if body.is_in_group("player") and body.has_method("take_contact_hit"):
		body.take_contact_hit(facing, "enemy", "bastion_shockwave")


func _defeat() -> void:
	if defeated_once:
		return
	defeated_once = true
	defeated.emit(POINTS_AWARD)
	queue_free()
