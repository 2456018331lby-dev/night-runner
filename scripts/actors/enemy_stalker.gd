extends CharacterBody2D
## EnemyStalker: vertical ambush elite.
##
## Hangs above the player on a platform, shows a drop warning,
## then plunges down. On landing, creates a shockwave that
## pushes nearby players. After landing, walks briefly before
## re-clinging to the nearest platform above.
##
## Boundary: Stalker only manages its own behavior.
## Global state, scoring, and damage are handled by World/GameState.

signal defeated(points: int)

const WALK_SPEED := 72.0
const GRAVITY := 1500.0
const CONTACT_RANGE := 32.0
const PLUNGE_SPEED_Y := 680.0
const PLUNGE_AIM_RANGE_X := 260.0
const CLING_TIME := 1.8
const WARNING_TIME := 0.55
const RECOVERY_TIME := 0.48
const REPOSITION_TIME := 1.2
const LANDING_IMPACT_RANGE := 120.0
const POINTS_AWARD := 240
const PLATFORM_REACH_X := 380.0
const PLATFORM_MIN_VERTICAL_GAP := 56.0
const PLATFORM_EDGE_PADDING := 28.0
const CLING_SURFACE_MARGIN := 6.0
const AFTERIMAGE_INTERVAL := 0.05
const AFTERIMAGE_LIFETIME := 0.22
const LANDING_PREVIEW_RAY_LENGTH := 760.0
const LANDING_PREVIEW_FALLBACK_Y := 720.0

@onready var body_shape_node: CollisionShape2D = $CollisionShape2D
@onready var rig: Node2D = $Rig
@onready var body_visual: Polygon2D = $Rig/Body
@onready var mask_visual: Polygon2D = $Rig/Mask
@onready var eye_visual: Polygon2D = $Rig/Eye
@onready var art_sprite: Sprite2D = $Rig/Art
@onready var shadow_visual: Polygon2D = $Shadow
@onready var landing_zone: Area2D = $LandingZone
@onready var landing_shape: CollisionShape2D = $LandingZone/CollisionShape2D
@onready var landing_ring: Polygon2D = $LandingZone/LandingRing
@onready var warning_marker: Polygon2D = $WarningMarker
@onready var landing_preview_line: Line2D = Line2D.new()
@onready var landing_preview_ring: Polygon2D = Polygon2D.new()

var player: Node2D
var knocked_velocity: Vector2 = Vector2.ZERO
var defeated_once: bool = false
var hit_flash_timer: float = 0.0
var state: String = "cling"
var cling_timer: float = 1.0
var warning_timer: float = 0.0
var recovery_timer: float = 0.0
var reposition_timer: float = 0.0
var facing: float = -1.0
var cling_origin: Vector2 = Vector2.ZERO
var landing_flash_timer: float = 0.0
var shadow_phase: float = randf() * TAU
var max_hp: int = 4
var current_hp: int = 4
var hp_bar_bg: Polygon2D
var hp_bar_fill: Polygon2D
var base_art_scale: Vector2 = Vector2.ONE
var predicted_landing_position: Vector2 = Vector2.ZERO
var afterimage_timer: float = 0.0
var afterimages: Array[Sprite2D] = []


func _ready() -> void:
	add_to_group("enemy")
	current_hp = max_hp
	_setup_hp_bar()
	landing_zone.monitoring = true
	landing_zone.monitorable = false
	landing_zone.body_entered.connect(_on_landing_zone_body_entered)
	landing_shape.disabled = true
	landing_ring.visible = false
	_setup_warning_marker()
	_setup_landing_preview()
	cling_origin = global_position
	base_art_scale = art_sprite.scale


func _setup_warning_marker() -> void:
	warning_marker.polygon = PackedVector2Array([
		Vector2(0, -18),
		Vector2(14, -6),
		Vector2(10, 10),
		Vector2(-10, 10),
		Vector2(-14, -6),
	])
	warning_marker.color = Color(1.0, 0.28, 0.22, 0.0)
	warning_marker.z_index = 12
	warning_marker.visible = false


