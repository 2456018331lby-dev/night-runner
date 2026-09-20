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
const JUMP_BUFFER_TIME := 0.14
const ATTACK_BUFFER_TIME := 0.12
const COYOTE_TIME := 0.1
# 世界坠落判定线；低于它即视为掉出关卡。
const FALL_LINE_Y := 920.0

const RUN_FRAMES: Array[Texture2D] = [
	preload("res://assets/art/anim_run_0.png"),
	preload("res://assets/art/anim_run_1.png"),
	preload("res://assets/art/anim_run_2.png"),
	preload("res://assets/art/anim_run_3.png"),
	preload("res://assets/art/anim_run_4.png"),
	preload("res://assets/art/anim_run_5.png"),
	preload("res://assets/art/anim_run_6.png"),
	preload("res://assets/art/anim_run_7.png"),
]

const ATTACK_FRAMES: Array[Texture2D] = [
	preload("res://assets/art/anim_attack_0.png"),
	preload("res://assets/art/anim_attack_1.png"),
	preload("res://assets/art/anim_attack_2.png"),
	preload("res://assets/art/anim_attack_3.png"),
	preload("res://assets/art/anim_attack_4.png"),
	preload("res://assets/art/anim_attack_5.png"),
]

const TEX_RUN := preload("res://assets/art/sprite_player_run.png")
const TEX_JUMP := preload("res://assets/art/sprite_player_jump.png")
const TEX_ATTACK := preload("res://assets/art/sprite_player_attack.png")
const TEX_DASH := preload("res://assets/art/sprite_player_dash.png")

@onready var body_visual: Polygon2D = $Body
@onready var art_sprite: Sprite2D = $Art
@onready var camera: Camera2D = $Camera2D

var anim_run_timer: float = 0.0
var anim_attack_timer: float = 0.0
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
var jump_buffer_timer: float = 0.0
var coyote_timer: float = 0.0
var time_dip_generation: int = 0
var land_squash_timer: float = 0.0
var land_squash_duration: float = 0.12
var land_squash_strength: float = 0.0
var jump_stretch_timer: float = 0.0
var air_fall_speed: float = 0.0
var camera_kick_vector: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("player")


func _time_effects_allowed() -> bool:
	return DisplayServer.get_name() != "headless"


func _apply_hitstop(duration: float, dip_scale: float = 0.05) -> void:
	if not _time_effects_allowed():
		return
	time_dip_generation += 1
	var generation := time_dip_generation
	Engine.time_scale = dip_scale
	get_tree().create_timer(duration, true, false, true).timeout.connect(func() -> void:
		if generation == time_dip_generation:
			Engine.time_scale = 1.0
	)


func trigger_kill_slowmo() -> void:
	_apply_hitstop(0.08, 0.3)
	_trigger_camera_shake(5.0, 0.12)


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	if hit_stop_timer > 0.0:
		_refresh_visuals()
		return
	_collect_actions()
	_consume_jump_buffer_if_possible()
	_apply_gravity(delta)
	_handle_horizontal_motion(delta)
	_handle_fall_check()
	move_and_slide()
	_refresh_visuals()


func _update_timers(delta: float) -> void:
	_refresh_jump_windows(delta, is_on_floor())
	if is_on_floor() and absf(velocity.x) > 20.0:
		anim_run_timer += delta * (absf(velocity.x) / 340.0) * 16.0
	else:
		anim_run_timer = 0.0
	if strike_flash_timer > 0.0 or attack_timer > 0.0:
		anim_attack_timer += delta * 24.0
	else:
		anim_attack_timer = 0.0
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
	if land_squash_timer > 0.0:
		land_squash_timer -= delta
	if jump_stretch_timer > 0.0:
		jump_stretch_timer -= delta
	camera_kick_vector = camera_kick_vector.move_toward(Vector2.ZERO, delta * 70.0)
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
		_queue_jump()
	if Input.is_action_just_pressed("dash") or InputRouter.consume_dash():
		_try_dash()
	if Input.is_action_just_pressed("attack") or Input.is_action_pressed("attack") or InputRouter.consume_attack() or InputRouter.is_action_held("attack"):
		_try_attack()

	if dash_timer <= 0.0:
		var control := 1.0 if is_on_floor() else AIR_CONTROL
		var move_speed := SPEED * GameState.get_modifier_value("speed_multiplier", 1.0)
		velocity.x = move_toward(velocity.x, axis * move_speed, move_speed * control * 0.18)


