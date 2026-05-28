extends CharacterBody2D

signal defeated(points: int)

const SPEED := 132.0
const GRAVITY := 1500.0
const CONTACT_RANGE := 30.0
const POINTS_AWARD := 100

@onready var body_visual: Polygon2D = $Body
@onready var art_sprite: Sprite2D = $Art

var player: Node2D
var knocked_velocity: Vector2 = Vector2.ZERO
var defeated_once: bool = false
var hit_flash_timer: float = 0.0
var stride_phase: float = randf() * TAU
var max_hp: int = 2
var current_hp: int = 2
var hp_bar_bg: Polygon2D
var hp_bar_fill: Polygon2D
var hit_text_timer: float = 0.0
var dash_attack_timer: float = 0.0
var dash_attack_cooldown: float = 0.0
var is_dashing: bool = false
var dash_direction: float = 0.0
const DASH_ATTACK_SPEED := 320.0
const DASH_ATTACK_DURATION := 0.22
const DASH_ATTACK_COOLDOWN := 2.8
const DASH_ATTACK_RANGE := 220.0


func _ready() -> void:
	add_to_group("enemy")
	current_hp = max_hp
	_setup_hp_bar()


func _setup_hp_bar() -> void:
	hp_bar_bg = Polygon2D.new()
	hp_bar_bg.polygon = PackedVector2Array([
		Vector2(-18.0, -2.0), Vector2(18.0, -2.0), Vector2(18.0, 2.0), Vector2(-18.0, 2.0),
	])
	hp_bar_bg.color = Color(0.12, 0.15, 0.22, 0.7)
	hp_bar_bg.position = Vector2(0.0, -32.0)
	hp_bar_bg.z_index = 20
	hp_bar_bg.visible = false
	add_child(hp_bar_bg)
	hp_bar_fill = Polygon2D.new()
	hp_bar_fill.polygon = PackedVector2Array([
		Vector2(-17.0, -1.5), Vector2(17.0, -1.5), Vector2(17.0, 1.5), Vector2(-17.0, 1.5),
	])
	hp_bar_fill.color = Color(0.3, 0.92, 0.4, 0.9)
	hp_bar_fill.position = Vector2(0.0, -32.0)
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
	hp_bar_fill.position.x = -17.0 * (1.0 - ratio)
	if ratio > 0.5:
		hp_bar_fill.color = Color(0.3, 0.92, 0.4, 0.9)
	elif ratio > 0.25:
		hp_bar_fill.color = Color(1.0, 0.82, 0.2, 0.9)
	else:
		hp_bar_fill.color = Color(1.0, 0.22, 0.18, 0.95)


func _physics_process(delta: float) -> void:
	if defeated_once:
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if knocked_velocity.length() > 1.0:
		velocity = knocked_velocity
		knocked_velocity = knocked_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	elif is_instance_valid(player) and not GameState.is_run_failed:
		_update_dash_attack(delta)
		if is_dashing:
			velocity.x = dash_direction * DASH_ATTACK_SPEED
		else:
			var direction := signf(player.global_position.x - global_position.x)
			velocity.x = direction * SPEED * GameState.get_modifier_value("speed_multiplier", 1.0)
			body_visual.scale.x = direction if direction != 0.0 else body_visual.scale.x
	stride_phase += delta * clampf(absf(velocity.x) / 80.0, 0.8, 2.6)
	move_and_slide()
	_try_contact_damage()
	_update_flash(delta)
	if global_position.y > 920.0:
		_defeat(true, true)


func _update_dash_attack(delta: float) -> void:
	if dash_attack_cooldown > 0.0:
		dash_attack_cooldown -= delta
	if is_dashing:
		dash_attack_timer -= delta
		if dash_attack_timer <= 0.0:
			is_dashing = false
			dash_attack_cooldown = DASH_ATTACK_COOLDOWN
		return
	if dash_attack_cooldown > 0.0:
		return
	if knocked_velocity.length() > 1.0:
		return
	var dist := global_position.distance_to(player.global_position)
	if dist <= DASH_ATTACK_RANGE and dist > 40.0:
		is_dashing = true
		dash_attack_timer = DASH_ATTACK_DURATION
		dash_direction = signf(player.global_position.x - global_position.x)
		if dash_direction == 0.0:
			dash_direction = 1.0
		body_visual.scale.x = dash_direction


func receive_hit(force: Vector2) -> void:
	current_hp -= 1
	knocked_velocity = force
	hit_flash_timer = 0.18
	_refresh_hp_bar()
	_spawn_hit_number()
	if current_hp <= 0:
		_defeat(true, false)


func _try_contact_damage() -> void:
	if not is_instance_valid(player) or GameState.is_run_failed:
		return
	if global_position.distance_to(player.global_position) <= CONTACT_RANGE:
		var push_direction := signf(player.global_position.x - global_position.x)
		if push_direction == 0.0:
			push_direction = signf(body_visual.scale.x) if body_visual.scale.x != 0.0 else 1.0
		player.take_contact_hit(push_direction, "enemy", "runner_body")


func _update_flash(delta: float) -> void:
	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
		body_visual.color = Color(1.0, 0.95, 0.72)
		art_sprite.modulate = Color(1.0, 0.96, 0.78)
	elif is_dashing:
		body_visual.color = Color(1.0, 0.55, 0.28)
		art_sprite.modulate = Color(1.0, 0.82, 0.68)
	else:
		body_visual.color = Color(0.21, 0.95, 0.8)
		art_sprite.modulate = Color(1.0, 1.0, 1.0)
	var squash := 1.0 + sin(stride_phase) * 0.06 if absf(velocity.x) > 10.0 and is_on_floor() else 1.0
	body_visual.scale.y = squash
	art_sprite.scale.y = 0.22 * (1.0 + (squash - 1.0) * 0.6)


func _defeat(award_points: bool = true, env_kill: bool = false) -> void:
	if defeated_once:
		return
	defeated_once = true
	_spawn_defeat_number()
	if award_points:
		var pts := int(POINTS_AWARD * 0.5) if env_kill else POINTS_AWARD
		defeated.emit(pts)
	queue_free()


func _spawn_hit_number() -> void:
	var text_label := Label.new()
	text_label.text = "1"
	text_label.add_theme_font_size_override("font_size", 16)
	text_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7, 1.0))
	text_label.z_index = 25
	text_label.global_position = global_position + Vector2(randf_range(-8.0, 8.0), -38.0)
	get_parent().add_child(text_label)
	var tween := text_label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(text_label, "global_position:y", text_label.global_position.y - 28.0, 0.4)
	tween.tween_property(text_label, "modulate:a", 0.0, 0.45)
	tween.set_parallel(false)
	tween.tween_callback(text_label.queue_free)


func _spawn_defeat_number() -> void:
	var text_label := Label.new()
	text_label.text = "+%d" % POINTS_AWARD
	text_label.add_theme_font_size_override("font_size", 20)
	text_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.32, 1.0))
	text_label.z_index = 25
	text_label.global_position = global_position + Vector2(-12.0, -42.0)
	get_parent().add_child(text_label)
	var tween := text_label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(text_label, "global_position:y", text_label.global_position.y - 36.0, 0.5)
	tween.tween_property(text_label, "modulate:a", 0.0, 0.55)
	tween.tween_property(text_label, "scale", Vector2.ONE * 1.3, 0.2)
	tween.set_parallel(false)
	tween.tween_callback(text_label.queue_free)
