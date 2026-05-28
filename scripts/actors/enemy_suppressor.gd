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
const FIRE_COOLDOWN := 1.65
const PROJECTILE_SPEED := 385.0
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
var aim_flash_timer: float = 0.0
var stride_phase: float = randf() * TAU
var max_hp: int = 3
var current_hp: int = 3
var hp_bar_bg: Polygon2D
var hp_bar_fill: Polygon2D


func _ready() -> void:
	add_to_group("enemy")




func _setup_hp_bar() -> void:
	hp_bar_bg = Polygon2D.new()
	hp_bar_bg.polygon = PackedVector2Array([
		Vector2(-20.0, -2.0), Vector2(20.0, -2.0), Vector2(20.0, 2.0), Vector2(-20.0, 2.0),
	])
	hp_bar_bg.color = Color(0.12, 0.15, 0.22, 0.7)
	hp_bar_bg.position = Vector2(0.0, -36.0)
	hp_bar_bg.z_index = 20
	hp_bar_bg.visible = false
	add_child(hp_bar_bg)
	hp_bar_fill = Polygon2D.new()
	hp_bar_fill.polygon = PackedVector2Array([
		Vector2(-19.0, -1.5), Vector2(19.0, -1.5), Vector2(19.0, 1.5), Vector2(-19.0, 1.5),
	])
	hp_bar_fill.color = Color(0.3, 0.92, 0.4, 0.9)
	hp_bar_fill.position = Vector2(0.0, -36.0)
	hp_bar_fill.z_index = 21
	hp_bar_fill.visible = false
	add_child(hp_bar_fill)


func _refresh_hp_bar() -> void:
	if current_hp >= max_hp:
		hp_bar_bg.visible = false
		hp_bar_fill.visible = false
		return
	hp_bar_bg.visible = true
	hp_bar_fill.visible = true
	var ratio: float = float(current_hp) / float(max_hp)
	hp_bar_fill.scale.x = ratio
	hp_bar_fill.position.x = -19.0 * (1.0 - ratio)
	if ratio > 0.5:
		hp_bar_fill.color = Color(0.3, 0.92, 0.4, 0.9)
	elif ratio > 0.25:
		hp_bar_fill.color = Color(1.0, 0.82, 0.2, 0.9)
	else:
		hp_bar_fill.color = Color(1.0, 0.22, 0.18, 0.95)


func _spawn_hit_number() -> void:
	var text_label := Label.new()
	text_label.text = "1"
	text_label.add_theme_font_size_override("font_size", 16)
	text_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7, 1.0))
	text_label.z_index = 25
	text_label.global_position = global_position + Vector2(randf_range(-8.0, 8.0), -42.0)
	get_parent().add_child(text_label)
	var tween := text_label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(text_label, "global_position:y", text_label.global_position.y - 28.0, 0.4)
	tween.tween_property(text_label, "modulate:a", 0.0, 0.45)
	tween.set_parallel(false)
	tween.tween_callback(text_label.queue_free)


func _spawn_defeat_number() -> void:
	var text_label := Label.new()
	text_label.text = "+150"
	text_label.add_theme_font_size_override("font_size", 20)
	text_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.32, 1.0))
	text_label.z_index = 25
	text_label.global_position = global_position + Vector2(-12.0, -46.0)
	get_parent().add_child(text_label)
	var tween := text_label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(text_label, "global_position:y", text_label.global_position.y - 36.0, 0.5)
	tween.tween_property(text_label, "modulate:a", 0.0, 0.55)
	tween.tween_property(text_label, "scale", Vector2.ONE * 1.3, 0.2)
	tween.set_parallel(false)
	tween.tween_callback(text_label.queue_free)

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
		_defeat(true, true)


func receive_hit(force: Vector2) -> void:
	knocked_velocity = force
	hit_flash_timer = 0.18
	_refresh_hp_bar()
	_spawn_hit_number()
	if current_hp <= 0:
		_defeat(true, false)
	fire_cooldown_timer = maxf(fire_cooldown_timer, 0.35)
	aim_flash_timer = 0.0


func _update_timers(delta: float) -> void:
	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
	if fire_cooldown_timer > 0.0:
		fire_cooldown_timer -= delta
	else:
		aim_flash_timer = minf(0.24, aim_flash_timer + delta)


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
	stride_phase += delta * clampf(absf(velocity.x) / 75.0, 0.7, 2.2)


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
	aim_flash_timer = 0.0


func _try_contact_damage() -> void:
	if not is_instance_valid(player) or GameState.is_run_failed:
		return
	if global_position.distance_to(player.global_position) <= CONTACT_RANGE:
		var push_direction := signf(player.global_position.x - global_position.x)
		if push_direction == 0.0:
			push_direction = facing if facing != 0.0 else 1.0
		player.take_contact_hit(push_direction, "enemy", "suppressor_body")


func _refresh_visuals() -> void:
	if facing != 0.0:
		rig.scale.x = facing
	var stride := 1.0 + sin(stride_phase) * 0.05 if absf(velocity.x) > 8.0 and is_on_floor() else 1.0
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
		var ready_mix := clampf(aim_flash_timer / 0.24, 0.0, 1.0)
		visor_visual.color = Color(0.9 + ready_mix * 0.1, 0.95 - ready_mix * 0.18, 1.0 - ready_mix * 0.45)
		art_sprite.modulate = Color(1.0, 1.0, 1.0)
	body_visual.scale.y = stride
	muzzle.scale = Vector2.ONE * (1.0 + clampf(aim_flash_timer / 0.24, 0.0, 1.0) * 0.16)


func _defeat(award_points: bool = true, env_kill: bool = false) -> void:
	if defeated_once:
		return
	defeated_once = true
	if award_points:
		var pts := int(POINTS_AWARD * 0.5) if env_kill else POINTS_AWARD
		defeated.emit(pts)
	queue_free()
