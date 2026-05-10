extends Area2D

var hazard_id: String = ""
var setup: Dictionary = {}
var cycle_time: float = 2.0
var active_time: float = 0.8
var start_offset: float = 0.0
var push_direction: float = 1.0
var stage_enabled: bool = false
var active_now: bool = false
var pulse_time: float = 0.0
var contact_cooldown: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var beam: Polygon2D = $Beam
@onready var halo: Polygon2D = $Halo


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	monitoring = true
	monitorable = false


func configure(hazard_setup: Dictionary) -> void:
	setup = hazard_setup.duplicate(true)
	hazard_id = String(setup.get("id", ""))
	cycle_time = maxf(0.2, float(setup.get("cycle_time", 2.0)))
	active_time = clampf(float(setup.get("active_time", 0.8)), 0.1, cycle_time)
	start_offset = float(setup.get("start_offset", 0.0))
	push_direction = float(setup.get("push_direction", 1.0))
	var size := Vector2(setup.get("size", Vector2(120.0, 18.0)))
	var shape := RectangleShape2D.new()
	shape.size = size
	collision_shape.shape = shape
	var half := size * 0.5
	var beam_polygon := PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	beam.polygon = beam_polygon
	halo.polygon = PackedVector2Array([
		Vector2(-half.x * 1.16, -half.y * 1.8),
		Vector2(half.x * 1.16, -half.y * 1.8),
		Vector2(half.x * 1.16, half.y * 1.8),
		Vector2(-half.x * 1.16, half.y * 1.8),
	])
	var rotation_degrees_value := float(setup.get("rotation_degrees", 0.0))
	rotation_degrees = rotation_degrees_value
	_apply_visuals(false)


func set_stage_enabled(value: bool) -> bool:
	var changed := stage_enabled != value
	stage_enabled = value
	return changed


func _process(delta: float) -> void:
	pulse_time += delta
	if contact_cooldown > 0.0:
		contact_cooldown -= delta
	var next_active := _compute_active_state()
	if next_active != active_now:
		active_now = next_active
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


func _apply_visuals(is_active: bool) -> void:
	var primary: Color = setup.get("primary_color", Color(1.0, 0.52, 0.28))
	var secondary: Color = setup.get("secondary_color", Color(0.33, 0.9, 1.0))
	if is_active:
		beam.color = primary
		beam.modulate.a = 0.95
		halo.color = Color(primary.r, primary.g, primary.b, 0.22)
		halo.scale = Vector2.ONE * 1.02
	else:
		beam.color = secondary
		beam.modulate.a = 0.36 if stage_enabled else 0.14
		halo.color = Color(secondary.r, secondary.g, secondary.b, 0.12 if stage_enabled else 0.04)
		halo.scale = Vector2.ONE


func _animate_visuals() -> void:
	var intensity := 0.0
	if active_now:
		intensity = 0.82 + sin(pulse_time * 11.0) * 0.12
		beam.scale = Vector2.ONE * (1.0 + sin(pulse_time * 9.0) * 0.03)
		halo.scale = Vector2.ONE * (1.02 + sin(pulse_time * 5.0) * 0.08)
	else:
		intensity = (0.3 if stage_enabled else 0.15) + sin(pulse_time * 4.0) * 0.04
		beam.scale = Vector2.ONE
		halo.scale = Vector2.ONE * (1.0 + sin(pulse_time * 2.5) * 0.03)
	beam.modulate.a = clampf(intensity, 0.08, 1.0)
	halo.modulate.a = clampf(intensity * 0.6, 0.03, 0.58)


func _damage_overlapping_players() -> void:
	if contact_cooldown > 0.0:
		return
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_contact_hit"):
			body.take_contact_hit(push_direction)
			contact_cooldown = 0.45
			break


func _on_body_entered(body: Node) -> void:
	if not active_now or contact_cooldown > 0.0:
		return
	if body.is_in_group("player") and body.has_method("take_contact_hit"):
		body.take_contact_hit(push_direction)
		contact_cooldown = 0.45
