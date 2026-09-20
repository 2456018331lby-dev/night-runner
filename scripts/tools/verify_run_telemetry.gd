extends Node

## 校验一局结束时的 web telemetry 打点：死因、死亡坐标、阶段和 cashout overstay 都要真实。
## 改 GameState._build_run_telemetry / register_damage_source / world 的 fall 注册后先跑本场景。
##
## 注意：本场景直接改 GameState 字段并只读地调用 _build_run_telemetry()，
## 终局守卫段只调 finish_run() / lose_health() 的早退分支，不触发 start_run，
## 因此不会写 user:// 存档。

const REQUIRED_KEYS := [
	"run_id", "route_id", "directive_id", "success",
	"death_cause", "death_x_position", "death_y_position", "phase_reached",
	"cashout_overstay_seconds", "cores_collected", "final_score",
	"elapsed_time", "hits_taken", "max_combo", "extraction_unlocked",
]

# 死亡坐标未记录时的哨兵值。
const UNKNOWN_POSITION := -1.0

var failures: Array[String] = []


func _ready() -> void:
	var snapshot := _snapshot_state()
	_verify_key_contract()
	_verify_fall_death()
	_verify_enemy_death()
	_verify_hazard_death()
	_verify_success_run()
	_verify_phase_reached()
	_verify_unknown_position()
	_verify_terminal_state_guards()
	_restore_state(snapshot)

	if failures.is_empty():
		print("Run telemetry regression passed.")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _verify_key_contract() -> void:
	var telemetry: Dictionary = GameState.call("_build_run_telemetry")
	for key in REQUIRED_KEYS:
		_expect(telemetry.has(key), "telemetry carries key '%s'" % key)
	_expect(telemetry.get("route_id") is String, "telemetry route_id is a string")
	_expect(telemetry.get("success") is bool, "telemetry success is a bool")


func _verify_fall_death() -> void:
	# world.gd 的 _on_player_fell 现在会带上玩家坐标；跌落死因必须能被区分出来。
	_setup_run({"id": "blitz_pursuit"}, {"id": "base"})
	GameState.run_success = false
	GameState.data_cores_collected = 2
	GameState.register_damage_source("fall", "player_fell", Vector2(812.0, 905.0))
	var telemetry: Dictionary = GameState.call("_build_run_telemetry")
	_expect(String(telemetry.get("death_cause", "")) == "fall", "fall death reports death_cause 'fall'")
	_expect(is_equal_approx(float(telemetry.get("death_x_position", 0.0)), 812.0),
		"fall death reports the real x position (got %s)" % telemetry.get("death_x_position"))
	_expect(is_equal_approx(float(telemetry.get("death_y_position", 0.0)), 905.0),
		"fall death reports the real y position (got %s)" % telemetry.get("death_y_position"))


func _verify_enemy_death() -> void:
	_setup_run({"id": "ghost_circuit"}, {"id": "ghost_step"})
	GameState.run_success = false
	GameState.register_damage_source("enemy", "suppressor_bolt", Vector2(430.0, 260.0))
	var telemetry: Dictionary = GameState.call("_build_run_telemetry")
	_expect(String(telemetry.get("death_cause", "")) == "enemy_suppressor",
		"suppressor bolt death maps to 'enemy_suppressor' (got %s)" % telemetry.get("death_cause"))
	_expect(is_equal_approx(float(telemetry.get("death_x_position", 0.0)), 430.0),
		"enemy death reports the real x position")


func _verify_hazard_death() -> void:
	_setup_run({"id": "overdrive_protocol"}, {"id": "overdrive_core"})
	GameState.run_success = false
	GameState.register_damage_source("hazard", "pulse_beam", Vector2(1500.0, 300.0))
	var telemetry: Dictionary = GameState.call("_build_run_telemetry")
	_expect(String(telemetry.get("death_cause", "")) == "hazard", "hazard death reports 'hazard'")
	_expect(is_equal_approx(float(telemetry.get("death_x_position", 0.0)), 1500.0),
		"hazard death reports the real x position")


