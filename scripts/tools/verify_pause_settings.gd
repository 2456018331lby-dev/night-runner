extends Node

const SESSION_SCREEN_SCENE := preload("res://scenes/ui/session_screen.tscn")
const RunCatalogScript := preload("res://scripts/game/run_catalog.gd")

var failures: Array[String] = []


func _ready() -> void:
	var original_mobile := PlatformProfile.is_mobile
	var original_volume := GameState.get_master_volume()
	var original_haptics := GameState.are_haptics_enabled()
	PlatformProfile.is_mobile = true
	GameState.set_master_volume(0.7, false)
	GameState.set_haptics_enabled(true, false)

	var screen := SESSION_SCREEN_SCENE.instantiate()
	add_child(screen)
	await get_tree().process_frame

	var blitz := RunCatalogScript.get_operation("blitz_pursuit")
	var knife_party := _find_directive(blitz, "knife_party")
	var directive_detail := String(screen.call("_format_hub_directive_summary", knife_party, false))
	_expect(directive_detail.contains("Longer combo window"), "directive detail should include the directive summary")
	_expect(directive_detail.contains("COMBO +25%"), "directive detail should include combo modifier impact text")
	_expect(directive_detail.contains("ATK +12%"), "directive detail should keep multi-modifier impact text")

	screen.call("build_pause", RunCatalogScript.get_operation("blitz_pursuit"))
	await get_tree().process_frame

	var route_list: VBoxContainer = screen.get_node("Content/Root/Body/LeftPanel/LeftCol/RouteScroll/RouteList")
	var primary_button: Button = screen.get_node("Content/Root/Footer/ActionRow/Primary")
	var secondary_button: Button = screen.get_node("Content/Root/Footer/ActionRow/Secondary")
	var volume_slider := _find_first_child_of_type(route_list, HSlider) as HSlider
	var haptics_toggle := _find_first_child_of_type(route_list, CheckButton) as CheckButton
	_expect(volume_slider != null, "pause settings did not create a volume slider")
	_expect(haptics_toggle != null, "pause settings did not create a haptics toggle")
	_expect(primary_button.custom_minimum_size.y >= 56.0, "pause resume button is below mobile touch target height")
	_expect(secondary_button.custom_minimum_size.y >= 56.0, "pause hub button is below mobile touch target height")

	if volume_slider != null:
		_expect(volume_slider.custom_minimum_size.y >= 56.0, "volume slider is below mobile touch target height")
		_expect(is_equal_approx(volume_slider.value, 0.7), "volume slider did not mirror GameState volume")
		volume_slider.value = 0.45
		await get_tree().process_frame
		_expect(is_equal_approx(GameState.get_master_volume(), 0.45), "volume slider did not update GameState volume")

	if haptics_toggle != null:
		_expect(haptics_toggle.custom_minimum_size.y >= 56.0, "haptics toggle is below mobile touch target height")
		_expect(haptics_toggle.size_flags_horizontal == Control.SIZE_EXPAND_FILL, "haptics toggle should fill the pause settings column")
		_expect(haptics_toggle.button_pressed, "haptics toggle did not mirror GameState haptics")
		_expect(not haptics_toggle.disabled, "haptics toggle should be enabled on mobile profile")
		haptics_toggle.button_pressed = false
		await get_tree().process_frame
		_expect(not GameState.are_haptics_enabled(), "haptics toggle did not update GameState haptics")

	PlatformProfile.is_mobile = original_mobile
	GameState.set_master_volume(original_volume, false)
	GameState.set_haptics_enabled(original_haptics, false)

	if failures.is_empty():
		print("Pause settings regression passed.")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _find_first_child_of_type(root: Node, type_hint: Variant) -> Node:
	for child in root.get_children():
		if is_instance_of(child, type_hint):
			return child
		var nested := _find_first_child_of_type(child, type_hint)
		if nested != null:
			return nested
	return null


func _find_directive(operation: Dictionary, directive_id: String) -> Dictionary:
	for directive in operation.get("directive_pool", []):
		if String(directive.get("id", "")) == directive_id:
			return directive
	return {}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