func _queue_jump() -> void:
	jump_buffer_timer = JUMP_BUFFER_TIME


func _try_jump() -> bool:
	if jumps_remaining <= 0:
		return false
	jumps_remaining -= 1
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	velocity.y = JUMP_VELOCITY * GameState.get_modifier_value("jump_multiplier", 1.0)
	jump_stretch_timer = 0.12
	return true


func _consume_jump_buffer_if_possible() -> bool:
	if jump_buffer_timer <= 0.0:
		return false
	return _try_jump()


func _refresh_jump_windows(delta: float, grounded: bool) -> void:
	if grounded:
		jumps_remaining = 2
		coyote_timer = COYOTE_TIME
	else:
		if coyote_timer > 0.0:
			coyote_timer = maxf(0.0, coyote_timer - delta)
		if coyote_timer <= 0.0 and jumps_remaining > 1:
			jumps_remaining = 1
	if jump_buffer_timer > 0.0:
		jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)


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
	velocity.x = facing * maxf(absf(velocity.x) + 40.0, 180.0)
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
	_spawn_attack_arc()
	if hit_any:
		hit_stop_timer = 0.05
		_apply_hitstop(0.05)
		AudioEngine.play_hit()
	else:
		AudioEngine.play_attack()
	_trigger_camera_shake(3.5 if not hit_any else 7.0, 0.14)


func _apply_gravity(delta: float) -> void:
	if dash_timer > 0.0:
		return
	if not is_on_floor():
		var grav_mult := 1.0
		# Jump apex float: slight hang time when near the peak of a jump for silky platforming control
		if absf(velocity.y) < 110.0 and not is_on_floor():
			grav_mult = 0.76
		velocity.y += GRAVITY * grav_mult * delta


func _handle_horizontal_motion(delta: float) -> void:
	if dash_timer > 0.0:
		velocity.x = facing * DASH_SPEED * GameState.get_modifier_value("dash_multiplier", 1.0)
		return
	if is_on_floor() and absf(Input.get_axis("move_left", "move_right")) < 0.1 and absf(InputRouter.move_axis) < 0.1:
		velocity.x = move_toward(velocity.x, 0.0, SPEED * GameState.get_modifier_value("speed_multiplier", 1.0) * delta * 5.0)


func _handle_fall_check() -> void:
	# 只在跑动中判定：坠落会连续多帧低于判定线，收尾后必须停止重复触发。
	if not GameState.is_run_active or GameState.is_run_failed or GameState.run_success:
		return
	if global_position.y > FALL_LINE_Y:
		player_fell.emit()


