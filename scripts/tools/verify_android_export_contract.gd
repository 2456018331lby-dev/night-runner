extends Node

const ANDROID_PRESET_NAME := "Android"
const EXPECTED_EXPORT_PATH := "exports/android/NightRunner-debug.apk"
const EXPECTED_PACKAGE_NAME := "com.nousresearch.nightrunner"
const EXPECTED_APP_NAME := "Night Runner"
const EXPECTED_VERSION_NAME := "0.1.0"
const REQUIRED_MIN_SDK := 24
const REQUIRED_TARGET_SDK := 35
const SENSOR_LANDSCAPE := 4

const REQUIRED_ICON_PATHS := [
	"res://assets/art/night_runner_icon.png",
	"res://assets/art/night_runner_icon_fg.png",
	"res://assets/art/night_runner_icon_bg.png",
	"res://assets/art/night_runner_boot.png",
]

var failures: Array[String] = []


func _ready() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load("res://export_presets.cfg")
	_expect(err == OK, "export_presets.cfg must be readable")
	if err != OK:
		_finish()
		return

	var preset_section := _find_preset_section(cfg, ANDROID_PRESET_NAME)
	_expect(not preset_section.is_empty(), "Android export preset exists")
	if preset_section.is_empty():
		_finish()
		return

	var options_section := "%s.options" % preset_section
	_verify_preset(cfg, preset_section, options_section)
	_verify_project_settings()
	_finish()


func _find_preset_section(cfg: ConfigFile, preset_name: String) -> String:
	for section in cfg.get_sections():
		if not section.begins_with("preset.") or section.ends_with(".options"):
			continue
		if String(cfg.get_value(section, "name", "")) == preset_name:
			return section
	return ""


func _verify_preset(cfg: ConfigFile, preset_section: String, options_section: String) -> void:
	_expect(String(cfg.get_value(preset_section, "platform", "")) == "Android", "Android preset uses Android platform")
	_expect(bool(cfg.get_value(preset_section, "runnable", false)), "Android preset remains runnable")
	_expect(String(cfg.get_value(preset_section, "export_path", "")) == EXPECTED_EXPORT_PATH, "Android APK export path stays stable")
	_expect(String(cfg.get_value(preset_section, "export_filter", "")) == "all_resources", "Android export includes all project resources")

	_expect(String(cfg.get_value(options_section, "package/unique_name", "")) == EXPECTED_PACKAGE_NAME, "Android package id stays stable")
	_expect(String(cfg.get_value(options_section, "package/name", "")) == EXPECTED_APP_NAME, "Android app name stays stable")
	_expect(bool(cfg.get_value(options_section, "package/signed", false)), "Android APK remains signed")
	_expect(not bool(cfg.get_value(options_section, "package/allow_backup", true)), "Android backup remains disabled")
	_expect(bool(cfg.get_value(options_section, "package/show_as_launcher_app", false)), "Android build remains launchable")
	_expect(bool(cfg.get_value(options_section, "architectures/arm64-v8a", false)), "Android build includes arm64-v8a")
	_expect(int(cfg.get_value(options_section, "gradle_build/export_format", -1)) == 0, "Android preset still exports APK format")
	_expect(int(cfg.get_value(options_section, "version/min_sdk", 0)) >= REQUIRED_MIN_SDK, "Android min SDK matches the Godot 4.6 runtime floor")
	_expect(int(cfg.get_value(options_section, "version/target_sdk", 0)) >= REQUIRED_TARGET_SDK, "Android target SDK stays current")
	_expect(String(cfg.get_value(options_section, "version/name", "")) == EXPECTED_VERSION_NAME, "Android version name stays stable")
	_expect(int(cfg.get_value(options_section, "orientation/screen", 0)) == SENSOR_LANDSCAPE, "Android orientation remains sensor landscape")
	_expect(bool(cfg.get_value(options_section, "screen/immersive_mode", false)), "Android build remains immersive")

	_expect_path_exists(String(cfg.get_value(options_section, "launcher_icons/main_192x192", "")), "Android main launcher icon exists")
	_expect_path_exists(String(cfg.get_value(options_section, "launcher_icons/adaptive_foreground_432x432", "")), "Android adaptive foreground icon exists")
	_expect_path_exists(String(cfg.get_value(options_section, "launcher_icons/adaptive_background_432x432", "")), "Android adaptive background icon exists")


func _verify_project_settings() -> void:
	_expect(String(ProjectSettings.get_setting("application/config/name", "")) == EXPECTED_APP_NAME, "Project app name stays stable")
	_expect(String(ProjectSettings.get_setting("application/run/main_scene", "")) == "res://scenes/app/main.tscn", "Project main scene stays on the app shell")
	_expect(String(ProjectSettings.get_setting("application/config/icon", "")) == "res://assets/art/night_runner_icon.png", "Project icon stays branded")
	_expect(String(ProjectSettings.get_setting("application/boot_splash/image", "")) == "res://assets/art/night_runner_boot.png", "Boot splash stays branded")
	_expect(String(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile", "")) == "mobile", "Android renderer stays on mobile")
	_expect(bool(ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc", false)), "Android texture compression remains enabled")
	_expect(int(ProjectSettings.get_setting("display/window/handheld/orientation", 0)) == SENSOR_LANDSCAPE, "Project handheld orientation remains sensor landscape")

	for path in REQUIRED_ICON_PATHS:
		_expect_path_exists(path, "required branded Android asset exists: %s" % path)


func _expect_path_exists(path: String, message: String) -> void:
	_expect(path.begins_with("res://") and FileAccess.file_exists(path), message)


func _finish() -> void:
	if failures.is_empty():
		print("Android export contract regression passed.")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
