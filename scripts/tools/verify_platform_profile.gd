extends Node

var failures: Array[String] = []


func _ready() -> void:
	var original_is_mobile := PlatformProfile.is_mobile
	var original_is_desktop := PlatformProfile.is_desktop
	var original_safe_area := PlatformProfile.safe_area_margin
	var original_haptics := GameState.are_haptics_enabled()

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

	PlatformProfile.is_mobile = original_is_mobile
	PlatformProfile.is_desktop = original_is_desktop
	PlatformProfile.safe_area_margin = original_safe_area
	GameState.set_haptics_enabled(original_haptics, false)

	if failures.is_empty():
		print("Platform profile regression passed.")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _margin_matches(actual: Variant, expected: Vector4) -> bool:
	if not actual is Vector4:
		return false
	var margin := actual as Vector4
	return margin.is_equal_approx(expected)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
