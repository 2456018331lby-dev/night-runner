extends Area2D

signal extraction_entered
signal extraction_blocked

const LOCKED_BASE := Color(0.18, 0.24, 0.38, 0.68)
const LOCKED_BORDER := Color(1.0, 0.56, 0.28, 0.82)
const UNLOCKED_BASE := Color(0.08, 0.32, 0.24, 0.72)
const UNLOCKED_BORDER := Color(0.42, 1.0, 0.82, 0.92)
const OVERDRIVE_BORDER := Color(1.0, 0.78, 0.36, 0.95)

@onready var pillar: Polygon2D = $Pillar
@onready var gate_frame: Polygon2D = $GateFrame
@onready var glow: Polygon2D = $Glow
@onready var art_sprite: Sprite2D = $Art
@onready var signal_ring: Polygon2D = $SignalRing
@onready var lock_chain: Polygon2D = $LockChain

var unlocked: bool = false
var pulse_time: float = 0.0
var chain_shatter_timer: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_apply_visual_state()


func _process(delta: float) -> void:
	pulse_time += delta
	if chain_shatter_timer > 0.0:
		chain_shatter_timer -= delta
		lock_chain.modulate.a = chain_shatter_timer / 0.3
		lock_chain.scale = Vector2.ONE * (1.0 + (0.3 - chain_shatter_timer) * 3.0)
	var pulse := 0.78 + sin(pulse_time * 2.5) * 0.12
	glow.scale = Vector2.ONE * pulse
	var greed_mix := clampf(GameState.get_extraction_bonus_progress_ratio(), 0.0, 1.0) if unlocked else 0.0
	glow.modulate.a = (0.16 if unlocked else 0.1) + sin(pulse_time * 1.9) * 0.03 + greed_mix * 0.12
	signal_ring.visible = unlocked
	if unlocked:
		signal_ring.scale = Vector2.ONE * (0.9 + greed_mix * 0.28 + sin(pulse_time * 1.8) * 0.06)
		signal_ring.modulate.a = clampf(0.14 + greed_mix * 0.24 + sin(pulse_time * 2.3) * 0.05, 0.08, 0.42)
		gate_frame.color = UNLOCKED_BORDER.lerp(OVERDRIVE_BORDER, greed_mix)


func set_unlocked(value: bool) -> void:
	var was_locked := not unlocked
	unlocked = value
	if unlocked and was_locked:
		chain_shatter_timer = 0.3
		_spawn_unlock_burst()
	_apply_visual_state()
	if unlocked:
		for body in get_overlapping_bodies():
			if body.is_in_group("player"):
				extraction_entered.emit()
				break


func _spawn_unlock_burst() -> void:
	var ring := Polygon2D.new()
	ring.polygon = PackedVector2Array()
	for step in 24:
		var angle := TAU * float(step) / 24.0
		ring.polygon.append(Vector2(cos(angle) * 38.0, sin(angle) * 38.0))
	ring.global_position = global_position
	ring.color = Color(0.42, 1.0, 0.82, 0.7)
	ring.z_index = 16
	get_tree().current_scene.add_child(ring)
	var beam := Polygon2D.new()
	beam.polygon = PackedVector2Array([
		Vector2(-16.0, -140.0),
		Vector2(16.0, -140.0),
		Vector2(24.0, 100.0),
		Vector2(-24.0, 100.0),
	])
	beam.global_position = global_position + Vector2(0.0, -28.0)
	beam.color = Color(0.45, 0.95, 1.0, 0.3)
	beam.z_index = 14
	get_tree().current_scene.add_child(beam)
	var tween := ring.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2.ONE * 2.8, 0.3).from(Vector2.ONE * 0.2)
	tween.tween_property(ring, "modulate:a", 0.0, 0.32)
	tween.tween_property(beam, "scale", Vector2(1.3, 1.0), 0.24).from(Vector2(0.4, 0.5))
	tween.tween_property(beam, "modulate:a", 0.0, 0.28)
	tween.set_parallel(false)
	tween.tween_callback(ring.queue_free)
	tween.tween_callback(beam.queue_free)


func _apply_visual_state() -> void:
	pillar.color = UNLOCKED_BASE if unlocked else LOCKED_BASE
	gate_frame.color = UNLOCKED_BORDER if unlocked else LOCKED_BORDER
	art_sprite.modulate = Color(1.0, 1.0, 1.0) if unlocked else Color(1.0, 0.86, 0.76)
	signal_ring.visible = unlocked
	lock_chain.visible = not unlocked and chain_shatter_timer <= 0.0


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if unlocked:
		extraction_entered.emit()
	else:
		extraction_blocked.emit()
