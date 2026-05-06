extends Node2D

const RUNNER_SCENE := preload("res://scenes/actors/enemy_runner.tscn")
const SUPPRESSOR_SCENE := preload("res://scenes/actors/enemy_suppressor.tscn")
const DATA_CORE_SCENE := preload("res://scenes/game/data_core.tscn")
const BOOST_PAD_SCENE := preload("res://scenes/game/boost_pad.tscn")

@onready var player: Node = $Player
@onready var enemy_container: Node2D = $Enemies
@onready var data_core_container: Node2D = $DataCores
@onready var boost_pad_container: Node2D = $BoostPads
@onready var extraction_gate: Area2D = $ExtractionGate
@onready var hud: CanvasLayer = $HUD
@onready var touch_controls: CanvasLayer = $TouchControls

var encounter_layout: Array[Dictionary] = [
	{
		"scene": RUNNER_SCENE,
		"position": Vector2(540, 348),
	},
	{
		"scene": SUPPRESSOR_SCENE,
		"position": Vector2(900, 188),
	},
	{
		"scene": RUNNER_SCENE,
		"position": Vector2(1290, 208),
	},
	{
		"scene": SUPPRESSOR_SCENE,
		"position": Vector2(1700, 78),
	},
	{
		"scene": RUNNER_SCENE,
		"position": Vector2(1810, 40),
	},
	{
		"scene": RUNNER_SCENE,
		"position": Vector2(1100, 612),
	},
	{
		"scene": SUPPRESSOR_SCENE,
		"position": Vector2(2050, 110),
	},
]
var data_core_positions: Array[Vector2] = [
	Vector2(690, 366),
	Vector2(1124, 278),
	Vector2(1500, 178),
	Vector2(1760, 92),
	Vector2(2050, 122),
]
var boost_pad_layout: Array[Dictionary] = [
	{
		"position": Vector2(494, 618),
		"boost_velocity": Vector2(420.0, -520.0),
	},
	{
		"position": Vector2(1124, 292),
		"boost_velocity": Vector2(340.0, -470.0),
	},
	{
		"position": Vector2(1716, 112),
		"boost_velocity": Vector2(300.0, -390.0),
	},
	{
		"position": Vector2(1934, 142),
		"boost_velocity": Vector2(280.0, -360.0),
	},
]
var reinforcements_spawned: bool = false
var current_objective: String = ""


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
	reinforcements_spawned = false
	for setup in encounter_layout:
		var scene: PackedScene = setup["scene"]
		var position: Vector2 = setup["position"]
		_spawn_enemy(scene, position)
	GameState.set_data_core_total(data_core_positions.size())
	for core_position in data_core_positions:
		_spawn_data_core(core_position)
	for pad_setup in boost_pad_layout:
		_spawn_boost_pad(pad_setup["position"], pad_setup["boost_velocity"])
	if extraction_gate.has_method("set_unlocked"):
		extraction_gate.call("set_unlocked", false)
	_set_objective("Steal all 3 data cores, then escape alive.")
	_show_toast("Sweep fast. Boost pads can catapult you between rooftops.", 2.8)


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


func _spawn_boost_pad(at_position: Vector2, boost_velocity: Vector2) -> void:
	var pad: Area2D = BOOST_PAD_SCENE.instantiate() as Area2D
	if pad == null:
		return
	pad.global_position = at_position
	pad.set("boost_velocity", boost_velocity)
	boost_pad_container.add_child(pad)


func _spawn_reinforcements() -> void:
	if reinforcements_spawned:
		return
	reinforcements_spawned = true
	_spawn_enemy(RUNNER_SCENE, Vector2(808, 372))
	_spawn_enemy(SUPPRESSOR_SCENE, Vector2(1498, 190))
	_spawn_enemy(RUNNER_SCENE, Vector2(1850, 74))
	_spawn_enemy(SUPPRESSOR_SCENE, Vector2(2120, 120))


func _on_enemy_defeated(points: int) -> void:
	GameState.register_enemy_defeat(points)
	if GameState.combo_count >= 3:
		_show_toast("Combo x%d. Keep pressure for bonus score." % GameState.combo_count, 1.6)


func _on_player_hit() -> void:
	GameState.lose_health(1)
	_show_toast("Hit taken. Preserve your last health for extraction bonus.", 1.9)


func _on_player_fell() -> void:
	GameState.finish_run(false)
	_set_objective("Run failed. Restart and reroute through the rooftops.")
	_show_toast("You fell off the route.", 2.0)


func _on_run_failed() -> void:
	_set_objective("Run failed. Restart and recover the route.")


func _on_run_finished(success: bool) -> void:
	if success:
		_set_objective("Extraction complete. Push for a higher rank on the next run.")
		_show_toast(GameState.result_summary, 3.0)


func _on_data_core_collected() -> void:
	GameState.collect_data_core(250)
	var remaining := GameState.data_cores_total - GameState.data_cores_collected
	if remaining > 0:
		_set_objective("Collect the remaining %d data core(s)." % remaining)
		_show_toast("Core secured. Keep moving before the lanes collapse.", 1.9)
		return
	if extraction_gate.has_method("set_unlocked"):
		extraction_gate.call("set_unlocked", true)
	_spawn_reinforcements()
	_set_objective("Extraction is live. Escape now or stay and farm the cleanup team.")
	_show_toast("Alarm tripped. Reinforcements inbound.", 2.4)


func _on_extraction_blocked() -> void:
	var remaining := GameState.data_cores_total - GameState.data_cores_collected
	_show_toast("Extraction locked. %d more data core(s) needed." % remaining, 1.8)


func _on_extraction_entered() -> void:
	if GameState.is_run_failed or GameState.run_success:
		return
	var finish_bonus: int = GameState.health * 120 + max(0, 420 - int(GameState.elapsed_time * 18.0))
	GameState.add_score(finish_bonus)
	var rank := _calculate_rank()
	var summary := "Rank %s. Score %04d. Press R to run again." % [rank, GameState.score]
	GameState.set_result(rank, summary)
	GameState.finish_run(true)


func _calculate_rank() -> String:
	if GameState.score >= 2000:
		return "S"
	if GameState.score >= 1550:
		return "A"
	if GameState.score >= 1150:
		return "B"
	if GameState.score >= 850:
		return "C"
	return "D"


func _set_objective(text: String) -> void:
	if current_objective == text:
		return
	current_objective = text
	if hud.has_method("set_objective"):
		hud.call("set_objective", text)


func _show_toast(text: String, duration: float = 2.3) -> void:
	if hud.has_method("show_toast"):
		hud.call("show_toast", text, duration)
