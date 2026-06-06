extends CharacterBody2D

signal player_hit
signal player_fell

const SPEED := 340.0
const JUMP_VELOCITY := -575.0
const AIR_CONTROL := 0.72
const GRAVITY := 1500.0
const DASH_SPEED := 790.0
const DASH_TIME := 0.2
const DASH_COOLDOWN := 0.52
const ATTACK_RANGE_X := 178.0
const ATTACK_RANGE_Y := 98.0
const ATTACK_FORCE := 590.0
const ATTACK_COOLDOWN := 0.16
const DAMAGE_AFTERIMAGE_LIFETIME := 0.24

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
var boost_flash_timer: float = 0.0
var attack_timer: float = 0.0
var hit_stop_timer: float = 0.0
var strike_flash_timer: float = 0.0
var trail_phase: float = 0.0
var dash_afterimages: Array[Polygon2D] = []
var dash_afterimage_timer: float = 0.0
var damage_flash_timer: float = 0.0
var damage_flash_duration: float = 0.0
var damage_afterimages: Array[Sprite2D] = []
var was_on_floor: bool = true
var landing_dust_timer: float = 0.0
var speed_line_timer: float = 0.0


func _ready() -> void:
	add_to_group("player")


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	if hit_stop_timer > 0.0:
		_refresh_visuals()
		return
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
	if attack_timer > 0.0:
		attack_timer -= delta
	if hit_stop_timer > 0.0:
		hit_stop_timer -= delta
	if invulnerable_timer > 0.0:
		invulnerable_timer -= delta
	if action_pop_timer > 0.0:
		action_pop_timer -= delta
	if camera_shake_timer > 0.0:
		camera_shake_timer -= delta
	else:
		camera_shake_strength = move_toward(camera_shake_strength, 0.0, delta * 22.0)
	if boost_flash_timer > 0.0:
		boost_flash_timer -= delta
	if strike_flash_timer > 0.0:
		strike_flash_timer -= delta
	if damage_flash_timer > 0.0:
		damage_flash_timer -= delta
	if landing_dust_timer > 0.0:
		landing_dust_timer -= delta
	if speed_line_timer > 0.0:
		speed_line_timer -= delta
	trail_phase += delta * 7.0
	_update_dash_afterimages(delta)
	_update_damage_afterimages(delta)
	_detect_landing()
	_maybe_spawn_speed_lines(delta)


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
		var move_speed := SPEED * GameState.get_modifier_value("speed_multiplier", 1.0)
		velocity.x = move_toward(velocity.x, axis * move_speed, move_speed * control * 0.18)


func _try_jump() -> void:
	if jumps_remaining <= 0:
		return
	jumps_remaining -= 1
	velocity.y = JUMP_VELOCITY * GameState.get_modifier_value("jump_multiplier", 1.0)


func _try_dash() -> void:
	if dash_timer > 0.0 or dash_cooldown_timer > 0.0:
		return
	dash_timer = DASH_TIME
	dash_cooldown_timer = DASH_COOLDOWN
	velocity.y = minf(velocity.y, -40.0)
	velocity.x = facing * DASH_SPEED * GameState.get_modifier_value("dash_multiplier", 1.0)
	action_pop_timer = 0.1
	_trigger_camera_shake(4.0, 0.1)
	AudioEngine.play_dash()


func _try_attack() -> void:
	if attack_timer > 0.0:
		return
	attack_timer = ATTACK_COOLDOWN
	var hit_any := false
	for enemy: Node in get_tree().get_nodes_in_group("enemy"):
		if not enemy.has_method("receive_hit"):
			continue
		var enemy_node := enemy as Node2D
		if enemy_node == null:
			continue
		var delta_pos: Vector2 = enemy_node.global_position - global_position
		var forward_distance := delta_pos.x * facing
		if forward_distance >= -20.0 and forward_distance <= ATTACK_RANGE_X and absf(delta_pos.y) <= ATTACK_RANGE_Y:
			var attack_force := ATTACK_FORCE * GameState.get_modifier_value("attack_force_multiplier", 1.0)
			enemy.receive_hit(Vector2(facing * attack_force, -240.0))
			_spawn_hit_spark(enemy_node.global_position - Vector2(facing * 18.0, 8.0))
			_spawn_hit_flash(enemy_node.global_position)
			hit_any = true
	action_pop_timer = 0.1
	strike_flash_timer = 0.16
	if hit_any:
		hit_stop_timer = 0.05
		AudioEngine.play_hit()
	else:
		AudioEngine.play_attack()
	_trigger_camera_shake(3.5 if not hit_any else 7.0, 0.14)


func _apply_gravity(delta: float) -> void:
	if dash_timer > 0.0:
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta


