extends Area2D

var hazard_id: String = ""
var hazard_type: String = "pulse_beam"
var setup: Dictionary = {}
var cycle_time: float = 2.0
var active_time: float = 0.8
var start_offset: float = 0.0
var push_direction: float = 1.0
var stage_enabled: bool = false
var active_now: bool = false
var pulse_time: float = 0.0
var contact_cooldown: float = 0.0
var warning_time: float = 0.28
var visual_extent: Vector2 = Vector2(120.0, 18.0)
var warning_mix: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var halo: Polygon2D = $Halo
@onready var beam: Polygon2D = $Beam


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	monitoring = true
	monitorable = false


func configure(hazard_setup: Dictionary) -> void:
	setup = hazard_setup.duplicate(true)
	hazard_id = String(setup.get("id", ""))
	hazard_type = String(setup.get("type", "pulse_beam"))
	cycle_time = maxf(0.2, float(setup.get("cycle_time", 2.0)))
	active_time = clampf(float(setup.get("active_time", 0.8)), 0.08, cycle_time)
	start_offset = float(setup.get("start_offset", 0.0))
	push_direction = float(setup.get("push_direction", 1.0))
	warning_time = clampf(float(setup.get("warning_time", active_time * 0.5)), 0.05, cycle_time)
	visual_extent = Vector2(setup.get("size", Vector2(120.0, 18.0)))
	rotation_degrees = float(setup.get("rotation_degrees", 0.0))
	_apply_geometry()
	_apply_visuals(false)


func set_stage_enabled(value: bool) -> bool:
	var changed := stage_enabled != value
	stage_enabled = value
	if not stage_enabled:
		active_now = false
		_apply_visuals(false)
	return changed


func get_status_summary() -> String:
	var type_label := String(setup.get("label", hazard_id.replace("_", " "))).capitalize()
	if not stage_enabled:
		return "%s offline" % type_label
	if active_now:
		return "%s firing" % type_label
	if warning_mix > 0.02:
		return "%s priming" % type_label
	return "%s cycling" % type_label


func _process(delta: float) -> void:
	pulse_time += delta
	if contact_cooldown > 0.0:
		contact_cooldown -= delta
	var next_active := _compute_active_state()
	warning_mix = _compute_warning_mix()
	if next_active != active_now:
		active_now = next_active
		_apply_geometry()
		_apply_visuals(active_now)
		if active_now:
			_damage_overlapping_players()
	else:
		_animate_visuals()


func _compute_active_state() -> bool:
	if not stage_enabled:
		return false
	if bool(setup.get("always_on", false)):
		return true
	var cycle_position := fposmod(pulse_time + start_offset, cycle_time)
	return cycle_position <= active_time


func _compute_warning_mix() -> float:
	if not stage_enabled or bool(setup.get("always_on", false)):
		return 0.0
	var cycle_position := fposmod(pulse_time + start_offset, cycle_time)
	if cycle_position <= active_time:
		return 0.0
	var time_until_fire := cycle_time - cycle_position
	if time_until_fire > warning_time:
		return 0.0
	return clampf(1.0 - time_until_fire / maxf(0.01, warning_time), 0.0, 1.0)


func _apply_geometry() -> void:
	match hazard_type:
		"sweep_wall":
			_apply_sweep_wall_geometry()
		"collapse_zone":
			_apply_collapse_zone_geometry()
		_:
			_apply_pulse_beam_geometry()


func _apply_pulse_beam_geometry() -> void:
	var size := visual_extent
	_set_rectangle_shape(size)
	var half := size * 0.5
	beam.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	halo.polygon = PackedVector2Array([
		Vector2(-half.x * 1.16, -half.y * 1.8),
		Vector2(half.x * 1.16, -half.y * 1.8),
		Vector2(half.x * 1.16, half.y * 1.8),
		Vector2(-half.x * 1.16, half.y * 1.8),
	])
	if not active_now:
		beam.position = Vector2.ZERO
		halo.position = Vector2.ZERO
		return
	var sweep_distance := float(setup.get("sweep_distance", 0.0))
	var pulse_offset := sin(pulse_time * 7.5) * sweep_distance * 0.18
	beam.position = Vector2(0.0, pulse_offset)
	halo.position = beam.position


func _apply_sweep_wall_geometry() -> void:
	var size := visual_extent
	_set_rectangle_shape(size)
	var half := size * 0.5
	beam.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x * 0.76, -half.y * 0.88),
		Vector2(half.x, half.y),
		Vector2(-half.x * 0.72, half.y * 0.8),
	])
	halo.polygon = PackedVector2Array([
		Vector2(-half.x * 1.18, -half.y * 1.46),
		Vector2(half.x * 1.02, -half.y * 1.12),
		Vector2(half.x * 1.18, half.y * 1.46),
		Vector2(-half.x * 0.92, half.y * 1.18),
	])
	var sweep_distance := float(setup.get("sweep_distance", size.x * 0.32))
	var sweep_phase := clampf(_get_active_ratio(), 0.0, 1.0)
	var lateral_offset := lerpf(-sweep_distance * 0.5, sweep_distance * 0.5, sweep_phase) if active_now else lerpf(-sweep_distance * 0.5, sweep_distance * 0.2, warning_mix)
	beam.position = Vector2(lateral_offset, 0.0)
	halo.position = beam.position


