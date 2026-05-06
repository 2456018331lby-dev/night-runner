extends Node2D

const RUNNER_SCENE := preload("res://scenes/actors/enemy_runner.tscn")
const SUPPRESSOR_SCENE := preload("res://scenes/actors/enemy_suppressor.tscn")

@onready var player: Node = $Player
@onready var enemy_container: Node2D = $Enemies
@onready var hud: CanvasLayer = $HUD
@onready var touch_controls: CanvasLayer = $TouchControls

var encounter_layout: Array[Dictionary] = [
	{
		"scene": RUNNER_SCENE,
		"position": Vector2(540, 300),
	},
	{
		"scene": SUPPRESSOR_SCENE,
		"position": Vector2(900, 220),
	},
	{
		"scene": RUNNER_SCENE,
		"position": Vector2(1290, 120),
	},
	{
		"scene": SUPPRESSOR_SCENE,
		"position": Vector2(1700, 20),
	},
]


func _ready() -> void:
	GameState.run_failed.connect(_on_run_failed)
	player.player_fell.connect(_on_player_fell)
	player.player_hit.connect(_on_player_hit)
	if touch_controls.has_method("configure"):
		touch_controls.call("configure", PlatformProfile.should_show_touch_controls())


func begin() -> void:
	for setup in encounter_layout:
		var scene: PackedScene = setup["scene"]
		var position: Vector2 = setup["position"]
		_spawn_enemy(scene, position)
	_update_status("Push forward. Suppressors will fire if you leave them space.")


func _process(_delta: float) -> void:
	if GameState.is_run_failed:
		return
	var remaining_enemies := 0
	for child in enemy_container.get_children():
		if child.is_in_group("enemy"):
			remaining_enemies += 1
	if remaining_enemies == 0:
		_update_status("Sector clear. Press R to replay or keep moving.")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


func _spawn_enemy(scene: PackedScene, at_position: Vector2) -> void:
	var enemy: Node2D = scene.instantiate() as Node2D
	if enemy == null:
		return
	enemy.global_position = at_position
	enemy.set("player", player)
	if enemy.has_signal("defeated"):
		enemy.connect("defeated", Callable(self, "_on_enemy_defeated"))
	enemy_container.add_child(enemy)


func _on_enemy_defeated(points: int) -> void:
	GameState.add_score(points)


func _on_player_hit() -> void:
	GameState.lose_health(1)
	_update_status("Stay moving. Falling or trading hits will end the run.")


func _on_player_fell() -> void:
	GameState.finish_run(false)
	_update_status("You fell. Press R to restart.")


func _on_run_failed() -> void:
	_update_status("Run failed. Press R to restart.")


func _update_status(text: String) -> void:
	if hud.has_method("set_status"):
		hud.call("set_status", text)
