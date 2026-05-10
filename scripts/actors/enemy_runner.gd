extends CharacterBody2D

signal defeated(points: int)

const SPEED := 150.0
const GRAVITY := 1500.0
const CONTACT_RANGE := 34.0

@onready var body_visual: Polygon2D = $Body
@onready var art_sprite: Sprite2D = $Art

var player: Node2D
var knocked_velocity: Vector2 = Vector2.ZERO
var defeated_once: bool = false
var hit_flash_timer: float = 0.0
var stride_phase: float = randf() * TAU


func _ready() -> void:
	add_to_group("enemy")


func _physics_process(delta: float) -> void:
	if defeated_once:
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if knocked_velocity.length() > 1.0:
		velocity = knocked_velocity
		knocked_velocity = knocked_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	elif is_instance_valid(player) and not GameState.is_run_failed:
		var direction := signf(player.global_position.x - global_position.x)
		velocity.x = direction * SPEED * GameState.get_modifier_value("speed_multiplier", 1.0)
		body_visual.scale.x = direction if direction != 0.0 else body_visual.scale.x
	stride_phase += delta * clampf(absf(velocity.x) / 80.0, 0.8, 2.6)
	move_and_slide()
	_try_contact_damage()
	_update_flash(delta)
	if global_position.y > 920.0:
		_defeat()


func receive_hit(force: Vector2) -> void:
	knocked_velocity = force
	hit_flash_timer = 0.18


func _try_contact_damage() -> void:
	if not is_instance_valid(player) or GameState.is_run_failed:
		return
	if global_position.distance_to(player.global_position) <= CONTACT_RANGE:
		player.take_contact_hit(signf(player.global_position.x - global_position.x), "enemy", "runner_body")


func _update_flash(delta: float) -> void:
	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
		body_visual.color = Color(1.0, 0.95, 0.72)
		art_sprite.modulate = Color(1.0, 0.96, 0.78)
	else:
		body_visual.color = Color(0.21, 0.95, 0.8)
		art_sprite.modulate = Color(1.0, 1.0, 1.0)
	var squash := 1.0 + sin(stride_phase) * 0.06 if absf(velocity.x) > 10.0 and is_on_floor() else 1.0
	body_visual.scale.y = squash
	art_sprite.scale.y = 0.22 * (1.0 + (squash - 1.0) * 0.6)


func _defeat() -> void:
	if defeated_once:
		return
	defeated_once = true
	defeated.emit(100)
	queue_free()