func _handle_horizontal_motion(delta: float) -> void:
	if dash_timer > 0.0:
		velocity.x = facing * DASH_SPEED * GameState.get_modifier_value("dash_multiplier", 1.0)
		return
	if is_on_floor() and absf(Input.get_axis("move_left", "move_right")) < 0.1 and absf(InputRouter.move_axis) < 0.1:
		velocity.x = move_toward(velocity.x, 0.0, SPEED * GameState.get_modifier_value("speed_multiplier", 1.0) * delta * 5.0)


func _handle_fall_check() -> void:
	if global_position.y > 920.0:
		player_fell.emit()


func take_contact_hit(push_direction: float, source_kind: String = "enemy", source_detail: String = "") -> void:
	if invulnerable_timer > 0.0 or GameState.is_run_failed:
		return
	GameState.register_damage_source(source_kind, source_detail)
	var heavy_hit := _is_heavy_damage_source(source_kind, source_detail)
	var hit_direction := push_direction
	if hit_direction == 0.0:
		hit_direction = -facing if facing != 0.0 else 1.0
	invulnerable_timer = 0.65
	velocity = Vector2(hit_direction * (340.0 if heavy_hit else 260.0), -270.0 if heavy_hit else -220.0)
	action_pop_timer = 0.24 if heavy_hit else 0.16
	damage_flash_duration = 0.34 if heavy_hit else 0.24
	damage_flash_timer = damage_flash_duration
	hit_stop_timer = maxf(hit_stop_timer, 0.085 if heavy_hit else 0.055)
	_trigger_camera_shake(12.0 if heavy_hit else 8.0, 0.24 if heavy_hit else 0.18)
	_spawn_damage_afterimage(hit_direction, heavy_hit)
	_spawn_damage_burst(hit_direction, heavy_hit)
	player_hit.emit()
	AudioEngine.play_damage()


func apply_launch_boost(boost_velocity: Vector2) -> void:
	velocity = boost_velocity
	facing = signf(boost_velocity.x) if boost_velocity.x != 0.0 else facing
	action_pop_timer = maxf(action_pop_timer, 0.12)
	boost_flash_timer = 0.2
	_trigger_camera_shake(6.5, 0.16)


func _refresh_visuals() -> void:
	var damage_mix := clampf(damage_flash_timer / maxf(0.01, damage_flash_duration), 0.0, 1.0)
	var damage_strobe := 0.5 + absf(sin(trail_phase * 5.4)) * 0.5
	if damage_flash_timer > 0.0:
		body_visual.color = Color(1.0, 0.95 - damage_mix * 0.18, 0.78 - damage_mix * 0.28)
	elif invulnerable_timer > 0.0:
		body_visual.color = Color(1.0, 0.85, 0.42)
	elif strike_flash_timer > 0.0:
		body_visual.color = Color(1.0, 0.62, 0.48)
	elif boost_flash_timer > 0.0:
		body_visual.color = Color(0.74, 0.98, 1.0)
	else:
		body_visual.color = Color(1.0, 0.35, 0.54)
	var impact_strength := clampf(action_pop_timer * 8.0, 0.0, 1.0)
	var locomotion_bob := 0.03 * sin(trail_phase) if is_on_floor() and absf(velocity.x) > 120.0 else 0.0
	body_visual.scale = Vector2(facing * (1.0 + impact_strength * 0.14), 1.0 - impact_strength * 0.08 + locomotion_bob)
	if damage_flash_timer > 0.0:
		art_sprite.modulate = Color(1.0, 1.0 - damage_mix * 0.16, 0.84 - damage_mix * 0.16, 1.0).lerp(Color(1.0, 1.0, 1.0, 1.0), damage_strobe * 0.45)
	elif invulnerable_timer > 0.0:
		art_sprite.modulate = Color(1.0, 0.9, 0.72)
	elif strike_flash_timer > 0.0:
		art_sprite.modulate = Color(1.0, 0.86, 0.78)
	elif boost_flash_timer > 0.0:
		art_sprite.modulate = Color(0.84, 0.98, 1.0)
	else:
		art_sprite.modulate = Color(1.0, 1.0, 1.0)
	art_sprite.scale = Vector2(0.25 * facing * (1.0 + impact_strength * 0.08), 0.25 * (1.0 - impact_strength * 0.04 + locomotion_bob * 0.35))
	camera.position.x = lerpf(camera.position.x, 90.0 * facing, 0.08)
	var shake_target := Vector2.ZERO
	if camera_shake_timer > 0.0:
		shake_target = Vector2(randf_range(-camera_shake_strength, camera_shake_strength), randf_range(-camera_shake_strength, camera_shake_strength))
	camera.offset = camera.offset.lerp(shake_target, 0.32)