func _setup_landing_preview() -> void:
	landing_preview_line.top_level = true
	landing_preview_line.width = 3.0
	landing_preview_line.default_color = Color(1.0, 0.28, 0.18, 0.74)
	landing_preview_line.z_index = -1
	landing_preview_line.visible = false
	add_child(landing_preview_line)

	landing_preview_ring.top_level = true
	landing_preview_ring.polygon = PackedVector2Array()
	for step in 24:
		var angle := TAU * float(step) / 24.0
		var radius := LANDING_IMPACT_RANGE if step % 2 == 0 else LANDING_IMPACT_RANGE * 0.82
		landing_preview_ring.polygon.append(Vector2(cos(angle) * radius, sin(angle) * radius * 0.26))
	landing_preview_ring.color = Color(1.0, 0.18, 0.12, 0.28)
	landing_preview_ring.z_index = -2
	landing_preview_ring.visible = false
	add_child(landing_preview_ring)




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
	text_label.text = "+240"
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
	_update_state(delta)
	move_and_slide()
	_try_contact_damage()
	_update_afterimages(delta)
	_refresh_visuals()
	if global_position.y > 920.0:
		_defeat(true, true)


func receive_hit(force: Vector2) -> void:
	current_hp -= 1
	knocked_velocity = force * 0.9
	hit_flash_timer = 0.2
	_refresh_hp_bar()
	_spawn_hit_number()
	if current_hp <= 0:
		_defeat(true, false)
	if state == "cling":
		state = "reposition"
		reposition_timer = REPOSITION_TIME * 0.6
	elif state == "warning":
		state = "reposition"
		reposition_timer = REPOSITION_TIME
		warning_timer = 0.0


func _update_timers(delta: float) -> void:
	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
	if landing_flash_timer > 0.0:
		landing_flash_timer -= delta
	shadow_phase += delta * 3.5


func _update_state(delta: float) -> void:
	match state:
		"cling":
			_update_cling(delta)
		"warning":
			_update_warning(delta)
		"plunge":
			_update_plunge(delta)
		"recovery":
			_update_recovery(delta)
		"reposition":
			_update_reposition(delta)


func _update_cling(delta: float) -> void:
	velocity = Vector2.ZERO
	cling_timer -= delta
	if cling_timer <= 0.0:
		if _can_plunge():
			_begin_warning()
		else:
			cling_timer = 0.4


func _update_warning(delta: float) -> void:
	velocity = Vector2.ZERO
	warning_timer -= delta
	if warning_timer <= 0.0:
		_launch_plunge()


func _update_plunge(_delta: float) -> void:
	if is_on_floor():
		_on_landing()


func _update_recovery(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * delta * 8.0)
	recovery_timer -= delta
	if recovery_timer <= 0.0:
		_try_find_platform_above()


func _update_reposition(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * delta * 6.0)
	reposition_timer -= delta
	if reposition_timer <= 0.0:
		if is_on_floor():
			_try_find_platform_above()
		else:
			state = "cling"
			cling_timer = CLING_TIME * 0.7
			cling_origin = global_position


func _can_plunge() -> bool:
	if not is_instance_valid(player) or GameState.is_run_failed:
		return false
	var delta_x := absf(player.global_position.x - global_position.x)
	return delta_x <= PLUNGE_AIM_RANGE_X


func _begin_warning() -> void:
	state = "warning"
	warning_timer = WARNING_TIME
	AudioEngine.play_stalker_warn()
	if is_instance_valid(player):
		facing = signf(player.global_position.x - global_position.x)
		if facing == 0.0:
			facing = -1.0
	predicted_landing_position = _compute_landing_preview_position()
	_update_landing_preview_geometry()


func _launch_plunge() -> void:
	state = "plunge"
	velocity.x = facing * 60.0
	velocity.y = PLUNGE_SPEED_Y
	afterimage_timer = 0.0


func _on_landing() -> void:
	state = "recovery"
	recovery_timer = RECOVERY_TIME
	velocity = Vector2.ZERO
	landing_flash_timer = 0.25
	landing_preview_line.visible = false
	landing_preview_ring.visible = false
	AudioEngine.play_stalker_impact()
	_activate_landing_impact()
	_spawn_landing_burst()


