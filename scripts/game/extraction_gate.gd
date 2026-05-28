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

var unlocked: bool = false
var pulse_time: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_apply_visual_state()


func _process(delta: float) -> void:
	pulse_time += delta
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
	unlocked = value
	_apply_visual_state()
	if unlocked:
		for body in get_overlapping_bodies():
			if body.is_in_group("player"):
				extraction_entered.emit()
				break


func _apply_visual_state() -> void:
	pillar.color = UNLOCKED_BASE if unlocked else LOCKED_BASE
	gate_frame.color = UNLOCKED_BORDER if unlocked else LOCKED_BORDER
	art_sprite.modulate = Color(1.0, 1.0, 1.0) if unlocked else Color(1.0, 0.86, 0.76)
	signal_ring.visible = unlocked


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if unlocked:
		extraction_entered.emit()
	else:
		extraction_blocked.emit()