func _verify_success_run() -> void:
	_setup_run({"id": "blitz_pursuit"}, {"id": "base"})
	GameState.run_success = true
	GameState.extraction_unlocked = true
	GameState.extraction_unlock_time = 10.0
	GameState.elapsed_time = 34.0
	GameState.data_cores_collected = 5
	var telemetry: Dictionary = GameState.call("_build_run_telemetry")
	_expect(String(telemetry.get("death_cause", "")) == "success", "successful extraction reports 'success'")
	_expect(bool(telemetry.get("extraction_unlocked", false)), "telemetry reports extraction unlocked")
	_expect(int(telemetry.get("cashout_overstay_seconds", 0)) == 24,
		"telemetry reports cashout overstay seconds (got %s)" % telemetry.get("cashout_overstay_seconds"))
	_expect(int(telemetry.get("cores_collected", 0)) == 5, "telemetry reports collected cores")


func _verify_phase_reached() -> void:
	# 阶段应复用 World 实时维护的 live_route_phase，而不是静态推断。
	_setup_run({"id": "blitz_pursuit"}, {"id": "base"})
	GameState.set_live_route_status("CASHOUT", "Extraction open.", "Hazard net dormant.")
	_expect(String(GameState.call("_get_phase_reached")) == "cashout", "phase reached uses live_route_phase")
	GameState.set_live_route_status("BREACH", "Route building.", "Hazard net dormant.")
	_expect(String(GameState.call("_get_phase_reached")) == "breach", "phase reached tracks breach")


func _verify_unknown_position() -> void:
	# 没记录过伤害来源时不能把 (0,0) 当成真实坐标。
	_setup_run({"id": "blitz_pursuit"}, {"id": "base"})
	GameState.run_success = false
	var telemetry: Dictionary = GameState.call("_build_run_telemetry")
	_expect(is_equal_approx(float(telemetry.get("death_x_position", 0.0)), UNKNOWN_POSITION),
		"unknown death position uses the -1 sentinel for x")
	_expect(is_equal_approx(float(telemetry.get("death_y_position", 0.0)), UNKNOWN_POSITION),
		"unknown death position uses the -1 sentinel for y")


func _verify_terminal_state_guards() -> void:
	# 终局守卫：finish_run() 必须幂等（坠落事件会在多帧里重复触发），
	# 已经结束的局不能再记成绩、不能再掉血。
	# 本段刻意让 is_run_active 处于"已结束"状态，全部走早退分支，
	# 因此不会进入 _commit_run_record，也就不会写 user:// 存档。
	GameState.current_operation_id = "blitz_pursuit"
	GameState.current_directive = {"id": "base"}

	var runs_before := int(GameState.meta_progress.get("career_runs", 0))
	var successes_before := int(GameState.meta_progress.get("career_successes", 0))

	GameState.is_run_active = false
	GameState.is_run_failed = false
	GameState.run_success = false
	GameState.finish_run(true)
	_expect(int(GameState.meta_progress.get("career_runs", 0)) == runs_before,
		"finish_run must not record a run when no run is active")
	_expect(int(GameState.meta_progress.get("career_successes", 0)) == successes_before,
		"finish_run must not record a success when no run is active")
	_expect(not GameState.run_success, "finish_run must not flip the outcome when no run is active")

	# 已失败 / 已成功 / 未开局，三种终局态都不允许再扣血。
	GameState.is_run_active = true
	GameState.is_run_failed = true
	GameState.health = 2
	GameState.lose_health(1)
	_expect(GameState.health == 2, "lose_health must be ignored after the run already failed")

	GameState.is_run_failed = false
	GameState.run_success = true
	GameState.lose_health(1)
	_expect(GameState.health == 2, "lose_health must be ignored after a successful extraction")

	GameState.run_success = false
	GameState.is_run_active = false
	GameState.lose_health(1)
	_expect(GameState.health == 2, "lose_health must be ignored when no run is active")

	# 进行中的局仍然要正常扣血，守卫不能把正常路径一起吞掉。
	GameState.is_run_active = true
	GameState.lose_health(1)
	_expect(GameState.health == 1, "lose_health still applies during an active run")