func _activate_landing_impact() -> void:
	landing_shape.disabled = false
	landing_ring.visible = true
	landing_ring.scale = Vector2.ONE * 0.3
	landing_ring.modulate.a = 0.7
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(landing_ring, "scale", Vector2.ONE * 1.8, 0.22)
	tween.tween_property(landing_ring, "modulate:a", 0.0, 0.24)
	tween.set_parallel(false)
	tween.tween_callback(func() -> void:
		landing_shape.disabled = true
		landing_ring.visible = false
	)
	_damage_players_in_landing_zone()


func _spawn_landing_burst() -> void:
	for index in 8:
		var shard := Polygon2D.new()
		shard.polygon = PackedVector2Array([
			Vector2(0.0, -4.0),
			Vector2(14.0, 0.0),
			Vector2(0.0, 4.0),
		])
		var angle := TAU * float(index) / 8.0
		shard.global_position = global_position
		shard.rotation = angle
		shard.color = Color(1.0, 0.38, 0.22, 0.85)
		shard.z_index = 17
		get_parent().add_child(shard)
		var shard_tween := shard.create_tween()
		shard_tween.set_parallel(true)
		shard_tween.tween_property(shard, "global_position", global_position + Vector2(cos(angle), sin(angle)) * 48.0, 0.16)
		shard_tween.tween_property(shard, "modulate:a", 0.0, 0.16)
		shard_tween.tween_property(shard, "scale", Vector2.ONE * 0.3, 0.16)
		shard_tween.set_parallel(false)
		shard_tween.tween_callback(shard.queue_free)
	var ring := Polygon2D.new()
	ring.polygon = PackedVector2Array()
	for step in 20:
		var angle := TAU * float(step) / 20.0
		var radius := 26.0 if step % 2 == 0 else 10.0
		ring.polygon.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	ring.global_position = global_position
	ring.color = Color(1.0, 0.68, 0.42, 0.65)
	ring.z_index = 16
	get_parent().add_child(ring)
	var ring_tween := ring.create_tween()
	ring_tween.set_parallel(true)
	ring_tween.tween_property(ring, "scale", Vector2.ONE * 2.2, 0.18).from(Vector2.ONE * 0.35)
	ring_tween.tween_property(ring, "modulate:a", 0.0, 0.2)
	ring_tween.set_parallel(false)
	ring_tween.tween_callback(ring.queue_free)


func _damage_players_in_landing_zone() -> void:
	for body in landing_zone.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_contact_hit"):
			body.take_contact_hit(facing, "enemy", "stalker_landing")


func _compute_landing_preview_position() -> Vector2:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		global_position + Vector2(0.0, _get_body_half_height()),
		global_position + Vector2(0.0, LANDING_PREVIEW_RAY_LENGTH),
		4
	)
	query.exclude = [get_rid()]
	var hit := space_state.intersect_ray(query)
	if hit.has("position"):
		var hit_position: Vector2 = hit["position"]
		return hit_position
	return Vector2(global_position.x, LANDING_PREVIEW_FALLBACK_Y)


func _update_landing_preview_geometry() -> void:
	var launch_position := global_position + Vector2(0.0, _get_body_half_height() + 4.0)
	landing_preview_line.global_position = Vector2.ZERO
	landing_preview_line.points = PackedVector2Array([
		launch_position,
		predicted_landing_position,
	])
	landing_preview_ring.global_position = predicted_landing_position
	landing_preview_ring.rotation = 0.0


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
		image.modulate.a = clampf(next_life / AFTERIMAGE_LIFETIME, 0.0, 1.0) * 0.34
	if state != "plunge":
		afterimage_timer = 0.0
		return
	afterimage_timer -= delta
	if afterimage_timer <= 0.0:
		afterimage_timer = AFTERIMAGE_INTERVAL
		_spawn_afterimage()


