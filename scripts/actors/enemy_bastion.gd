extends CharacterBody2D

signal defeated(points: int)

const WALK_SPEED := 64.0
const GRAVITY := 1500.0
const CONTACT_RANGE := 38.0
const PRESSURE_RANGE_X := 380.0
const PRESSURE_RANGE_Y := 180.0
const SHOCK_COOLDOWN := 2.55
const SHOCK_WINDUP := 0.68
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
var max_hp: int = 5
var current_hp: int = 5
var hp_bar_bg: Polygon2D
var hp_bar_fill: Polygon2D


func _ready() -> void:
	add_to_group("enemy")
	pulse_zone.monitoring = true
	pulse_zone.monitorable = false
	pulse_zone.body_entered.connect(_on_pulse_zone_body_entered)
	_set_pulse_active(false)




func _setup_hp_bar() -> void:
	hp_bar_bg = Polygon2D.new()
	hp_bar_bg.polygon = PackedVector2Array([
		Vector2(-24.0, -2.0), Vector2(24.0, -2.0), Vector2(24.0, 2.0), Vector2(-24.0, 2.0),
	])
	hp_bar_bg.color = Color(0.12, 0.15, 0.22, 0.7)
	hp_bar_bg.position = Vector2(0.0, -38.0)
	hp_bar_bg.z_index = 20
	hp_bar_bg.visible = false
	add_child(hp_bar_bg)
	hp_bar_fill = Polygon2D.new()
	hp_bar_fill.polygon = PackedVector2Array([
		Vector2(-23.0, -1.5), Vector2(23.0, -1.5), Vector2(23.0, 1.5), Vector2(-23.0, 1.5),
	])
	hp_bar_fill.color = Color(0.3, 0.92, 0.4, 0.9)
	hp_bar_fill.position = Vector2(0.0, -38.0)
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
	hp_bar_fill.position.x = -23.0 * (1.0 - ratio)
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
	text_label.text = "+260"
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
	_try_begin_shockwave()
	_refresh_visuals()
	if global_position.y > 920.0:
		_defeat(true, true)


func receive_hit(force: Vector2) -> void:
	knocked_velocity = force * 0.82
	hit_flash_timer = 0.24
	_refresh_hp_bar()
	_spawn_hit_number()
	if current_hp <= 0:
		_defeat(true, false)
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
	AudioEngine.play_bastion_shock()


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
		var push_direction := signf(player.global_position.x - global_position.x)
		if push_direction == 0.0:
			push_direction = facing if facing != 0.0 else 1.0
		player.take_contact_hit(push_direction, "enemy", "bastion_body")


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


func _defeat(award_points: bool = true, env_kill: bool = false) -> void:
	if defeated_once:
		return
	defeated_once = true
	if award_points:
		var pts := int(POINTS_AWARD * 0.5) if env_kill else POINTS_AWARD
		defeated.emit(pts)
	queue_free()
