extends Area2D

signal collected

@onready var art_sprite: Sprite2D = $Art
@onready var glow: Polygon2D = $Glow

var phase: float = randf() * TAU
var base_position: Vector2
var collected_once: bool = false


func _ready() -> void:
	base_position = position
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	phase += delta * 1.8
	position = base_position + Vector2(0.0, sin(phase) * 5.0)
	rotation = sin(phase * 0.75) * 0.06
	art_sprite.modulate.a = 0.88 + sin(phase * 1.2) * 0.12
	glow.modulate.a = 0.38 + sin(phase * 1.4) * 0.12


func _on_body_entered(body: Node) -> void:
	if collected_once or not body.is_in_group("player"):
		return
	collected_once = true
	collected.emit()
	queue_free()
