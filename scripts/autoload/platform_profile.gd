extends Node

var is_mobile: bool = false
var is_desktop: bool = false
var safe_area_margin: Vector4 = Vector4.ZERO


func _ready() -> void:
	var platform_name := OS.get_name()
	is_mobile = platform_name == "Android" or platform_name == "iOS"
	is_desktop = not is_mobile
	_refresh_safe_area_margin()


func should_show_touch_controls() -> bool:
	return is_mobile


func get_safe_area_margin() -> Vector4:
	if not is_mobile:
		return Vector4.ZERO
	_refresh_safe_area_margin()
	return safe_area_margin


func get_mobile_ui_scale() -> float:
	if not is_mobile:
		return 1.0
	var viewport_size := get_viewport().get_visible_rect().size
	return clampf(viewport_size.x / 1280.0, 0.82, 1.0)


func supports_haptics() -> bool:
	return is_mobile


func haptics_enabled() -> bool:
	return supports_haptics() and GameState.are_haptics_enabled()


func vibrate_light() -> void:
	if not haptics_enabled():
		return
	if Input.has_method("vibrate_handheld"):
		Input.vibrate_handheld(30)


func vibrate_warn() -> void:
	if not haptics_enabled():
		return
	if Input.has_method("vibrate_handheld"):
		Input.vibrate_handheld(65)


func _refresh_safe_area_margin() -> void:
	var screen_size := DisplayServer.screen_get_size()
	var safe_area := DisplayServer.get_display_safe_area()
	if safe_area.size.x <= 0 or safe_area.size.y <= 0:
		safe_area_margin = Vector4.ZERO
		return
	safe_area_margin = Vector4(
		maxf(0.0, float(safe_area.position.x)),
		maxf(0.0, float(safe_area.position.y)),
		maxf(0.0, float(screen_size.x - safe_area.end.x)),
		maxf(0.0, float(screen_size.y - safe_area.end.y))
	)
