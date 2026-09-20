extends Node

const LIGHT_HAPTIC_COOLDOWN_MSEC := 75
const WARN_HAPTIC_COOLDOWN_MSEC := 140
const HAPTIC_INITIAL_MSEC := -1000000

var is_mobile: bool = false
var is_desktop: bool = false
var safe_area_margin: Vector4 = Vector4.ZERO
var last_light_haptic_msec: int = HAPTIC_INITIAL_MSEC
var last_warn_haptic_msec: int = HAPTIC_INITIAL_MSEC


func _ready() -> void:
	is_mobile = detect_is_mobile(
		OS.get_name(),
		OS.has_feature("web_android"),
		OS.has_feature("web_ios"),
		OS.has_feature("web_macos") or OS.has_feature("web_windows") or OS.has_feature("web_linuxbsd"),
		DisplayServer.is_touchscreen_available()
	)
	is_desktop = not is_mobile
	_refresh_safe_area_margin()


static func detect_is_mobile(
	platform_name: String,
	has_web_android: bool,
	has_web_ios: bool,
	has_desktop_web_tag: bool,
	touchscreen_available: bool
) -> bool:
	if platform_name == "Android" or platform_name == "iOS":
		return true
	if platform_name == "Web":
		# 手机浏览器里 OS.get_name() 也是 "Web"，优先用特性标签判断移动端，
		# 否则 web 版在手机上不会显示触控按键。
		if has_web_android or has_web_ios:
			return true
		# 桌面浏览器标签是权威判据：带触屏的笔记本仍按桌面处理，
		# 避免被误判成移动端（压缩 HUD + 强制触控按键）。
		if has_desktop_web_tag:
			return false
		# 标签都缺失时才退回触屏能力兜底。
		return touchscreen_available
	return false


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
	return is_mobile and Input.has_method("vibrate_handheld")


func haptics_enabled() -> bool:
	return supports_haptics() and GameState.are_haptics_enabled()


func vibrate_light() -> void:
	if not haptics_enabled():
		return
	if not _claim_light_haptic(Time.get_ticks_msec()):
		return
	Input.vibrate_handheld(30)


func vibrate_warn() -> void:
	if not haptics_enabled():
		return
	if not _claim_warn_haptic(Time.get_ticks_msec()):
		return
	Input.vibrate_handheld(65)


func _claim_light_haptic(now_msec: int) -> bool:
	if now_msec - last_light_haptic_msec < LIGHT_HAPTIC_COOLDOWN_MSEC:
		return false
	if now_msec - last_warn_haptic_msec < LIGHT_HAPTIC_COOLDOWN_MSEC:
		return false
	last_light_haptic_msec = now_msec
	return true


func _claim_warn_haptic(now_msec: int) -> bool:
	if now_msec - last_warn_haptic_msec < WARN_HAPTIC_COOLDOWN_MSEC:
		return false
	last_warn_haptic_msec = now_msec
	last_light_haptic_msec = now_msec
	return true


func _refresh_safe_area_margin() -> void:
	var screen_size := DisplayServer.screen_get_size()
	var safe_area := DisplayServer.get_display_safe_area()
	safe_area_margin = _calculate_safe_area_margin(screen_size, safe_area)


func _calculate_safe_area_margin(screen_size: Vector2i, safe_area: Rect2i) -> Vector4:
	if screen_size.x <= 0 or screen_size.y <= 0:
		return Vector4.ZERO
	if safe_area.size.x <= 0 or safe_area.size.y <= 0:
		return Vector4.ZERO
	return Vector4(
		maxf(0.0, float(safe_area.position.x)),
		maxf(0.0, float(safe_area.position.y)),
		maxf(0.0, float(screen_size.x - safe_area.end.x)),
		maxf(0.0, float(screen_size.y - safe_area.end.y))
	)
