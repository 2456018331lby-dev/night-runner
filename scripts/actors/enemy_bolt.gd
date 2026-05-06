extends Area2D

const LIFETIME := 3.5

var velocity: Vector2 = Vector2.ZERO
var lifetime_remaining: float = LIFETIME


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func launch(initial_velocity: Vector2) -> void:
	velocity = initial_velocity
	rotation = velocity.angle()


func _physics_process(delta: float) -> void:
	position += velocity * delta
	lifetime_remaining -= delta
	if lifetime_remaining <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_contact_hit"):
		var push_direction := signf(velocity.x)
		if push_direction == 0.0:
			push_direction = 1.0
		body.take_contact_hit(push_direction)
	queue_free()
