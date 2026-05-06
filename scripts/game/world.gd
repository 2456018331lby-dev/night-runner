extends Node2D

const RUNNER_SCENE := preload("res://scenes/actors/enemy_runner.tscn")
const SUPPRESSOR_SCENE := preload("res://scenes/actors/enemy_suppressor.tscn")
const DATA_CORE_SCENE := preload("res://scenes/game/data_core.tscn")

@onready var player: Node = $Player
@onready var enemy_container: Node2D = $Enemies
@onready var data_core_container: Node2D = $DataCores
@onready var extraction_gate: Area2D = $ExtractionGate
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
	{
		"scene": RUNNER_SCENE,
		"position": Vector2(1810, 44),
	},
]
var data_core_positions: Array[Vector2] = [
	Vector2(690, 350),
	Vector2(1124, 262),
	Vector2(1760, 70),
]
var current_status: String = ""


func _ready() -> void:
	GameState.run_failed.connect(_on_run_failed)
	GameState.run_finished.connect(_on_run_finished)
	player.player_fell.connect(_on_player_fell)
	player.player_hit.connect(_on_player_hit)
	extraction_gate.extraction_entered.connect(_on_extraction_entered)
	extraction_gate.extraction_blocked.connect(_on_extraction_blocked)
	if touch_controls.has_method("configure"):
		touch_controls.call("configure", PlatformProfile.should_show_touch_controls())


func begin() -> void:
	for setup in encounter_layout:
		var scene: PackedScene = setup["scene"]
		var position: Vector2 = setup["position"]
		_spawn_enemy(scene, position)
	GameState.set_data_core_total(data_core_positions.size())
	for core_position in data_core_positions:
		_spawn_data_core(core_position)
	if extraction_gate.has_method("set_unlocked"):
		extraction_gate.call("set_unlocked", false)
	_update_status("Steal every data core, then hit the extraction gate.")


func _process(_delta: float) -> void:
	if GameState.is_run_failed or GameState.run_success:
		return
	var remaining_enemies := 0
	for child in enemy_container.get_children():
		if child.is_in_group("enemy"):
			remaining_enemies += 1
	if GameState.extraction_unlocked:
		if remaining_enemies == 0:
			_update_status("Lane clear. Step into extraction for the clean finish.")
		else:
			_update_status("Extraction is live. Leave now or risk more score.")
	elif remaining_enemies == 0:
		_update_status("Sweep the rooftops. Find the remaining data cores.")


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


func _spawn_data_core(at_position: Vector2) -> void:
	var core: Area2D = DATA_CORE_SCENE.instantiate() as Area2D
	if core == null:
		return
	core.global_position = at_position
	core.collected.connect(_on_data_core_collected)
	data_core_container.add_child(core)


func _on_enemy_defeated(points: int) -> void:
	GameState.register_enemy_defeat(points)


func _on_player_hit() -> void:
	GameState.lose_health(1)
	_update_status("Stay moving. Taking hits will cost the whole run.")


func _on_player_fell() -> void:
	GameState.finish_run(false)
	_update_status("You fell. Press R to restart.")


func _on_run_failed() -> void:
	_update_status("Run failed. Press R to restart.")


func _on_run_finished(success: bool) -> void:
	if success:
		_update_status(GameState.result_summary)


func _on_data_core_collected() -> void:
	GameState.collect_data_core(250)
	var remaining := GameState.data_cores_total - GameState.data_cores_collected
	if remaining > 0:
		_update_status("Data core secured. %d left before extraction unlocks." % remaining)
		return
	if extraction_gate.has_method("set_unlocked"):
		extraction_gate.call("set_unlocked", true)
	_update_status("All cores secured. Extraction is now live.")


func _on_extraction_blocked() -> void:
	var remaining := GameState.data_cores_total - GameState.data_cores_collected
	_update_status("Extraction locked. Collect %d more data core(s)." % remaining)


func _on_extraction_entered() -> void:
	if GameState.is_run_failed or GameState.run_success:
		return
	var finish_bonus: int = GameState.health * 120 + max(0, 420 - int(GameState.elapsed_time * 18.0))
	GameState.add_score(finish_bonus)
	var rank := _calculate_rank()
	var summary := "Extraction complete. Rank %s. Score %04d. Press R to run again." % [rank, GameState.score]
	GameState.set_result(rank, summary)
	GameState.finish_run(true)


func _calculate_rank() -> String:
	if GameState.score >= 1600:
		return "S"
	if GameState.score >= 1250:
		return "A"
	if GameState.score >= 950:
		return "B"
	if GameState.score >= 700:
		return "C"
	return "D"


func _update_status(text: String) -> void:
	if current_status == text:
		return
	current_status = text
	if hud.has_method("set_status"):
		hud.call("set_status", text)