func _spawn_hit_spark(at_position: Vector2) -> void:
	var spark := Polygon2D.new()
	spark.polygon = PackedVector2Array([
		Vector2(0.0, -8.0),
		Vector2(38.0 * facing, -2.0),
		Vector2(0.0, 8.0),
		Vector2(-10.0 * facing, 0.0),
	])
	spark.global_position = at_position
	spark.color = Color(1.0, 0.86, 0.42, 0.95)
	spark.z_index = 18
	get_tree().current_scene.add_child(spark)
	var tween := spark.create_tween()
	tween.set_parallel(true)
	tween.tween_property(spark, "scale", Vector2(1.9, 0.45), 0.12).from(Vector2(0.45, 1.0))
	tween.tween_property(spark, "modulate:a", 0.0, 0.14)
	tween.set_parallel(false)
	tween.tween_callback(spark.queue_free)


func _spawn_hit_flash(at_position: Vector2) -> void:
	var flash := Polygon2D.new()
	flash.polygon = PackedVector2Array()
	for step in 10:
		var angle := TAU * float(step) / 10.0
		var radius := 16.0 if step % 2 == 0 else 6.0
		flash.polygon.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	flash.global_position = at_position
	flash.color = Color(1.0, 1.0, 1.0, 0.8)
	flash.z_index = 19
	get_tree().current_scene.add_child(flash)
	var tween := flash.create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector2.ONE * 1.5, 0.08).from(Vector2.ONE * 0.3)
	tween.tween_property(flash, "modulate:a", 0.0, 0.1)
	tween.set_parallel(false)
	tween.tween_callback(flash.queue_free)


func _trigger_camera_shake(strength: float, duration: float) -> void:
	camera_shake_strength = maxf(camera_shake_strength, strength)
	camera_shake_timer = duration


func _is_heavy_damage_source(source_kind: String, source_detail: String) -> bool:
	if source_kind == "hazard":
		return true
	return source_detail in ["stalker_landing", "bastion_shockwave", "phantom_dive"]


func _update_dash_afterimages(delta: float) -> void:
	for index in range(dash_afterimages.size() - 1, -1, -1):
		var image := dash_afterimages[index]
		if not is_instance_valid(image):
			dash_afterimages.remove_at(index)
			continue
		var life := float(image.get_meta("life", 0.22)) - delta
		if life <= 0.0:
			image.queue_free()
			dash_afterimages.remove_at(index)
			continue
		image.set_meta("life", life)
		image.modulate.a = clampf(life / 0.22, 0.0, 1.0) * 0.3
	if dash_timer <= 0.0:
		dash_afterimage_timer = 0.0
		return
	dash_afterimage_timer -= delta
	if dash_afterimage_timer <= 0.0:
		dash_afterimage_timer = 0.045
		_spawn_dash_afterimage()


func _spawn_dash_afterimage() -> void:
	var image := Polygon2D.new()
	image.polygon = body_visual.polygon
	image.global_position = global_position
	image.scale = body_visual.scale
	image.color = Color(0.45, 0.85, 1.0, 0.3)
	image.z_index = body_visual.z_index - 1
	image.set_meta("life", 0.22)
	get_tree().current_scene.add_child(image)
	dash_afterimages.append(image)


func _update_damage_afterimages(delta: float) -> void:
	for index in range(damage_afterimages.size() - 1, -1, -1):
		var image := damage_afterimages[index]
		if not is_instance_valid(image):
			damage_afterimages.remove_at(index)
			continue
		var life := float(image.get_meta("life", DAMAGE_AFTERIMAGE_LIFETIME)) - delta
		if life <= 0.0:
			image.queue_free()
			damage_afterimages.remove_at(index)
			continue
		image.set_meta("life", life)
		image.modulate.a = clampf(life / DAMAGE_AFTERIMAGE_LIFETIME, 0.0, 1.0) * 0.34


func _spawn_damage_afterimage(push_direction: float, heavy_hit: bool) -> void:
	var image := Sprite2D.new()
	image.texture = art_sprite.texture
	image.global_position = art_sprite.global_position - Vector2(push_direction * (20.0 if heavy_hit else 12.0), 0.0)
	image.global_rotation = art_sprite.global_rotation
	image.global_scale = art_sprite.global_scale * (1.08 if heavy_hit else 1.0)
	image.modulate = Color(1.0, 0.38 if heavy_hit else 0.55, 0.32 if heavy_hit else 0.46, 0.34)
	image.z_index = art_sprite.z_index - 1
	image.set_meta("life", DAMAGE_AFTERIMAGE_LIFETIME)
	get_tree().current_scene.add_child(image)
	damage_afterimages.append(image)


