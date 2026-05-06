extends Area2D

signal extraction_entered
signal extraction_blocked

const LOCKED_BASE := Color(0.18, 0.24, 0.38, 0.68)
const LOCKED_BORDER := Color(1.0, 0.56, 0.28, 0.82)
const UNLOCKED_BASE := Color(0.08, 0.32, 0.24, 0.72)
const UNLOCKED_BORDER := Color(0.42, 1.0, 0.82, 0.92)

@onready var pillar: Polygon2D = $Pillar
@onready var gate_frame: Polygon2D = $GateFrame
@onready var glow: Polygon2D = $Glow
@onready var art_sprite: Sprite2D = $Art

var unlocked: bool = false
var pulse_time: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_apply_visual_state()


func _process(delta: float) -> void:
	pulse_time += delta
	var pulse := 0.78 + sin(pulse_time * 2.5) * 0.12
	glow.scale = Vector2.ONE * pulse
	glow.modulate.a = (0.16 if unlocked else 0.1) + sin(pulse_time * 1.9) * 0.03


func set_unlocked(value: bool) -> void:
	unlocked = value
	_apply_visual_state()


func _apply_visual_state() -> void:
	pillar.color = UNLOCKED_BASE if unlocked else LOCKED_BASE
	gate_frame.color = UNLOCKED_BORDER if unlocked else LOCKED_BORDER
	art_sprite.modulate = Color(1.0, 1.0, 1.0) if unlocked else Color(1.0, 0.86, 0.76)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if unlocked:
		extraction_entered.emit()
	else:
		extraction_blocked.emit()