func _apply_collapse_zone_geometry() -> void:
	var size := visual_extent
	var active_scale := 1.0 + _get_active_ratio() * 0.24 if active_now else 1.0 + warning_mix * 0.14
	var ellipse_radius := size * 0.5 * active_scale
	var points := PackedVector2Array()
	for step in 12:
		var angle := TAU * float(step) / 12.0
		var radius_variation := 0.86 + sin(float(step) * 1.7 + pulse_time * 4.0) * 0.12
		points.append(Vector2(cos(angle) * ellipse_radius.x * radius_variation, sin(angle) * ellipse_radius.y * radius_variation))
	beam.polygon = points
	var halo_points := PackedVector2Array()
	for point in points:
		halo_points.append(point * 1.28)
	halo.polygon = halo_points
	beam.position = Vector2.ZERO
	halo.position = Vector2.ZERO
	_set_rectangle_shape(size * Vector2(0.92, 0.86))


func _set_rectangle_shape(size: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	collision_shape.shape = shape


func _apply_visuals(is_active: bool) -> void:
	var primary: Color = setup.get("primary_color", Color(1.0, 0.52, 0.28))
	var secondary: Color = setup.get("secondary_color", Color(0.33, 0.9, 1.0))
	var warning_color := primary.lerp(secondary, 0.24)
	if is_active:
		beam.color = primary
		beam.modulate.a = 0.96
		halo.color = Color(primary.r, primary.g, primary.b, 0.22)
		halo.scale = Vector2.ONE * 1.04
	elif warning_mix > 0.02:
		beam.color = warning_color
		beam.modulate.a = 0.26 + warning_mix * 0.38
		halo.color = Color(primary.r, primary.g, primary.b, 0.08 + warning_mix * 0.14)
		halo.scale = Vector2.ONE * (1.0 + warning_mix * 0.08)
	else:
		beam.color = secondary
		beam.modulate.a = 0.34 if stage_enabled else 0.12
		halo.color = Color(secondary.r, secondary.g, secondary.b, 0.1 if stage_enabled else 0.03)
		halo.scale = Vector2.ONE


func _animate_visuals() -> void:
	var intensity := 0.0
	match hazard_type:
		"collapse_zone":
			if active_now:
				intensity = 0.88 + sin(pulse_time * 13.0) * 0.08
				beam.scale = Vector2.ONE * (1.03 + sin(pulse_time * 9.0) * 0.04)
				halo.scale = Vector2.ONE * (1.08 + sin(pulse_time * 5.0) * 0.12)
			else:
				intensity = 0.24 + warning_mix * 0.3 + sin(pulse_time * 4.0) * 0.04
				beam.scale = Vector2.ONE * (1.0 + warning_mix * 0.1)
				halo.scale = Vector2.ONE * (1.0 + warning_mix * 0.12)
		"sweep_wall":
			if active_now:
				intensity = 0.84 + sin(pulse_time * 11.0) * 0.09
				beam.scale = Vector2(1.0 + sin(pulse_time * 6.0) * 0.03, 1.0 + sin(pulse_time * 8.0) * 0.04)
				halo.scale = Vector2.ONE * (1.06 + sin(pulse_time * 4.0) * 0.08)
			else:
				intensity = 0.22 + warning_mix * 0.34 + sin(pulse_time * 5.0) * 0.04
				beam.scale = Vector2.ONE * (1.0 + warning_mix * 0.04)
				halo.scale = Vector2.ONE * (1.0 + warning_mix * 0.07)
		_:
			if active_now:
				intensity = 0.82 + sin(pulse_time * 11.0) * 0.12
				beam.scale = Vector2.ONE * (1.0 + sin(pulse_time * 9.0) * 0.03)
				halo.scale = Vector2.ONE * (1.02 + sin(pulse_time * 5.0) * 0.08)
			else:
				intensity = (0.3 if stage_enabled else 0.15) + warning_mix * 0.24 + sin(pulse_time * 4.0) * 0.04
				beam.scale = Vector2.ONE
				halo.scale = Vector2.ONE * (1.0 + sin(pulse_time * 2.5) * 0.03)
	beam.modulate.a = clampf(intensity, 0.08, 1.0)
	halo.modulate.a = clampf(intensity * 0.6, 0.03, 0.62)


func _damage_overlapping_players() -> void:
	if contact_cooldown > 0.0:
		return
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_contact_hit"):
			body.take_contact_hit(push_direction, "hazard", hazard_id)
			contact_cooldown = 0.45
			break


func _get_active_ratio() -> float:
	if not active_now:
		return 0.0
	var cycle_position := fposmod(pulse_time + start_offset, cycle_time)
	return clampf(cycle_position / maxf(0.01, active_time), 0.0, 1.0)


func _on_body_entered(body: Node) -> void:
	if not active_now or contact_cooldown > 0.0:
		return
	if body.is_in_group("player") and body.has_method("take_contact_hit"):
		body.take_contact_hit(push_direction, "hazard", hazard_id)
		contact_cooldown = 0.45