func _spawn_damage_burst(push_direction: float, heavy_hit: bool) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var shard_count := 8 if heavy_hit else 5
	var spread := 78.0 if heavy_hit else 48.0
	for index in shard_count:
		var shard := Polygon2D.new()
		shard.polygon = PackedVector2Array([
			Vector2(0.0, -3.5),
			Vector2(18.0, 0.0),
			Vector2(0.0, 3.5),
		])
		var angle := lerpf(-0.92, 0.92, float(index) / maxf(1.0, float(shard_count - 1)))
		var direction := Vector2(push_direction, 0.0).rotated(angle)
		shard.global_position = global_position + Vector2(-push_direction * 10.0, -10.0)
		shard.rotation = direction.angle()
		shard.color = Color(1.0, 0.34 if heavy_hit else 0.58, 0.24 if heavy_hit else 0.42, 0.86)
		shard.z_index = 24
		scene.add_child(shard)
		var tween := shard.create_tween()
		tween.set_parallel(true)
		tween.tween_property(shard, "global_position", shard.global_position + direction * spread, 0.16 if heavy_hit else 0.12)
		tween.tween_property(shard, "modulate:a", 0.0, 0.18)
		tween.tween_property(shard, "scale", Vector2.ONE * 0.32, 0.18)
		tween.set_parallel(false)
		tween.tween_callback(shard.queue_free)
	var ring := Polygon2D.new()
	ring.polygon = PackedVector2Array()
	for step in 18:
		var angle := TAU * float(step) / 18.0
		var radius := 22.0 if step % 2 == 0 else 9.0
		ring.polygon.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	ring.global_position = global_position + Vector2(0.0, -10.0)
	ring.color = Color(1.0, 0.92, 0.82, 0.62 if heavy_hit else 0.42)
	ring.z_index = 23
	scene.add_child(ring)
	var ring_tween := ring.create_tween()
	ring_tween.set_parallel(true)
	ring_tween.tween_property(ring, "scale", Vector2.ONE * (2.0 if heavy_hit else 1.45), 0.14).from(Vector2.ONE * 0.35)
	ring_tween.tween_property(ring, "modulate:a", 0.0, 0.16)
	ring_tween.set_parallel(false)
	ring_tween.tween_callback(ring.queue_free)


func _detect_landing() -> void:
	if is_on_floor() and not was_on_floor:
		_spawn_landing_dust()
		AudioEngine.play_land()
	was_on_floor = is_on_floor()


func _spawn_landing_dust() -> void:
	if landing_dust_timer > 0.0:
		return
	landing_dust_timer = 0.15
	for index in 5:
		var dust := Polygon2D.new()
		var angle := PI + float(index) / 4.0 * PI
		dust.polygon = PackedVector2Array([
			Vector2(-3.0, -2.0), Vector2(3.0, -2.0), Vector2(4.0, 2.0), Vector2(-4.0, 2.0),
		])
		dust.global_position = global_position + Vector2(0.0, 4.0)
		dust.color = Color(0.6, 0.55, 0.5, 0.35)
		dust.z_index = -1
		get_tree().current_scene.add_child(dust)
		var tween := dust.create_tween()
		tween.set_parallel(true)
		tween.tween_property(dust, "global_position", dust.global_position + Vector2(cos(angle) * 28.0, -absf(sin(angle)) * 8.0), 0.18)
		tween.tween_property(dust, "modulate:a", 0.0, 0.2)
		tween.set_parallel(false)
		tween.tween_callback(dust.queue_free)


func _maybe_spawn_speed_lines(delta: float) -> void:
	if not is_on_floor() or absf(velocity.x) < SPEED * 0.85:
		return
	speed_line_timer -= delta
	if speed_line_timer > 0.0:
		return
	speed_line_timer = 0.08
	var line := Polygon2D.new()
	var line_length := randf_range(18.0, 36.0)
	var line_y := randf_range(-20.0, 16.0)
	var direction := signf(velocity.x)
	line.polygon = PackedVector2Array([
		Vector2(0.0, -0.8), Vector2(line_length * direction, -0.4),
		Vector2(line_length * direction, 0.4), Vector2(0.0, 0.8),
	])
	line.global_position = global_position + Vector2(-direction * randf_range(12.0, 28.0), line_y)
	line.color = Color(0.7, 0.88, 1.0, 0.22)
	line.z_index = -2
	get_tree().current_scene.add_child(line)
	var tween := line.create_tween()
	tween.set_parallel(true)
	tween.tween_property(line, "global_position:x", line.global_position.x - direction * 40.0, 0.12)
	tween.tween_property(line, "modulate:a", 0.0, 0.14)
	tween.set_parallel(false)
	tween.tween_callback(line.queue_free)
