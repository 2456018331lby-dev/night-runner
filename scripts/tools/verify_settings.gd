extends Node

var failures: Array[String] = []


func _ready() -> void:
	var original_volume := GameState.get_master_volume()
	var original_haptics := GameState.are_haptics_enabled()
	var original_is_mobile := PlatformProfile.is_mobile
	var original_is_desktop := PlatformProfile.is_desktop
	var original_safe_area := PlatformProfile.safe_area_margin
	var original_light_haptic_msec := int(PlatformProfile.get("last_light_haptic_msec"))
	var original_warn_haptic_msec := int(PlatformProfile.get("last_warn_haptic_msec"))

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

	_verify_platform_boundaries()

	GameState.set_master_volume(original_volume, false)
	GameState.set_haptics_enabled(original_haptics, false)
	PlatformProfile.is_mobile = original_is_mobile
	PlatformProfile.is_desktop = original_is_desktop
	PlatformProfile.safe_area_margin = original_safe_area
	PlatformProfile.set("last_light_haptic_msec", original_light_haptic_msec)
	PlatformProfile.set("last_warn_haptic_msec", original_warn_haptic_msec)
	if failures.is_empty():
		print("Settings regression passed.")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _verify_platform_boundaries() -> void:
	PlatformProfile.is_mobile = false
	PlatformProfile.is_desktop = true
	PlatformProfile.safe_area_margin = Vector4(16.0, 16.0, 16.0, 16.0)
	_expect(PlatformProfile.get_safe_area_margin() == Vector4.ZERO, "desktop safe area returns zero margin")
	_expect(is_equal_approx(PlatformProfile.get_mobile_ui_scale(), 1.0), "desktop mobile ui scale stays neutral")
	_expect(not PlatformProfile.supports_haptics(), "desktop haptics support stays disabled")

	PlatformProfile.is_mobile = true
	PlatformProfile.is_desktop = false
	var mobile_scale := PlatformProfile.get_mobile_ui_scale()
	_expect(mobile_scale >= 0.82 and mobile_scale <= 1.0, "mobile ui scale stays within touch-safe clamp")
	_expect(PlatformProfile.supports_haptics() == Input.has_method("vibrate_handheld"), "mobile haptics support follows vibration API")

	GameState.set_haptics_enabled(false, false)
	_expect(not PlatformProfile.haptics_enabled(), "disabled haptics setting gates platform haptics")
	GameState.set_haptics_enabled(true, false)
	_expect(PlatformProfile.haptics_enabled() == PlatformProfile.supports_haptics(), "enabled haptics setting still requires platform support")
	_verify_haptic_cooldowns()

	_expect(
		_margin_matches(
			PlatformProfile.call("_calculate_safe_area_margin", Vector2i(2400, 1080), Rect2i(0, 0, 2400, 1080)),
			Vector4.ZERO
		),
		"full safe area produces zero margins"
	)
	_expect(
		_margin_matches(
			PlatformProfile.call("_calculate_safe_area_margin", Vector2i(2400, 1080), Rect2i(80, 24, 2200, 1000)),
			Vector4(80.0, 24.0, 120.0, 56.0)
		),
		"notch and gesture safe area margins are calculated from screen bounds"
	)
	_expect(
		_margin_matches(
			PlatformProfile.call("_calculate_safe_area_margin", Vector2i(2400, 1080), Rect2i(0, 0, 0, 0)),
			Vector4.ZERO
		),
		"invalid safe area produces zero margins"
	)
	_expect(
		_margin_matches(
			PlatformProfile.call("_calculate_safe_area_margin", Vector2i.ZERO, Rect2i(0, 0, 2400, 1080)),
			Vector4.ZERO
		),
		"invalid screen size produces zero margins"
	)


func _verify_haptic_cooldowns() -> void:
	PlatformProfile.set("last_light_haptic_msec", PlatformProfile.HAPTIC_INITIAL_MSEC)
	PlatformProfile.set("last_warn_haptic_msec", PlatformProfile.HAPTIC_INITIAL_MSEC)
	_expect(bool(PlatformProfile.call("_claim_light_haptic", 1000)), "first light haptic request is accepted")
	_expect(not bool(PlatformProfile.call("_claim_light_haptic", 1030)), "light haptic requests are throttled")
	_expect(bool(PlatformProfile.call("_claim_warn_haptic", 1040)), "warning haptic can pass through light cooldown")
	_expect(not bool(PlatformProfile.call("_claim_light_haptic", 1060)), "recent warning haptic suppresses follow-up light buzz")
	_expect(not bool(PlatformProfile.call("_claim_warn_haptic", 1120)), "warning haptic has its own cooldown")
	_expect(bool(PlatformProfile.call("_claim_warn_haptic", 1190)), "warning haptic recovers after cooldown")
	_expect(bool(PlatformProfile.call("_claim_light_haptic", 1270)), "light haptic recovers after warning cooldown")


func _margin_matches(actual: Variant, expected: Vector4) -> bool:
	if not actual is Vector4:
		return false
	var margin := actual as Vector4
	return margin.is_equal_approx(expected)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
