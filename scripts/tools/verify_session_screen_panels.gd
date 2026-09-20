extends Node

# 会话界面（大厅 / 暂停 / 结算）面板可见性回归。
#
# 覆盖两个曾经存在的缺陷：
#   1. HUB 会把信息列整体隐藏，但暂停与结算分支没有把控件恢复回来，
#      导致进入过一次大厅之后，右侧 Summary / Brief / Intel / 记录网格 / 指令区永久消失。
#   2. _apply_theme() 早于动态面板构建执行，对 route_banner_panel 与
#      first_run_brief_panel 的空判永远命中 null，样式覆盖全部丢失。

const SESSION_SCREEN_SCENE := preload("res://scenes/ui/session_screen.tscn")
const RunCatalogScript := preload("res://scripts/game/run_catalog.gd")
const INFO_COLUMN_CONTROLS: Array[String] = [
	"Summary",
	"Brief",
	"Intel",
	"RecordGrid",
	"DirectiveName",
	"DirectiveSummary",
]
const SELECTED_OPERATION_ID := "blitz_pursuit"

var failures: Array[String] = []


func _ready() -> void:
	# 独立场景里 main.gd 不会执行 bootstrap，这里用只读方式补齐桥接数据，
	# 避免调用 bootstrap() 触发存档写入。
	if FrontendBridge.operations.is_empty():
		FrontendBridge.operations = RunCatalogScript.shared().get_operations()
	FrontendBridge.selected_operation_id = SELECTED_OPERATION_ID

	var screen := SESSION_SCREEN_SCENE.instantiate()
	add_child(screen)
	await get_tree().process_frame
	await get_tree().process_frame

	var info_column := screen.get_node("Content/Root/Body/RightPanel/RightCol/InfoColumn")
	var directive_scroll: Control = screen.get_node("Content/Root/Body/RightPanel/RightCol/DirectiveScroll")

	var operations: Array = FrontendBridge.get_operations()
	_expect(not operations.is_empty(), "run catalog must expose at least one operation")
	var operation: Dictionary = FrontendBridge.get_operation(SELECTED_OPERATION_ID)
	_expect(not operation.is_empty(), "selected operation must resolve")
	if operations.is_empty() or operation.is_empty():
		_finish(screen)
		return

	# HUB 收起信息列属于设计意图，先确认前置状态成立。
	screen.call("build_hub", operations, SELECTED_OPERATION_ID)
	await get_tree().process_frame
	await get_tree().process_frame
	_expect_info_column(info_column, false, "HUB")
	_expect(not directive_scroll.visible, "HUB must collapse the directive list")

	screen.call("build_pause", operation)
	await get_tree().process_frame
	await get_tree().process_frame
	_expect_info_column(info_column, true, "PAUSE")
	_expect(directive_scroll.visible, "PAUSE must restore the directive list")

	screen.call("build_results", operation)
	await get_tree().process_frame
	await get_tree().process_frame
	_expect_info_column(info_column, true, "RESULTS")
	_expect(directive_scroll.visible, "RESULTS must restore the directive list")

	# 回到 HUB 再进暂停：隐藏与恢复必须可反复切换，而不是只生效一次。
	screen.call("build_hub", operations, SELECTED_OPERATION_ID)
	await get_tree().process_frame
	screen.call("build_pause", operation)
	await get_tree().process_frame
	await get_tree().process_frame
	_expect_info_column(info_column, true, "PAUSE after HUB round trip")

	# 主题应用顺序：动态构建的面板必须拿到 _apply_theme() 写入的扁平样式。
	var banner: PanelContainer = screen.get("route_banner_panel")
	_expect(banner != null, "route banner panel must be built at runtime")
	if banner != null:
		var banner_style := banner.get_theme_stylebox("panel") as StyleBoxFlat
		_expect(banner_style != null and banner_style.bg_color.a < 0.05, "route banner must use the flattened style applied after construction")

	var brief_panel: PanelContainer = screen.get("first_run_brief_panel")
	_expect(brief_panel != null, "first run brief panel must be built at runtime")
	if brief_panel != null:
		var brief_style := brief_panel.get_theme_stylebox("panel") as StyleBoxFlat
		_expect(brief_style != null and brief_style.bg_color.a < 0.05, "first run brief must use the flattened style applied after construction")

	_expect(
		screen.get_viewport().size_changed.is_connected(Callable(screen, "_on_viewport_resized")),
		"session screen must refresh its safe area on viewport resize"
	)

	_finish(screen)


func _finish(screen: Node) -> void:
	screen.queue_free()
	if failures.is_empty():
		print("Session screen panel regression passed.")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _expect_info_column(info_column: Node, expected_visible: bool, phase_label: String) -> void:
	for control_name in INFO_COLUMN_CONTROLS:
		var control := info_column.get_node_or_null(NodePath(control_name)) as Control
		if control == null:
			failures.append("%s: info column control %s is missing" % [phase_label, control_name])
			continue
		_expect(control.visible == expected_visible, "%s: %s visibility should be %s" % [phase_label, control_name, str(expected_visible)])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