func _setup_run(operation: Dictionary, directive: Dictionary) -> void:
	# 只设置 telemetry 需要的字段，绕开 start_run 的存档写入。
	GameState.current_operation_id = String(operation.get("id", ""))
	GameState.current_directive = directive.duplicate(true)
	GameState.run_success = false
	GameState.is_run_failed = true
	GameState.extraction_unlocked = false
	GameState.extraction_unlock_time = -1.0
	GameState.elapsed_time = 0.0
	GameState.data_cores_collected = 0
	GameState.data_cores_total = 5
	GameState.score = 0
	GameState.hits_taken = 0
	GameState.max_combo_reached = 0
	GameState.last_damage_source_kind = ""
	GameState.last_damage_source_detail = ""
	GameState.last_damage_position = Vector2.ZERO
	GameState.last_damage_position_recorded = false
	GameState.live_route_phase = "INGRESS"
	GameState.live_route_pressure = "Route cold."
	GameState.live_hazard_status = "Hazard net dormant."


func _snapshot_state() -> Dictionary:
	return {
		"current_operation_id": GameState.current_operation_id,
		"current_directive": GameState.current_directive.duplicate(true),
		"run_success": GameState.run_success,
		"is_run_failed": GameState.is_run_failed,
		"is_run_active": GameState.is_run_active,
		"health": GameState.health,
		"extraction_unlocked": GameState.extraction_unlocked,
		"extraction_unlock_time": GameState.extraction_unlock_time,
		"elapsed_time": GameState.elapsed_time,
		"data_cores_collected": GameState.data_cores_collected,
		"data_cores_total": GameState.data_cores_total,
		"score": GameState.score,
		"hits_taken": GameState.hits_taken,
		"max_combo_reached": GameState.max_combo_reached,
		"last_damage_source_kind": GameState.last_damage_source_kind,
		"last_damage_source_detail": GameState.last_damage_source_detail,
		"last_damage_position": GameState.last_damage_position,
		"last_damage_position_recorded": GameState.last_damage_position_recorded,
		"live_route_phase": GameState.live_route_phase,
		"live_route_pressure": GameState.live_route_pressure,
		"live_hazard_status": GameState.live_hazard_status,
	}


func _restore_state(snapshot: Dictionary) -> void:
	GameState.current_operation_id = String(snapshot["current_operation_id"])
	GameState.current_directive = Dictionary(snapshot["current_directive"]).duplicate(true)
	GameState.run_success = bool(snapshot["run_success"])
	GameState.is_run_failed = bool(snapshot["is_run_failed"])
	GameState.is_run_active = bool(snapshot["is_run_active"])
	GameState.health = int(snapshot["health"])
	GameState.extraction_unlocked = bool(snapshot["extraction_unlocked"])
	GameState.extraction_unlock_time = float(snapshot["extraction_unlock_time"])
	GameState.elapsed_time = float(snapshot["elapsed_time"])
	GameState.data_cores_collected = int(snapshot["data_cores_collected"])
	GameState.data_cores_total = int(snapshot["data_cores_total"])
	GameState.score = int(snapshot["score"])
	GameState.hits_taken = int(snapshot["hits_taken"])
	GameState.max_combo_reached = int(snapshot["max_combo_reached"])
	GameState.last_damage_source_kind = String(snapshot["last_damage_source_kind"])
	GameState.last_damage_source_detail = String(snapshot["last_damage_source_detail"])
	GameState.last_damage_position = Vector2(snapshot["last_damage_position"])
	GameState.last_damage_position_recorded = bool(snapshot["last_damage_position_recorded"])
	GameState.live_route_phase = String(snapshot["live_route_phase"])
	GameState.live_route_pressure = String(snapshot["live_route_pressure"])
	GameState.live_hazard_status = String(snapshot["live_hazard_status"])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
