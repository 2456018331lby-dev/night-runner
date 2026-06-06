extends CharacterBody2D

signal defeated(points: int)

const WALK_SPEED := 128.0
const GRAVITY := 1500.0
const CONTACT_RANGE := 30.0
const DIVE_RANGE_X := 420.0
const DIVE_RANGE_Y := 210.0
const DIVE_SPEED_X := 460.0
const DIVE_SPEED_Y := -250.0
const DIVE_COOLDOWN := 2.25
const DIVE_RECOVERY_TIME := 0.22
const WINDUP_TIME := 0.42
const DIVE_TIME := 0.34
const AFTERIMAGE_INTERVAL := 0.055
const AFTERIMAGE_LIFETIME := 0.24
const POINTS_AWARD := 220

@onready var rig: Node2D = $Rig
@onready var body_visual: Polygon2D = $Rig/Body
@onready var blade_visual: Polygon2D = $Rig/Blade
@onready var eye_visual: Polygon2D = $Rig/Eye
@onready var trail: Polygon2D = $Rig/Trail
@onready var warning_line: Line2D = Line2D.new()
@onready var warning_ring: Polygon2D = Polygon2D.new()

var player: Node2D
var knocked_velocity: Vector2 = Vector2.ZERO
var defeated_once: bool = false
var hit_flash_timer: float = 0.0
var dive_cooldown_timer: float = 0.8
var windup_timer: float = 0.0
var dive_timer: float = 0.0
var facing: float = -1.0
var stride_phase: float = randf() * TAU
var max_hp: int = 3
var current_hp: int = 3
var hp_bar_bg: Polygon2D
var hp_bar_fill: Polygon2D
var afterimage_timer: float = 0.0
var afterimages: Array[Polygon2D] = []


func _ready() -> void:
	add_to_group("enemy")
	current_hp = max_hp
	_setup_hp_bar()
	_setup_warning_visuals()


func _setup_warning_visuals() -> void:
	warning_line.width = 4.0
	warning_line.default_color = Color(0.82, 1.0, 0.92, 1.0)
	warning_line.points = PackedVector2Array([Vector2.ZERO, Vector2(DIVE_RANGE_X * 0.78, 0.0)])
	warning_line.z_index = -1
	warning_line.visible = false
	add_child(warning_line)
	warning_ring.polygon = PackedVector2Array([
		Vector2(0, -32),
		Vector2(24, -18),
		Vector2(32, 0),
		Vector2(24, 18),
		Vector2(0, 32),
		Vector2(-24, 18),
		Vector2(-32, 0),
		Vector2(-24, -18),
	])
	warning_ring.color = Color(0.5, 1.0, 0.94, 1.0)
	warning_ring.z_index = -2
	warning_ring.visible = false
	add_child(warning_ring)




func _setup_hp_bar() -> void:
	hp_bar_bg = Polygon2D.new()
	hp_bar_bg.polygon = PackedVector2Array([
		Vector2(-18.0, -2.0), Vector2(18.0, -2.0), Vector2(18.0, 2.0), Vector2(-18.0, 2.0),
	])
	hp_bar_bg.color = Color(0.12, 0.15, 0.22, 0.7)
	hp_bar_bg.position = Vector2(0.0, -34.0)
	hp_bar_bg.z_index = 20
	hp_bar_bg.visible = false
	add_child(hp_bar_bg)
	hp_bar_fill = Polygon2D.new()
	hp_bar_fill.polygon = PackedVector2Array([
		Vector2(-17.0, -1.5), Vector2(17.0, -1.5), Vector2(17.0, 1.5), Vector2(-17.0, 1.5),
	])
	hp_bar_fill.color = Color(0.3, 0.92, 0.4, 0.9)
	hp_bar_fill.position = Vector2(0.0, -34.0)
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
	text_label.text = "+220"
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
	_try_begin_dive()
	_update_afterimages(delta)
	_refresh_visuals()
	if global_position.y > 920.0:
		_defeat(true, true)


func receive_hit(force: Vector2) -> void:
	current_hp -= 1
	knocked_velocity = force * 1.1
	hit_flash_timer = 0.2
	_refresh_hp_bar()
	_spawn_hit_number()
	if current_hp <= 0:
		_defeat(true, false)
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
	windup_timer = WINDUP_TIME


func _launch_dive() -> void:
	dive_timer = DIVE_TIME
	dive_cooldown_timer = DIVE_COOLDOWN
	velocity.x = facing * DIVE_SPEED_X
	velocity.y = DIVE_SPEED_Y
	AudioEngine.play_phantom_dive()


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


func _update_afterimages(delta: float) -> void:
	for index in range(afterimages.size() - 1, -1, -1):
		var image := afterimages[index]
		if not is_instance_valid(image):
			afterimages.remove_at(index)
			continue
		var next_life := float(image.get_meta("life", AFTERIMAGE_LIFETIME)) - delta
		if next_life <= 0.0:
			image.queue_free()
			afterimages.remove_at(index)
			continue
		image.set_meta("life", next_life)
		image.modulate.a = clampf(next_life / AFTERIMAGE_LIFETIME, 0.0, 1.0) * 0.28
	if dive_timer <= 0.0:
		afterimage_timer = 0.0
		return
	afterimage_timer -= delta
	if afterimage_timer <= 0.0:
		afterimage_timer = AFTERIMAGE_INTERVAL
		_spawn_afterimage()


func _spawn_afterimage() -> void:
	var image := Polygon2D.new()
	image.polygon = body_visual.polygon
	image.global_position = global_position
	image.global_rotation = rig.global_rotation
	image.global_scale = rig.global_scale
	image.color = Color(0.5, 1.0, 0.94, 1.0)
	image.modulate.a = 0.28
	image.z_index = -3
	image.set_meta("life", AFTERIMAGE_LIFETIME)
	get_parent().add_child(image)
	afterimages.append(image)


func _refresh_visuals() -> void:
	if facing != 0.0:
		rig.scale.x = facing
	var windup_mix := clampf(1.0 - windup_timer / WINDUP_TIME, 0.0, 1.0) if windup_timer > 0.0 else 0.0
	var dive_mix := clampf(dive_timer / DIVE_TIME, 0.0, 1.0)
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
	warning_line.visible = windup_timer > 0.0 or dive_timer > 0.0
	warning_ring.visible = windup_timer > 0.0
	warning_line.scale.x = facing if facing != 0.0 else 1.0
	warning_line.modulate.a = windup_mix * 0.72 + dive_mix * 0.26
	warning_ring.modulate.a = windup_mix * 0.3
	warning_ring.scale = Vector2.ONE * (0.75 + windup_mix * 0.55)


func _defeat(award_points: bool = true, env_kill: bool = false) -> void:
	if defeated_once:
		return
	defeated_once = true
	for image in afterimages:
		if is_instance_valid(image):
			image.queue_free()
	afterimages.clear()
	_spawn_defeat_number()
	if award_points:
		var pts := int(POINTS_AWARD * 0.5) if env_kill else POINTS_AWARD
		defeated.emit(pts)
	queue_free()