func take_contact_hit(push_direction: float, source_kind: String = "enemy", source_detail: String = "") -> void:
	if invulnerable_timer > 0.0 or GameState.is_run_failed or GameState.run_success or not GameState.is_run_active:
		return
	GameState.register_damage_source(source_kind, source_detail, global_position)
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
	_apply_hitstop(0.085 if heavy_hit else 0.055)
	camera_kick_vector = Vector2(-hit_direction * 10.0, -4.0 if heavy_hit else -2.0)
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
	body_visual.visible = false
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
	var squash_mix := clampf(land_squash_timer / maxf(0.01, land_squash_duration), 0.0, 1.0) * land_squash_strength
	var stretch_mix := clampf(jump_stretch_timer / 0.12, 0.0, 1.0)
	var scale_x_mix := 1.0 + impact_strength * 0.14 + squash_mix * 0.12 - stretch_mix * 0.12
	var scale_y_mix := 1.0 - impact_strength * 0.08 + locomotion_bob - squash_mix * 0.18 + stretch_mix * 0.14
	body_visual.scale = Vector2(facing * scale_x_mix, scale_y_mix)

	# Dynamic Action Multi-frame Sprite Switching
	var base_scale := 0.095
	var sprite_offset := Vector2(0, -2)
	if dash_timer > 0.0:
		art_sprite.texture = TEX_DASH
		base_scale = 0.095
		sprite_offset = Vector2(0, -2)
	elif strike_flash_timer > 0.0 or attack_timer > 0.0:
		var atk_idx: int = clamp(int(anim_attack_timer), 0, ATTACK_FRAMES.size() - 1)
		art_sprite.texture = ATTACK_FRAMES[atk_idx]
		base_scale = 0.17
		sprite_offset = Vector2(8 * facing, -4)
	elif not is_on_floor():
		art_sprite.texture = TEX_JUMP
		base_scale = 0.095
		sprite_offset = Vector2(0, -2)
	else:
		if absf(velocity.x) > 20.0:
			var run_idx: int = int(anim_run_timer) % RUN_FRAMES.size()
			art_sprite.texture = RUN_FRAMES[run_idx]
			base_scale = 0.18
			sprite_offset = Vector2(0, -4)
		else:
			art_sprite.texture = RUN_FRAMES[0]
			base_scale = 0.18
			sprite_offset = Vector2(0, -4)

	art_sprite.position = sprite_offset

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

	art_sprite.scale = Vector2(base_scale * facing * (1.0 + impact_strength * 0.08 + squash_mix * 0.06 - stretch_mix * 0.06), base_scale * (1.0 - impact_strength * 0.04 + locomotion_bob * 0.35 - squash_mix * 0.09 + stretch_mix * 0.07))
	camera.position.x = lerpf(camera.position.x, 90.0 * facing, 0.08)
	camera.position.y = lerpf(camera.position.y, clampf(velocity.y * 0.06, -28.0, 40.0), 0.06)
	var shake_target := Vector2.ZERO
	if camera_shake_timer > 0.0:
		shake_target = Vector2(randf_range(-camera_shake_strength, camera_shake_strength), randf_range(-camera_shake_strength, camera_shake_strength))
	camera.offset = camera.offset.lerp(shake_target + camera_kick_vector, 0.32)


func _spawn_attack_arc() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var arc := Polygon2D.new()
	var points := PackedVector2Array()
	var segments := 9
	for step in segments + 1:
		var angle := lerpf(-1.15, 1.15, float(step) / float(segments))
		points.append(Vector2(cos(angle) * 52.0 * facing, sin(angle) * 52.0))
	for step in segments + 1:
		var angle := lerpf(1.15, -1.15, float(step) / float(segments))
		points.append(Vector2(cos(angle) * 34.0 * facing, sin(angle) * 34.0))
	arc.polygon = points
	arc.global_position = global_position + Vector2(facing * 26.0, -8.0)
	arc.color = Color(1.0, 0.72, 0.5, 0.7)
	arc.z_index = 18
	scene.add_child(arc)
	var tween := arc.create_tween()
	tween.set_parallel(true)
	tween.tween_property(arc, "scale", Vector2(1.35, 1.15), 0.12).from(Vector2(0.6, 0.85))
	tween.tween_property(arc, "modulate:a", 0.0, 0.12)
	tween.set_parallel(false)
	tween.tween_callback(arc.queue_free)


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
	if not is_on_floor():
		air_fall_speed = maxf(air_fall_speed, velocity.y)
	if is_on_floor() and not was_on_floor:
		var impact_speed := maxf(air_fall_speed, absf(velocity.y))
		land_squash_strength = clampf(impact_speed / 900.0, 0.35, 1.0)
		land_squash_duration = clampf(0.12 + impact_speed / 900.0 * 0.08, 0.12, 0.2)
		land_squash_timer = land_squash_duration
		air_fall_speed = 0.0
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
