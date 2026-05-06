extends Area2D

@export var boost_velocity: Vector2 = Vector2(420.0, -520.0)

@onready var art_sprite: Sprite2D = $Art
@onready var glow: Polygon2D = $Glow

var pulse_time: float = randf() * TAU


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	pulse_time += delta * 2.0
	glow.modulate.a = 0.34 + sin(pulse_time) * 0.08
	art_sprite.modulate.a = 0.86 + sin(pulse_time * 1.3) * 0.12


func _on_body_entered(body: Node) -> void:
	if not body.has_method("apply_launch_boost"):
		return
	body.call("apply_launch_boost", boost_velocity)