func _spawn_afterimage() -> void:
	var image := Sprite2D.new()
	image.texture = art_sprite.texture
	image.global_position = art_sprite.global_position
	image.global_rotation = art_sprite.global_rotation
	image.global_scale = art_sprite.global_scale
	image.modulate = Color(1.0, 0.42, 0.28, 0.34)
	image.z_index = -3
	image.set_meta("life", AFTERIMAGE_LIFETIME)
	get_parent().add_child(image)
	afterimages.append(image)


func _try_find_platform_above() -> void:
	if not is_instance_valid(player) or GameState.is_run_failed:
		state = "cling"
		cling_timer = CLING_TIME
		return
	var desired_x := player.global_position.x + facing * -48.0
	var best_position := Vector2(desired_x, global_position.y - 80.0)
	var best_score := INF
	var found := false
	var platforms := get_tree().get_nodes_in_group("platform")
	for platform in platforms:
		var platform_rect := _get_platform_rect(platform)
		if platform_rect.size == Vector2.ZERO:
			continue
		var top_y := platform_rect.position.y
		if top_y >= global_position.y - PLATFORM_MIN_VERTICAL_GAP:
			continue
		var min_x := platform_rect.position.x + PLATFORM_EDGE_PADDING
		var max_x := platform_rect.end.x - PLATFORM_EDGE_PADDING
		if min_x > max_x:
			min_x = platform_rect.position.x
			max_x = platform_rect.end.x
		var cling_x := clampf(desired_x, min_x, max_x)
		var horizontal_cost := absf(cling_x - desired_x)
		if horizontal_cost > PLATFORM_REACH_X:
			continue
		var vertical_gap := global_position.y - top_y
		var player_center_x := clampf(player.global_position.x, platform_rect.position.x, platform_rect.end.x)
		var player_alignment_cost := absf(player_center_x - cling_x)
		var score := horizontal_cost * 1.35 + vertical_gap * 0.42 + player_alignment_cost * 0.18
		if score < best_score:
			best_score = score
			best_position = Vector2(cling_x, top_y - _get_body_half_height() - CLING_SURFACE_MARGIN)
			found = true
	if not found:
		best_position = Vector2(desired_x, minf(global_position.y - 80.0, player.global_position.y - 120.0))
	global_position = best_position
	velocity = Vector2.ZERO
	cling_origin = global_position
	state = "cling"
	cling_timer = CLING_TIME


func _get_platform_rect(platform: Node) -> Rect2:
	if not platform is Node2D:
		return Rect2()
	for child in platform.get_children():
		if not child is CollisionShape2D:
			continue
		var collision_child: CollisionShape2D = child as CollisionShape2D
		if not collision_child.shape is RectangleShape2D:
			continue
		var rect_shape: RectangleShape2D = collision_child.shape as RectangleShape2D
		var platform_node: Node2D = platform as Node2D
		var shape_position := platform_node.to_global(collision_child.position)
		var half := rect_shape.size * 0.5
		return Rect2(shape_position - half, rect_shape.size)
	return Rect2()


func _get_body_half_height() -> float:
	if body_shape_node.shape is RectangleShape2D:
		var rect_shape: RectangleShape2D = body_shape_node.shape as RectangleShape2D
		return rect_shape.size.y * 0.5
	return 26.0


func _try_contact_damage() -> void:
	if state == "plunge":
		return
	if not is_instance_valid(player) or GameState.is_run_failed:
		return
	if global_position.distance_to(player.global_position) <= CONTACT_RANGE:
		var push_direction := signf(player.global_position.x - global_position.x)
		if push_direction == 0.0:
			push_direction = facing if facing != 0.0 else 1.0
		var detail := "stalker_landing" if landing_flash_timer > 0.0 else "stalker_body"
		player.take_contact_hit(push_direction, "enemy", detail)


