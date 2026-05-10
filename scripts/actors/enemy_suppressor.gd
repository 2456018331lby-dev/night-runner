extends CharacterBody2D

signal defeated(points: int)

const WALK_SPEED := 90.0
const RETREAT_SPEED := 145.0
const GRAVITY := 1500.0
const CONTACT_RANGE := 30.0
const FIRE_RANGE_X := 520.0
const FIRE_RANGE_Y := 170.0
const COMFORT_RANGE := 250.0
const TOO_CLOSE_RANGE := 150.0
const FIRE_COOLDOWN := 1.35
const PROJECTILE_SPEED := 420.0
const POINTS_AWARD := 150

@export var bolt_scene: PackedScene = preload("res://scenes/actors/enemy_bolt.tscn")

@onready var rig: Node2D = $Rig
@onready var body_visual: Polygon2D = $Rig/Body
@onready var visor_visual: Polygon2D = $Rig/Visor
@onready var art_sprite: Sprite2D = $Rig/Art
@onready var muzzle: Marker2D = $Rig/Muzzle

var player: Node2D
var knocked_velocity: Vector2 = Vector2.ZERO
var defeated_once: bool = false
var hit_flash_timer: float = 0.0
var fire_cooldown_timer: float = 0.55
var facing: float = -1.0


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
	_try_fire()
	_refresh_visuals()
	if global_position.y > 920.0:
		_defeat()


func receive_hit(force: Vector2) -> void:
	knocked_velocity = force
	hit_flash_timer = 0.18
	fire_cooldown_timer = maxf(fire_cooldown_timer, 0.35)


func _update_timers(delta: float) -> void:
	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
	if fire_cooldown_timer > 0.0:
		fire_cooldown_timer -= delta


func _update_motion(delta: float) -> void:
	if knocked_velocity.length() > 1.0:
		velocity = knocked_velocity
		knocked_velocity = knocked_velocity.move_toward(Vector2.ZERO, 960.0 * delta)
		return
	if not is_instance_valid(player) or GameState.is_run_failed:
		velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * delta * 5.0)
		return

	var delta_pos := player.global_position - global_position
	if absf(delta_pos.x) > 1.0:
		facing = signf(delta_pos.x)

	if absf(delta_pos.x) < TOO_CLOSE_RANGE:
		velocity.x = -facing * RETREAT_SPEED
	elif absf(delta_pos.x) > COMFORT_RANGE + 80.0:
		velocity.x = facing * WALK_SPEED * GameState.get_modifier_value("speed_multiplier", 1.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * delta * 6.0)


func _try_fire() -> void:
	if fire_cooldown_timer > 0.0 or knocked_velocity.length() > 1.0:
		return
	if not is_instance_valid(player) or GameState.is_run_failed:
		return

	var delta_pos := player.global_position - muzzle.global_position
	if absf(delta_pos.x) > FIRE_RANGE_X or absf(delta_pos.y) > FIRE_RANGE_Y:
		return
	if absf(delta_pos.x) < 44.0:
		return

	var bolt := bolt_scene.instantiate()
	if not bolt is Node2D:
		return
	var bolt_node := bolt as Node2D
	bolt_node.global_position = muzzle.global_position
	var aim_position := player.global_position + Vector2(0.0, -18.0)
	if bolt_node.has_method("launch"):
		bolt_node.call("launch", (aim_position - muzzle.global_position).normalized() * PROJECTILE_SPEED)
	get_parent().add_child(bolt_node)
	fire_cooldown_timer = FIRE_COOLDOWN


func _try_contact_damage() -> void:
	if not is_instance_valid(player) or GameState.is_run_failed:
		return
	if global_position.distance_to(player.global_position) <= CONTACT_RANGE:
		player.take_contact_hit(signf(player.global_position.x - global_position.x))


func _refresh_visuals() -> void:
	if facing != 0.0:
		rig.scale.x = facing
	if hit_flash_timer > 0.0:
		body_visual.color = Color(1.0, 0.9, 0.72)
		visor_visual.color = Color(1.0, 0.95, 0.65)
		art_sprite.modulate = Color(1.0, 0.94, 0.82)
	elif fire_cooldown_timer < 0.2:
		body_visual.color = Color(0.27, 0.4, 0.96)
		visor_visual.color = Color(1.0, 0.45, 0.32)
		art_sprite.modulate = Color(1.0, 0.86, 0.74)
	else:
		body_visual.color = Color(0.23, 0.35, 0.92)
		visor_visual.color = Color(0.9, 0.95, 1.0)
		art_sprite.modulate = Color(1.0, 1.0, 1.0)


func _defeat() -> void:
	if defeated_once:
		return
	defeated_once = true
	defeated.emit(POINTS_AWARD)
	queue_free()
