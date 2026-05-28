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
	_spawn_collect_burst()
	collected.emit()
	queue_free()


func _spawn_collect_burst() -> void:
	var burst := Polygon2D.new()
	burst.polygon = PackedVector2Array()
	for step in 18:
		var angle := TAU * float(step) / 18.0
		var radius := 42.0 if step % 2 == 0 else 18.0
		burst.polygon.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	burst.global_position = global_position
	burst.color = Color(0.48, 0.95, 1.0, 0.76)
	burst.z_index = 16
	get_tree().current_scene.add_child(burst)
	var ring := Polygon2D.new()
	ring.polygon = PackedVector2Array()
	for step in 24:
		var angle := TAU * float(step) / 24.0
		ring.polygon.append(Vector2(cos(angle) * 28.0, sin(angle) * 28.0))
	ring.global_position = global_position
	ring.color = Color(1.0, 0.86, 0.38, 0.42)
	ring.z_index = 15
	get_tree().current_scene.add_child(ring)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(burst, "scale", Vector2.ONE * 1.9, 0.2).from(Vector2.ONE * 0.25)
	tween.tween_property(burst, "modulate:a", 0.0, 0.22)
	tween.tween_property(ring, "scale", Vector2.ONE * 2.4, 0.26).from(Vector2.ONE * 0.4)
	tween.tween_property(ring, "modulate:a", 0.0, 0.26)
	tween.set_parallel(false)
	tween.tween_callback(burst.queue_free)
	tween.tween_callback(ring.queue_free)