func _refresh_visuals() -> void:
	if facing != 0.0:
		rig.scale.x = facing
	var windup_mix := clampf(1.0 - warning_timer / WARNING_TIME, 0.0, 1.0) if state == "warning" else 0.0
	var plunge_mix := 1.0 if state == "plunge" else 0.0
	var recovery_mix := clampf(1.0 - recovery_timer / RECOVERY_TIME, 0.0, 1.0) if state == "recovery" else 0.0
	var cling_pulse := sin(shadow_phase * 2.2) * 0.5 + 0.5 if state == "cling" else 0.0
	if hit_flash_timer > 0.0:
		body_visual.color = Color(1.0, 0.88, 0.72)
		mask_visual.color = Color(1.0, 0.92, 0.78)
		eye_visual.color = Color(1.0, 0.82, 0.6)
		art_sprite.modulate = Color(1.0, 0.96, 0.86, 1.0)
	elif landing_flash_timer > 0.0:
		body_visual.color = Color(1.0, 0.52, 0.32)
		mask_visual.color = Color(1.0, 0.72, 0.48)
		eye_visual.color = Color(1.0, 0.9, 0.6)
		art_sprite.modulate = Color(1.0, 0.84, 0.62, 1.0)
	elif state == "warning":
		body_visual.color = Color(0.86 + windup_mix * 0.14, 0.22 + windup_mix * 0.12, 0.18)
		mask_visual.color = Color(0.92, 0.38 + windup_mix * 0.2, 0.24)
		eye_visual.color = Color(1.0, 0.8 + windup_mix * 0.12, 0.42)
		art_sprite.modulate = Color(1.0, 0.78 + windup_mix * 0.16, 0.7 - windup_mix * 0.08, 1.0)
	elif plunge_mix > 0.0:
		body_visual.color = Color(1.0, 0.32, 0.22)
		mask_visual.color = Color(1.0, 0.58, 0.36)
		eye_visual.color = Color(1.0, 0.9, 0.5)
		art_sprite.modulate = Color(1.0, 0.72, 0.56, 1.0)
	else:
		body_visual.color = Color(0.82 + cling_pulse * 0.08, 0.2 + cling_pulse * 0.04, 0.18)
		mask_visual.color = Color(0.88 + cling_pulse * 0.04, 0.36, 0.22)
		eye_visual.color = Color(0.96, 0.78 + cling_pulse * 0.1, 0.48)
		art_sprite.modulate = Color(1.0, 0.92 + cling_pulse * 0.05, 0.9 - cling_pulse * 0.04, 1.0)
	var body_squash := 1.0 + plunge_mix * 0.18 - plunge_mix * 0.12
	body_visual.scale.y = body_squash
	body_visual.scale.x = absf(body_visual.scale.x) * (1.0 + cling_pulse * 0.03)
	art_sprite.scale = base_art_scale * (1.0 + windup_mix * 0.06 + plunge_mix * 0.04 + cling_pulse * 0.02)
	shadow_visual.visible = state == "cling" or state == "warning"
	if shadow_visual.visible:
		var shadow_alpha := 0.22 + sin(shadow_phase) * 0.06 + windup_mix * 0.14
		shadow_visual.modulate.a = shadow_alpha
		shadow_visual.scale = Vector2.ONE * (0.8 + windup_mix * 0.3 + cling_pulse * 0.12)
	warning_marker.visible = state == "warning"
	if warning_marker.visible:
		warning_marker.color = Color(1.0, 0.28, 0.22, 0.35 + windup_mix * 0.45)
		warning_marker.scale = Vector2.ONE * (0.7 + windup_mix * 0.6)
		warning_marker.position.y = -60.0 - windup_mix * 20.0
	landing_preview_line.visible = state == "warning" or state == "plunge"
	landing_preview_ring.visible = state == "warning" or state == "plunge"
	if landing_preview_ring.visible:
		var danger_mix := windup_mix if state == "warning" else 1.0
		landing_preview_line.modulate.a = 0.18 + danger_mix * 0.58
		landing_preview_ring.modulate.a = 0.18 + danger_mix * 0.5
		landing_preview_ring.scale = Vector2.ONE * (0.82 + danger_mix * 0.24 + sin(shadow_phase * 5.0) * 0.05)


func _on_landing_zone_body_entered(body: Node) -> void:
	if landing_shape.disabled:
		return
	if body.is_in_group("player") and body.has_method("take_contact_hit"):
		body.take_contact_hit(facing, "enemy", "stalker_landing")


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
