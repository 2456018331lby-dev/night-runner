extends Area2D

@export var boost_velocity: Vector2 = Vector2(420.0, -520.0)

@onready var art_sprite: Sprite2D = $Art
@onready var glow: Polygon2D = $Glow
@onready var surge_ring: Polygon2D = $SurgeRing

var pulse_time: float = randf() * TAU
var trigger_flash: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	pulse_time += delta * 2.0
	if trigger_flash > 0.0:
		trigger_flash -= delta
	var flash_mix := clampf(trigger_flash / 0.24, 0.0, 1.0)
	glow.modulate.a = 0.34 + sin(pulse_time) * 0.08 + flash_mix * 0.18
	art_sprite.modulate.a = 0.86 + sin(pulse_time * 1.3) * 0.12 + flash_mix * 0.08
	surge_ring.scale = Vector2.ONE * (0.9 + sin(pulse_time * 1.8) * 0.04 + flash_mix * 0.26)
	surge_ring.modulate.a = clampf(0.12 + sin(pulse_time * 1.1) * 0.04 + flash_mix * 0.32, 0.08, 0.44)


func _on_body_entered(body: Node) -> void:
	if not body.has_method("apply_launch_boost"):
		return
	trigger_flash = 0.24
	body.call("apply_launch_boost", boost_velocity)
