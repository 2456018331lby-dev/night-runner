extends Node

@onready var world: Node = $World


func _ready() -> void:
	GameState.start_run()
	world.call_deferred("begin")

