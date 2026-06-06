extends Node

var failures: Array[String] = []


func _ready() -> void:
	var original_volume := GameState.get_master_volume()
	var original_haptics := GameState.are_haptics_enabled()

	var migrated: Dictionary = GameState.call("_merge_meta_progress", {
		"ux_flags": {
			"first_run_brief_seen": true,
		},
		"settings": {
			"master_volume": 0.35,
		},
	})
	var migrated_settings: Dictionary = migrated.get("settings", {})
	var migrated_ux: Dictionary = migrated.get("ux_flags", {})
	_expect(is_equal_approx(float(migrated_settings.get("master_volume", -1.0)), 0.35), "master volume survives save migration")
	_expect(bool(migrated_settings.get("haptics_enabled", false)), "missing haptics setting defaults on")
	_expect(bool(migrated_ux.get("first_run_brief_seen", false)), "existing ux flag survives migration")
	_expect(migrated_ux.has("blitz_hint_extract_seen"), "missing ux flags are backfilled")

	var repaired: Dictionary = GameState.call("_merge_meta_progress", {
		"ux_flags": "bad_flags",
		"settings": "bad_settings",
	})
	_expect(repaired.get("ux_flags", {}) is Dictionary, "malformed ux_flags are repaired")
	_expect(repaired.get("settings", {}) is Dictionary, "malformed settings are repaired")
	_expect(is_equal_approx(float(repaired.get("settings", {}).get("master_volume", -1.0)), 0.82), "malformed settings restore default volume")

	GameState.set_master_volume(0.4, false)
	_expect(is_equal_approx(GameState.get_master_volume(), 0.4), "master volume setter stores normalized value")
	var bus_index := AudioServer.get_bus_index("Master")
	if bus_index < 0:
		bus_index = 0
	var applied_volume := db_to_linear(AudioServer.get_bus_volume_db(bus_index))
	_expect(absf(applied_volume - 0.4) < 0.01, "master volume applies to AudioServer")

	GameState.set_master_volume(2.0, false)
	_expect(is_equal_approx(GameState.get_master_volume(), 1.0), "master volume clamps high values")
	GameState.set_master_volume(-1.0, false)
	_expect(is_equal_approx(GameState.get_master_volume(), 0.0), "master volume clamps low values")

	GameState.set_haptics_enabled(false, false)
	_expect(not GameState.are_haptics_enabled(), "haptics toggle stores false")
	GameState.set_haptics_enabled(true, false)
	_expect(GameState.are_haptics_enabled(), "haptics toggle stores true")

	GameState.set_master_volume(original_volume, false)
	GameState.set_haptics_enabled(original_haptics, false)
	if failures.is_empty():
		print("Settings regression passed.")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
