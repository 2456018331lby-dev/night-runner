extends CanvasLayer

signal operation_chosen(operation_id: String)
signal launch_requested
signal retry_requested
signal resume_requested
signal hub_requested

const FONT_DISPLAY_SIZE := 28
const FONT_TITLE_SIZE := 18
const FONT_BODY_SIZE := 13
const FONT_CAPTION_SIZE := 11
const MOBILE_TOUCH_TARGET_MIN := 56.0
const MOBILE_ROUTE_BUTTON_HEIGHT := 124.0
const MOBILE_LOCKED_ROUTE_BUTTON_HEIGHT := 146.0
const PANEL_BG := Color("09121f")
const PANEL_LINE := Color("4fdcff")
const PANEL_ACCENT := Color("ff7b43")
const TEXT_PRIMARY := Color("f7fbff")
const TEXT_MUTED := Color("9bb0c9")
const TEXT_GOLD := Color("ffd37c")
const TEXT_ALERT := Color("ff9289")
const TEXT_SUCCESS := Color("98ffd2")
const TEXT_TEAL := Color("77ffe4")

@onready var backdrop: ColorRect = $Backdrop
@onready var content_margin: MarginContainer = $Content
@onready var title_label: Label = $Content/Root/Header/HeaderRow/TitleSection/Title
@onready var subtitle_label: Label = $Content/Root/Header/HeaderRow/TitleSection/Subtitle
@onready var status_label: Label = $Content/Root/Header/HeaderRow/StatusBadge/Status
@onready var body_row: HBoxContainer = $Content/Root/Body
@onready var route_list: VBoxContainer = $Content/Root/Body/LeftPanel/LeftCol/RouteScroll/RouteList
@onready var route_title: Label = $Content/Root/Body/LeftPanel/LeftCol/SectionTitle
@onready var focus_mode: Label = $Content/Root/Body/RightPanel/RightCol/InfoColumn/Mode
@onready var focus_title: Label = $Content/Root/Body/RightPanel/RightCol/InfoColumn/RouteTitle
@onready var focus_summary: Label = $Content/Root/Body/RightPanel/RightCol/InfoColumn/Summary
@onready var focus_brief: Label = $Content/Root/Body/RightPanel/RightCol/InfoColumn/Brief
@onready var focus_intel: Label = $Content/Root/Body/RightPanel/RightCol/InfoColumn/Intel
@onready var record_grid: GridContainer = $Content/Root/Body/RightPanel/RightCol/InfoColumn/RecordGrid
@onready var directive_name: Label = $Content/Root/Body/RightPanel/RightCol/InfoColumn/DirectiveName
@onready var directive_summary: Label = $Content/Root/Body/RightPanel/RightCol/InfoColumn/DirectiveSummary
@onready var directive_scroll: ScrollContainer = $Content/Root/Body/RightPanel/RightCol/DirectiveScroll
@onready var directive_list: VBoxContainer = $Content/Root/Body/RightPanel/RightCol/DirectiveScroll/DirectiveList
@onready var right_col: VBoxContainer = $Content/Root/Body/RightPanel/RightCol
@onready var footer_hint: Label = $Content/Root/Footer/Hint
@onready var primary_button: Button = $Content/Root/Footer/ActionRow/Primary
@onready var secondary_button: Button = $Content/Root/Footer/ActionRow/Secondary

var current_phase: String = FrontendBridge.PHASE_HUB
var operation_buttons: Dictionary = {}
var operation_button_data: Dictionary = {}
var directive_buttons: Dictionary = {}
var directive_button_data: Dictionary = {}
var ambient_pulse: float = 0.0
var first_run_brief_panel: PanelContainer
var first_run_brief_list: VBoxContainer
var decor_root: Control
var decor_signal_panel: PanelContainer
var decor_signal_label: Label
var decor_lines: Array[ColorRect] = []
var decor_corner_glow: ColorRect
var decor_bottom_bar: ColorRect
var bg_texture_rect: TextureRect
var route_banner_panel: PanelContainer
var route_banner_texture: TextureRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_backdrop_decor()
	_build_route_banner()
	_build_first_run_brief()
	_wire_actions()
	# 主题必须在所有动态面板构建完成之后再应用：route_banner_panel / first_run_brief_panel
	# 都是运行时 new 出来的，提前调用会让这两处的空判永远命中 null，样式覆盖全部丢失。
	_apply_theme()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_on_viewport_resized):
		# 安全区与移动端 UI 缩放都依赖视口尺寸（网页端画布缩放 / 设备旋转），
		# 必须随尺寸变化重新计算，否则边距会一直停留在首次布局时的值。
		viewport.size_changed.connect(_on_viewport_resized)
	visible = true


func _on_viewport_resized() -> void:
	_apply_theme()


func _process(delta: float) -> void:
	# CanvasLayer 常驻 _process，隐藏期间（对局中）直接跳过装饰动画与计时累积。
	if not visible:
		return
	ambient_pulse += delta
	_animate_decor(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("jump") or event.is_action_pressed("attack") or event.is_action_pressed("ui_accept"):
		if primary_button.visible and not primary_button.disabled:
			get_viewport().set_input_as_handled()
			primary_button.pressed.emit()
	elif event.is_action_pressed("ui_cancel"):
		if secondary_button.visible and not secondary_button.disabled:
			get_viewport().set_input_as_handled()
			secondary_button.pressed.emit()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1 and operation_buttons.has("blitz_pursuit"):
			_select_route("blitz_pursuit")
		elif event.keycode == KEY_2 and operation_buttons.has("ghost_circuit") and GameState.is_operation_unlocked("ghost_circuit"):
			_select_route("ghost_circuit")
		elif event.keycode == KEY_3 and operation_buttons.has("overdrive_protocol") and GameState.is_operation_unlocked("overdrive_protocol"):
			_select_route("overdrive_protocol")


func build_hub(operations: Array[Dictionary], selected_id: String) -> void:
	current_phase = FrontendBridge.PHASE_HUB
	show()
	_clear_route_list()
	title_label.text = "NIGHT RUNNER // 暗夜奔行者"
	subtitle_label.text = "赛博战术突入 · 核心撤离行动 (TACTICAL BREACH DECK)"
	status_label.text = "作战就绪 (READY)"
	route_title.text = "快速行动 (QUICK DEPLOY)" if not GameState.has_ux_flag("first_run_brief_seen") else "选择行动路线 (SELECT ROUTE)"
	footer_hint.text = "【操作指南】A/D 移动 · 空格 跳跃 · J 键连续挥砍 · K 键无敌冲刺 (按 空格/回车 直接开打)"
	primary_button.text = _get_launch_button_text(FrontendBridge.get_operation(selected_id))
	secondary_button.text = ""
	secondary_button.visible = false
	primary_button.disabled = selected_id.is_empty() or not GameState.is_operation_unlocked(selected_id)
	for operation in operations:
		_add_route_button(operation, selected_id)
	_refresh_focus(FrontendBridge.get_operation(selected_id))
	_refresh_first_run_brief()


func build_results(operation: Dictionary) -> void:
	current_phase = FrontendBridge.PHASE_RESULTS
	show()
	_clear_route_list()
	title_label.text = "行动成功 (MISSION COMPLETE)" if GameState.run_success else "行动失败 (MISSION FAILED)"
	subtitle_label.text = "最终评级: %s · 结算得分: %04d" % [GameState.final_rank, GameState.score]
	status_label.text = "战后复盘 (DEBRIEF)"
	route_title.text = "作战数据统计 (RUN METRICS)"
	footer_hint.text = "按 空格 或 J 键可立即重新开始；按 Esc 返回主大厅。"
	primary_button.text = "⚡ 重新开始 (RETRY)"
	secondary_button.text = "⮌ 返回大厅 (HUB)"
	secondary_button.visible = true
	secondary_button.disabled = false
	primary_button.disabled = false
	_add_debrief_metrics(operation)
	_refresh_focus(operation)
	_refresh_first_run_brief()


func build_pause(operation: Dictionary) -> void:
	current_phase = FrontendBridge.PHASE_PAUSE
	show()
	_clear_route_list()
	title_label.text = "战术暂停 (PAUSED)"
	subtitle_label.text = "当前得分 %04d · 数据核心 %d/%d · 护盾生命 %d" % [GameState.score, GameState.data_cores_collected, GameState.data_cores_total, GameState.health]
	status_label.text = "战术挂起 (HOLD)"
	route_title.text = "实时战况 (LIVE DATA)"
	footer_hint.text = "按 空格 或 回车 继续行动；按 Esc 放弃并返回大厅。"
	primary_button.text = "▶ 继续行动 (RESUME)"
	secondary_button.text = "⮌ 返回大厅 (HUB)"
	secondary_button.visible = true
	secondary_button.disabled = false
	primary_button.disabled = false
	_add_pause_metrics()
	_add_pause_settings()
	_refresh_focus(operation)
	_refresh_first_run_brief()


func hide_for_run() -> void:
	hide()


func _clear_route_list() -> void:
	operation_buttons.clear()
	operation_button_data.clear()
	for child in route_list.get_children():
		child.queue_free()


func _clear_directive_list() -> void:
	directive_buttons.clear()
	directive_button_data.clear()
	for child in directive_list.get_children():
		child.queue_free()


func _refresh_focus(operation: Dictionary) -> void:
	var selected := operation if not operation.is_empty() else FrontendBridge.get_selected_operation()
	var operation_id := String(selected.get("id", ""))
	var record := GameState.get_operation_record(operation_id)
	var first_deploy_focus := _is_first_deploy_focus(operation_id)
	focus_mode.text = String(selected.get("mode_label", ""))
	focus_title.text = String(selected.get("title", "Select a route"))
	focus_summary.text = String(selected.get("summary", ""))
	focus_brief.text = String(selected.get("brief", ""))
	focus_intel.text = String(selected.get("intel", ""))
	var lane_signals: Array = selected.get("lane_signals", [])
	if not lane_signals.is_empty():
		focus_intel.text += "\n" + " · ".join(lane_signals)
	for child in record_grid.get_children():
		child.queue_free()
	_add_stat_pair("Best Score", "%04d" % int(record.get("best_score", 0)))
	_add_stat_pair("Best Rank", String(record.get("best_rank", "--")))
	_add_stat_pair("Runs", str(int(record.get("runs", 0))))
	_add_stat_pair("Win Rate", "%d%%" % int(round(float(record.get("successes", 0)) / maxi(1, int(record.get("runs", 0))) * 100.0)) if int(record.get("runs", 0)) > 0 else "--")
	record_grid.visible = not (PlatformProfile.is_mobile and current_phase == FrontendBridge.PHASE_HUB)
	focus_brief.visible = not (PlatformProfile.is_mobile and current_phase == FrontendBridge.PHASE_HUB)
	if first_deploy_focus:
		focus_summary.text = "First route online. Move fast, secure all 5 cores, then extract clean."
		focus_intel.text = "Default directive is already armed for your first clear."
	if current_phase == FrontendBridge.PHASE_HUB:
		focus_summary.visible = false
		focus_brief.visible = false
		focus_intel.visible = false
		record_grid.visible = false
		directive_name.visible = false
		directive_summary.visible = false
		directive_scroll.visible = false
		if route_banner_panel != null and route_banner_texture != null:
			var logo_path := "res://assets/art/title_logo.png"
			if ResourceLoader.exists(logo_path):
				route_banner_texture.texture = load(logo_path) as Texture2D
				route_banner_panel.visible = true
				route_banner_panel.custom_minimum_size = Vector2(0, 160)
				route_banner_texture.custom_minimum_size = Vector2(0, 150)
				route_banner_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			else:
				route_banner_panel.visible = false
		focus_mode.text = "赛博战术跑酷行动"
		focus_title.text = String(selected.get("title", "极速突破"))
		var selected_directive := FrontendBridge.get_selected_directive(operation_id)
		_set_hub_directive_detail(selected_directive, first_deploy_focus)
		_populate_directive_list(selected)
		primary_button.text = _get_launch_button_text(selected)
	else:
		if route_banner_panel != null:
			route_banner_panel.visible = false
		# HUB 会把信息列的 Summary / Brief / Intel / 记录网格 / 指令区整体隐藏，
		# 暂停与结算分支必须显式恢复它们，否则进入过一次 HUB 之后，
		# 右侧战况与复盘内容将永久不可见。
		focus_summary.visible = true
		focus_brief.visible = true
		focus_intel.visible = true
		record_grid.visible = true
		directive_name.visible = true
		directive_summary.visible = true
		directive_name.text = "AFTER ACTION" if current_phase == FrontendBridge.PHASE_RESULTS else GameState.get_current_directive_name()
		directive_summary.text = "Why the run ended, what worked, and what to change next." if current_phase == FrontendBridge.PHASE_RESULTS else GameState.get_current_directive_summary()
		directive_scroll.visible = true
		_clear_directive_list()
		if current_phase == FrontendBridge.PHASE_RESULTS:
			focus_mode.text = "SUCCESS" if GameState.run_success else "RECOVERY"
			_add_result_card("WHY YOU WON" if GameState.run_success else "WHY YOU LOST", [GameState.get_result_outcome_summary()], TEXT_SUCCESS if GameState.run_success else TEXT_ALERT)
			_add_result_card("TRY NEXT", [GameState.get_result_next_hint()], TEXT_TEAL)
			_add_result_card("RUN VERDICT", [GameState.get_run_verdict_text()], TEXT_GOLD)
			_add_result_card("RANK REPORT", GameState.get_run_rank_report_lines(), TEXT_TEAL)
			_add_result_card("SCORE BREAKDOWN", GameState.get_run_score_breakdown_lines(), PANEL_LINE)
			if not GameState.run_success and int(GameState.meta_progress.get("career_failures", 0)) == 1:
				_add_result_card("QUICK REMINDER", GameState.get_quick_reminder_lines(), TEXT_ALERT)
		elif current_phase == FrontendBridge.PHASE_PAUSE:
			_add_directive_note("Optional: %s" % GameState.get_secondary_objective_status_text(), TEXT_PRIMARY)
	_update_palette(selected)
	_refresh_decor_signal(selected)


func _is_first_deploy_focus(operation_id: String) -> bool:
	return current_phase == FrontendBridge.PHASE_HUB and PlatformProfile.is_mobile and not GameState.has_ux_flag("first_run_brief_seen") and operation_id == "blitz_pursuit"


func _populate_directive_list(operation: Dictionary) -> void:
	_clear_directive_list()
	var operation_id := String(operation.get("id", ""))
	var selected_directive := FrontendBridge.get_selected_directive(operation_id)
	for directive in operation.get("directive_pool", []):
		_add_directive_button(operation, directive, String(directive.get("id", "")) == String(selected_directive.get("id", "")))


func _add_route_button(operation: Dictionary, selected_id: String) -> void:
	var btn := Button.new()
	var operation_id := String(operation.get("id", ""))
	var selected := operation_id == selected_id
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.focus_mode = Control.FOCUS_NONE
	btn.toggle_mode = true
	btn.pressed.connect(func(): _select_route(operation_id))
	btn.add_theme_color_override("font_color", TEXT_PRIMARY)
	btn.add_theme_color_override("font_disabled_color", TEXT_MUTED)
	btn.add_theme_font_size_override("font_size", 15 if PlatformProfile.is_mobile else 16)
	_set_route_button_state(btn, operation, selected)
	route_list.add_child(btn)
	operation_buttons[operation_id] = btn
	operation_button_data[operation_id] = operation.duplicate(true)


func _add_directive_button(operation: Dictionary, directive: Dictionary, selected: bool) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 46 if not PlatformProfile.is_mobile else 72)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.focus_mode = Control.FOCUS_NONE
	btn.toggle_mode = true
	var operation_id := String(operation.get("id", ""))
	var directive_id := String(directive.get("id", ""))
	btn.pressed.connect(func(): _select_directive(operation_id, directive_id))
	btn.add_theme_color_override("font_color", TEXT_PRIMARY)
	btn.add_theme_color_override("font_disabled_color", TEXT_MUTED)
	btn.add_theme_font_size_override("font_size", 13 if not PlatformProfile.is_mobile else 14)
	_set_directive_button_state(btn, directive, selected)
	directive_list.add_child(btn)
	directive_buttons[directive_id] = btn
	directive_button_data[directive_id] = directive.duplicate(true)


func _select_route(operation_id: String) -> void:
	FrontendBridge.select_operation(operation_id)
	for key in operation_buttons.keys():
		var btn: Button = operation_buttons[key]
		var operation: Dictionary = operation_button_data.get(key, {})
		_set_route_button_state(btn, operation, key == operation_id)
	primary_button.disabled = not GameState.is_operation_unlocked(operation_id)
	_refresh_focus(FrontendBridge.get_operation(operation_id))
	operation_chosen.emit(operation_id)


func _set_route_button_state(btn: Button, operation: Dictionary, selected: bool) -> void:
	btn.toggle_mode = true
	var operation_id := String(operation.get("id", ""))
	var unlocked := GameState.is_operation_unlocked(operation_id)
	var title := String(operation.get("title", ""))
	var mode := String(operation.get("mode_label", ""))
	var subtitle := String(operation.get("subtitle", ""))
	var lock_text := String(operation.get("locked_text", ""))
	var state_label := "LOCKED"
	if unlocked:
		state_label = "ACTIVE" if selected else "READY"
	var title_cn := ""
	match operation_id:
		"blitz_pursuit":
			title_cn = "极速突破 (Blitz Pursuit)"
		"ghost_circuit":
			title_cn = "幽灵潜行 (Ghost Circuit)"
		"overdrive_protocol":
			title_cn = "过载协议 (Overdrive Protocol)"
		_:
			title_cn = title
	if PlatformProfile.is_mobile:
		btn.text = "%s  %s\n%s\n%s" % [state_label, title_cn, mode, _format_mobile_route_record(operation_id)]
	else:
		btn.text = "%s  %s\n%s\n%s" % [state_label, title_cn, mode, subtitle]
	if not unlocked and not lock_text.is_empty():
		btn.text += "\n%s" % lock_text
	if PlatformProfile.is_mobile:
		btn.custom_minimum_size = Vector2(0, MOBILE_ROUTE_BUTTON_HEIGHT if unlocked else MOBILE_LOCKED_ROUTE_BUTTON_HEIGHT)
	else:
		btn.custom_minimum_size = Vector2(0, 68 if unlocked else 80)
	btn.disabled = not unlocked
	btn.button_pressed = selected
	var theme: Dictionary = operation.get("theme", {})
	var primary: Color = theme.get("primary", PANEL_LINE)
	var secondary: Color = theme.get("secondary", PANEL_ACCENT)
	var fill := Color(primary.r * 0.09 + 0.03, primary.g * 0.08 + 0.04, primary.b * 0.1 + 0.07, 0.9) if selected else Color(primary.r * 0.05 + 0.02, primary.g * 0.05 + 0.03, primary.b * 0.08 + 0.07, 0.72)
	var line: Color = secondary if selected else Color(primary.r, primary.g, primary.b, 0.34)
	btn.add_theme_stylebox_override("normal", _make_style(fill, line, 10, 2 if selected else 1, 12))
	btn.add_theme_stylebox_override("hover", _make_style(fill.lightened(0.08), secondary.lightened(0.06), 10, 2, 14))
	btn.add_theme_stylebox_override("pressed", _make_style(fill.darkened(0.08), secondary, 10, 2, 8))


func _format_mobile_route_record(operation_id: String) -> String:
	var record := GameState.get_operation_record(operation_id)
	return "BEST %04d // RANK %s\nTIME %s // RUNS %d" % [
		int(record.get("best_score", 0)),
		String(record.get("best_rank", "--")),
		_format_record_time(float(record.get("best_time", 0.0))),
		int(record.get("runs", 0)),
	]


func _format_record_time(time_value: float) -> String:
	if time_value <= 0.0:
		return "--"
	var total_seconds := int(time_value)
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]


func _select_directive(operation_id: String, directive_id: String) -> void:
	FrontendBridge.select_directive(operation_id, directive_id)
	for key in directive_buttons.keys():
		var btn: Button = directive_buttons[key]
		var sel := String(key) == directive_id
		var directive: Dictionary = directive_button_data.get(key, {})
		_set_directive_button_state(btn, directive, sel)
	_set_hub_directive_detail(FrontendBridge.get_selected_directive(operation_id), _is_first_deploy_focus(operation_id))


func _set_directive_button_state(btn: Button, directive: Dictionary, selected: bool) -> void:
	btn.toggle_mode = true
	var modifier_summary := GameState.describe_modifier_block(Dictionary(directive.get("modifiers", {})))
	var directive_name_raw := String(directive.get("name", ""))
	var name_cn := ""
	match directive_name_raw:
		"Surge Injection":
			name_cn = "过载奔行 (Surge Injection)"
		"Knife Party":
			name_cn = "刀锋派对 (Knife Party)"
		"Redline Thrusters":
			name_cn = "红线喷射 (Redline Thrusters)"
		"Cloak Battery":
			name_cn = "隐形电池 (Cloak Battery)"
		"Null Siphon":
			name_cn = "虚空汲取 (Null Siphon)"
		"Ghost Step":
			name_cn = "幽灵漫步 (Ghost Step)"
		"Risk Multiplier":
			name_cn = "高危倍率 (Risk Multiplier)"
		"Adrenaline Harvest":
			name_cn = "肾上腺素 (Adrenaline Harvest)"
		"Double Down":
			name_cn = "孤注一掷 (Double Down)"
		_:
			name_cn = directive_name_raw
	btn.text = "%s  %s" % [("ACTIVE" if selected else "OPTION"), name_cn]
	if not PlatformProfile.is_mobile:
		btn.text += "\n%s" % String(directive.get("summary", ""))
	if not modifier_summary.is_empty():
		btn.text += "\n%s" % modifier_summary
	btn.button_pressed = selected
	var fill := Color(0.05, 0.06, 0.13, 0.9) if selected else Color(0.04, 0.06, 0.11, 0.7)
	var line: Color = (PANEL_ACCENT if selected else Color(0.3, 0.45, 0.6, 0.3))
	btn.add_theme_stylebox_override("normal", _make_style(fill, line, 8, 2 if selected else 1))
	btn.add_theme_stylebox_override("hover", _make_style(fill.lightened(0.06), line.lightened(0.1), 8, 2))
	btn.add_theme_stylebox_override("pressed", _make_style(fill.darkened(0.08), line, 8, 2))


func _set_hub_directive_detail(selected_directive: Dictionary, first_deploy_focus: bool) -> void:
	directive_name.text = String(selected_directive.get("name", "Base Protocol"))
	directive_summary.text = _format_hub_directive_summary(selected_directive, first_deploy_focus)


func _format_hub_directive_summary(selected_directive: Dictionary, first_deploy_focus: bool) -> String:
	var lines: Array[String] = ["Deploy directive"]
	if first_deploy_focus:
		lines.append("Default first-clear loadout. Launch now and learn the lane before tuning modifiers.")
	else:
		lines.append(String(selected_directive.get("summary", "")))
	var modifier_summary := GameState.describe_modifier_block(Dictionary(selected_directive.get("modifiers", {})))
	if not modifier_summary.is_empty():
		lines.append(modifier_summary)
	return "\n".join(lines)


func _add_debrief_metrics(operation: Dictionary) -> void:
	var record := GameState.get_operation_record(String(operation.get("id", "")))
	var metrics := GameState.get_run_metrics()
	_add_route_note("Rank %s · %04d" % [GameState.final_rank, GameState.score], TEXT_GOLD)
	_add_route_note("Career best %04d" % int(GameState.meta_progress.get("highest_score", 0)), TEXT_MUTED)
	_add_route_note("Route best %04d · Rank %s · Time %s · Runs %d" % [
		int(record.get("best_score", 0)),
		String(record.get("best_rank", "--")),
		_format_record_time(float(record.get("best_time", 0.0))),
		int(record.get("runs", 0)),
	], TEXT_MUTED)
	_add_route_note("Combat +%d · Cores +%d" % [int(metrics.get("combat_score", 0)), int(metrics.get("core_score", 0))], TEXT_TEAL)
	_add_route_note("Exit +%d · Cashout +%d" % [int(metrics.get("exit_bonus", 0)), int(metrics.get("cashout_bonus", 0))], TEXT_PRIMARY)
	if GameState.double_down_taken:
		if GameState.run_success:
			_add_route_note("Double-down honored · bank x2 (+%d)" % GameState.double_down_bonus_gained, TEXT_GOLD)
		else:
			_add_route_note("Double-down lost · +%d gone with the bank" % GameState.pending_extraction_bonus, TEXT_ALERT)
	_add_route_note("Why: %s" % GameState.get_result_outcome_summary(), TEXT_PRIMARY)
	_add_route_note("Try next: %s" % GameState.get_result_next_hint(), TEXT_MUTED)


func _add_pause_metrics() -> void:
	_add_route_note("Time %s" % GameState.formatted_time(), TEXT_PRIMARY)
	_add_route_note("Combo %d · HP %d" % [GameState.combo_count, GameState.health], TEXT_MUTED)
	var route_pressure := _format_pause_route_pressure(GameState.get_route_pressure_text())
	if route_pressure.is_empty():
		_add_route_note("Route %s" % GameState.get_route_phase_text(), TEXT_TEAL)
	else:
		_add_route_note("Route %s · %s" % [GameState.get_route_phase_text(), route_pressure], TEXT_TEAL)
	if GameState.extraction_unlocked or GameState.extraction_bonus_active:
		_add_route_note("Cashout %s" % GameState.get_extraction_bonus_status_text().split(" // ")[0], TEXT_GOLD if GameState.pending_extraction_bonus > 0 else TEXT_MUTED)
	var hazard_status := GameState.get_hazard_status_text()
	if not hazard_status.is_empty() and hazard_status != "Hazard net dormant.":
		_add_route_note("Hazard %s" % hazard_status.replace(" // ", " · "), TEXT_ALERT)


func _add_pause_settings() -> void:
	_add_route_note("", TEXT_MUTED)
	var settings_label := Label.new()
	settings_label.text = "SETTINGS"
	settings_label.add_theme_font_size_override("font_size", int(12 * PlatformProfile.get_mobile_ui_scale()))
	settings_label.add_theme_color_override("font_color", TEXT_GOLD)
	route_list.add_child(settings_label)

	var vol_label := Label.new()
	vol_label.add_theme_font_size_override("font_size", int(13 * PlatformProfile.get_mobile_ui_scale()))
	vol_label.add_theme_color_override("font_color", TEXT_PRIMARY)
	route_list.add_child(vol_label)
	var vol_slider := HSlider.new()
	vol_slider.min_value = 0.0
	vol_slider.max_value = 1.0
	vol_slider.step = 0.05
	vol_slider.value = GameState.get_master_volume()
	vol_slider.custom_minimum_size = Vector2(228, _get_pause_control_height())
	vol_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_update_volume_label(vol_label, vol_slider.value)
	vol_slider.value_changed.connect(func(val: float) -> void:
		GameState.set_master_volume(val)
		_update_volume_label(vol_label, val)
	)
	route_list.add_child(vol_slider)

	var haptics_toggle := CheckButton.new()
	haptics_toggle.text = "HAPTICS"
	haptics_toggle.button_pressed = GameState.are_haptics_enabled()
	haptics_toggle.disabled = not PlatformProfile.supports_haptics()
	haptics_toggle.focus_mode = Control.FOCUS_NONE
	haptics_toggle.custom_minimum_size = Vector2(0, _get_pause_control_height())
	haptics_toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	haptics_toggle.add_theme_font_size_override("font_size", int(13 * PlatformProfile.get_mobile_ui_scale()))
	haptics_toggle.add_theme_color_override("font_color", TEXT_PRIMARY)
	haptics_toggle.add_theme_color_override("font_disabled_color", TEXT_MUTED)
	haptics_toggle.toggled.connect(func(enabled: bool) -> void:
		GameState.set_haptics_enabled(enabled)
		if enabled:
			PlatformProfile.vibrate_light()
	)
	route_list.add_child(haptics_toggle)


func _update_volume_label(label: Label, value: float) -> void:
	label.text = "VOLUME %d%%" % int(round(clampf(value, 0.0, 1.0) * 100.0))


func _format_pause_route_pressure(pressure_text: String) -> String:
	var compact := pressure_text.strip_edges()
	if compact.is_empty():
		return ""
	return compact.split(".")[0].strip_edges()


func _get_pause_control_height() -> float:
	if PlatformProfile.is_mobile:
		return maxf(MOBILE_TOUCH_TARGET_MIN, MOBILE_TOUCH_TARGET_MIN * PlatformProfile.get_mobile_ui_scale())
	return 40.0


func _add_route_note(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	route_list.add_child(label)


func _add_directive_note(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	directive_list.add_child(label)


func _add_result_card(title: String, lines: Array[String], accent: Color) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_style(Color(0.05, 0.08, 0.14, 0.9), accent, 10, 1, 8))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	margin.add_child(column)
	var title_label_local := Label.new()
	title_label_local.text = title
	title_label_local.add_theme_font_size_override("font_size", 11 if PlatformProfile.is_mobile else 12)
	title_label_local.add_theme_color_override("font_color", accent)
	column.add_child(title_label_local)
	for line in lines:
		var body := Label.new()
		body.text = line
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_theme_font_size_override("font_size", 14)
		body.add_theme_color_override("font_color", TEXT_PRIMARY)
		column.add_child(body)
	directive_list.add_child(panel)


func _add_stat_pair(caption: String, value: String) -> void:
	var caption_cn := caption
	match caption:
		"Best Score":
			caption_cn = "最高得分 (Best Score)"
		"Best Rank":
			caption_cn = "最高评级 (Best Rank)"
		"Runs":
			caption_cn = "行动次数 (Runs)"
		"Win Rate":
			caption_cn = "撤离胜率 (Win Rate)"
	var l1 := Label.new()
	l1.text = caption_cn
	l1.add_theme_font_size_override("font_size", 11)
	l1.add_theme_color_override("font_color", TEXT_MUTED)
	record_grid.add_child(l1)
	var l2 := Label.new()
	l2.text = value
	l2.add_theme_font_size_override("font_size", 13)
	l2.add_theme_color_override("font_color", TEXT_PRIMARY)
	record_grid.add_child(l2)


func _update_palette(operation: Dictionary) -> void:
	var theme: Dictionary = operation.get("theme", {})
	if theme.is_empty():
		return
	var primary: Color = theme.get("primary", PANEL_LINE)
	var secondary: Color = theme.get("secondary", PANEL_ACCENT)
	status_label.add_theme_color_override("font_color", secondary)
	focus_mode.add_theme_color_override("font_color", secondary)
	title_label.add_theme_color_override("font_color", primary.lightened(0.2))


func _wire_actions() -> void:
	primary_button.pressed.connect(func() -> void:
		match current_phase:
			FrontendBridge.PHASE_HUB:
				launch_requested.emit()
			FrontendBridge.PHASE_RESULTS:
				retry_requested.emit()
			FrontendBridge.PHASE_PAUSE:
				resume_requested.emit()
	)
	secondary_button.pressed.connect(func() -> void:
		hub_requested.emit()
	)


func _build_first_run_brief() -> void:
	first_run_brief_panel = PanelContainer.new()
	first_run_brief_panel.custom_minimum_size = Vector2(0, 96)
	first_run_brief_list = VBoxContainer.new()
	first_run_brief_list.add_theme_constant_override("separation", 4)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	first_run_brief_panel.add_child(margin)
	margin.add_child(first_run_brief_list)
	first_run_brief_panel.add_theme_stylebox_override("panel", _make_style(Color("0d1726"), PANEL_ACCENT, 10, 1, 10))
	right_col.add_child(first_run_brief_panel)
	right_col.move_child(first_run_brief_panel, 1)


func _build_route_banner() -> void:
	route_banner_panel = PanelContainer.new()
	route_banner_panel.custom_minimum_size = Vector2(0, 68)
	route_banner_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	route_banner_panel.clip_contents = true
	route_banner_texture = TextureRect.new()
	route_banner_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	route_banner_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	route_banner_texture.custom_minimum_size = Vector2(0, 68)
	route_banner_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	route_banner_panel.add_child(route_banner_texture)
	route_banner_panel.add_theme_stylebox_override("panel", _make_style(Color(0.04, 0.08, 0.14, 0.88), PANEL_LINE, 8, 1, 4))
	var info_col: VBoxContainer = $Content/Root/Body/RightPanel/RightCol/InfoColumn
	info_col.add_child(route_banner_panel)
	info_col.move_child(route_banner_panel, 0)


func _build_backdrop_decor() -> void:
	decor_root = Control.new()
	decor_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	decor_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(decor_root)
	move_child(decor_root, 1)

	if ResourceLoader.exists("res://assets/art/game_hero_backdrop.jpg"):
		var bg_tex := load("res://assets/art/game_hero_backdrop.jpg") as Texture2D
		if bg_tex != null:
			bg_texture_rect = TextureRect.new()
			bg_texture_rect.texture = bg_tex
			bg_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			bg_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			bg_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			bg_texture_rect.modulate = Color(0.42, 0.55, 0.8, 0.65)
			bg_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			decor_root.add_child(bg_texture_rect)

	for index in 4:
		var stripe := ColorRect.new()
		stripe.color = Color(0.18, 0.72, 1.0, 0.05 if index % 2 == 0 else 0.03)
		stripe.anchor_left = 0.08 + index * 0.2
		stripe.anchor_right = stripe.anchor_left
		stripe.anchor_top = -0.06
		stripe.anchor_bottom = 1.06
		stripe.offset_left = -3.0
		stripe.offset_right = 3.0
		stripe.rotation = deg_to_rad(-18.0 if index % 2 == 0 else 14.0)
		decor_root.add_child(stripe)
		decor_lines.append(stripe)

	decor_corner_glow = ColorRect.new()
	decor_corner_glow.color = Color(1.0, 0.48, 0.26, 0.08)
	decor_corner_glow.anchor_left = 1.0
	decor_corner_glow.anchor_right = 1.0
	decor_corner_glow.anchor_top = 0.0
	decor_corner_glow.anchor_bottom = 0.0
	decor_corner_glow.offset_left = -320.0
	decor_corner_glow.offset_right = -24.0
	decor_corner_glow.offset_top = 24.0
	decor_corner_glow.offset_bottom = 220.0
	decor_root.add_child(decor_corner_glow)

	decor_bottom_bar = ColorRect.new()
	decor_bottom_bar.color = Color(0.24, 0.82, 1.0, 0.06)
	decor_bottom_bar.anchor_left = 0.0
	decor_bottom_bar.anchor_right = 1.0
	decor_bottom_bar.anchor_top = 1.0
	decor_bottom_bar.anchor_bottom = 1.0
	decor_bottom_bar.offset_top = -42.0
	decor_bottom_bar.offset_bottom = 0.0
	decor_root.add_child(decor_bottom_bar)

	decor_signal_panel = PanelContainer.new()
	decor_signal_panel.anchor_left = 1.0
	decor_signal_panel.anchor_right = 1.0
	decor_signal_panel.anchor_top = 0.0
	decor_signal_panel.anchor_bottom = 0.0
	decor_signal_panel.offset_left = -360.0
	decor_signal_panel.offset_right = -28.0
	decor_signal_panel.offset_top = 24.0
	decor_signal_panel.offset_bottom = 68.0
	decor_root.add_child(decor_signal_panel)
	var signal_margin := MarginContainer.new()
	signal_margin.add_theme_constant_override("margin_left", 14)
	signal_margin.add_theme_constant_override("margin_top", 10)
	signal_margin.add_theme_constant_override("margin_right", 14)
	signal_margin.add_theme_constant_override("margin_bottom", 10)
	decor_signal_panel.add_child(signal_margin)
	decor_signal_label = Label.new()
	decor_signal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	decor_signal_label.text = "BLITZ PURSUIT // BREACH READY"
	signal_margin.add_child(decor_signal_label)


func _refresh_first_run_brief() -> void:
	if first_run_brief_panel == null:
		return
	first_run_brief_panel.visible = current_phase == FrontendBridge.PHASE_HUB and not GameState.has_ux_flag("first_run_brief_seen")
	for child in first_run_brief_list.get_children():
		child.queue_free()
	if not first_run_brief_panel.visible:
		return
	var title := Label.new()
	title.text = "FIRST RUN BRIEF"
	title.add_theme_font_size_override("font_size", int(FONT_BODY_SIZE * PlatformProfile.get_mobile_ui_scale()))
	title.add_theme_color_override("font_color", TEXT_GOLD)
	first_run_brief_list.add_child(title)
	for line in GameState.get_first_run_brief_lines():
		var label := Label.new()
		label.text = line
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", int(FONT_BODY_SIZE * PlatformProfile.get_mobile_ui_scale()))
		label.add_theme_color_override("font_color", TEXT_PRIMARY)
		first_run_brief_list.add_child(label)


func _refresh_decor_signal(operation: Dictionary) -> void:
	if decor_signal_label == null:
		return
	if current_phase == FrontendBridge.PHASE_HUB:
		decor_signal_label.text = "%s // %s" % [
			String(operation.get("title", GameState.current_operation_title)).to_upper(),
			String(operation.get("mode_label", "BREACH READY")).to_upper()
		]
	elif current_phase == FrontendBridge.PHASE_RESULTS:
		decor_signal_label.text = "%s // SCORE %04d" % [
			("RUN COMPLETE" if GameState.run_success else "RUN FAILED"),
			GameState.score,
		]
	else:
		decor_signal_label.text = "RUN HOLD // %s" % String(operation.get("title", GameState.current_operation_title)).to_upper()


func _animate_decor(delta: float) -> void:
	var target_backdrop := Color(0.015, 0.025, 0.06, 1.0)
	match current_phase:
		FrontendBridge.PHASE_HUB:
			target_backdrop = Color(0.018, 0.026, 0.055, 1.0)
		FrontendBridge.PHASE_RESULTS:
			target_backdrop = Color(0.03, 0.024, 0.045, 1.0)
		FrontendBridge.PHASE_PAUSE:
			target_backdrop = Color(0.018, 0.02, 0.04, 1.0)
	backdrop.color = backdrop.color.lerp(target_backdrop, delta * 2.2)
	if decor_signal_panel != null:
		decor_signal_panel.modulate.a = 0.74 + sin(ambient_pulse * 1.8) * 0.16
	if decor_corner_glow != null:
		decor_corner_glow.modulate.a = 0.7 + sin(ambient_pulse * 2.1) * 0.18
	if decor_bottom_bar != null:
		decor_bottom_bar.modulate.a = 0.58 + sin(ambient_pulse * 1.3) * 0.18
	for index in decor_lines.size():
		var stripe := decor_lines[index]
		if stripe == null:
			continue
		stripe.modulate.a = 0.55 + sin(ambient_pulse * (1.2 + index * 0.18) + index) * 0.16
		stripe.position.y = sin(ambient_pulse * (0.8 + index * 0.1) + index) * 16.0
	primary_button.pivot_offset = primary_button.size * 0.5
	if current_phase == FrontendBridge.PHASE_HUB:
		primary_button.scale = Vector2.ONE * (1.0 + sin(ambient_pulse * 2.6) * 0.018)
	else:
		primary_button.scale = primary_button.scale.lerp(Vector2.ONE, delta * 8.0)


func _apply_theme() -> void:
	if not is_node_ready():
		return
	var ms := PlatformProfile.get_mobile_ui_scale()
	var safe := PlatformProfile.get_safe_area_margin()
	backdrop.color = Color(0.015, 0.025, 0.06, 1.0)
	content_margin.add_theme_constant_override("margin_left", int((16 if PlatformProfile.is_mobile else 20) * ms + safe.x))
	content_margin.add_theme_constant_override("margin_top", int((8 if PlatformProfile.is_mobile else 10) * ms + safe.y))
	content_margin.add_theme_constant_override("margin_right", int((16 if PlatformProfile.is_mobile else 20) * ms + safe.z))
	content_margin.add_theme_constant_override("margin_bottom", int((8 if PlatformProfile.is_mobile else 10) * ms + safe.w))
	$Content/Root.add_theme_constant_override("separation", 6 if not PlatformProfile.is_mobile else 10)
	$Content/Root/Header.custom_minimum_size = Vector2(0, int(48 * ms))
	$Content/Root/Header.add_theme_stylebox_override("panel", _make_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
	_style_sub_panel($Content/Root/Body/LeftPanel, Color(0.02, 0.04, 0.08, 0.4), Color(0.25, 0.65, 0.95, 0.15))
	_style_sub_panel($Content/Root/Body/RightPanel, Color(0.02, 0.04, 0.08, 0.4), Color(0.25, 0.65, 0.95, 0.15))
	if route_banner_panel != null:
		route_banner_panel.add_theme_stylebox_override("panel", _make_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
	if decor_signal_panel != null:
		decor_signal_panel.offset_left = -360.0 - safe.z
		decor_signal_panel.offset_right = -28.0 - safe.z
		decor_signal_panel.offset_top = 24.0 + safe.y
		decor_signal_panel.offset_bottom = 68.0 + safe.y
		decor_signal_panel.add_theme_stylebox_override("panel", _make_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
	if decor_signal_label != null:
		decor_signal_label.add_theme_font_size_override("font_size", int(12 * ms))
		decor_signal_label.add_theme_color_override("font_color", TEXT_MUTED)
	if first_run_brief_panel != null:
		first_run_brief_panel.add_theme_stylebox_override("panel", _make_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
	$Content/Root/Header/HeaderRow/StatusBadge.add_theme_stylebox_override("panel", _make_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
	title_label.add_theme_font_size_override("font_size", int(26 * ms))
	title_label.add_theme_color_override("font_color", Color(0.5, 0.92, 1.0))
	subtitle_label.add_theme_font_size_override("font_size", int(14 * ms))
	subtitle_label.add_theme_color_override("font_color", Color(0.75, 0.82, 0.94))
	status_label.add_theme_font_size_override("font_size", int(FONT_TITLE_SIZE * ms))
	status_label.add_theme_color_override("font_color", TEXT_GOLD)
	route_title.add_theme_font_size_override("font_size", int(FONT_TITLE_SIZE * ms))
	route_title.add_theme_color_override("font_color", TEXT_PRIMARY)
	focus_mode.add_theme_font_size_override("font_size", int(FONT_CAPTION_SIZE * ms))
	focus_mode.add_theme_color_override("font_color", TEXT_GOLD)
	focus_title.add_theme_font_size_override("font_size", int(20 * ms))
	focus_title.add_theme_color_override("font_color", TEXT_PRIMARY)
	focus_summary.add_theme_font_size_override("font_size", int(13 * ms))
	focus_summary.add_theme_color_override("font_color", TEXT_PRIMARY)
	focus_brief.add_theme_font_size_override("font_size", int(FONT_BODY_SIZE * ms))
	focus_brief.add_theme_color_override("font_color", TEXT_MUTED)
	focus_intel.add_theme_font_size_override("font_size", int(FONT_BODY_SIZE * ms))
	focus_intel.add_theme_color_override("font_color", TEXT_SUCCESS)
	directive_name.add_theme_font_size_override("font_size", int(15 * ms))
	directive_name.add_theme_color_override("font_color", TEXT_PRIMARY)
	directive_summary.add_theme_font_size_override("font_size", int(FONT_BODY_SIZE * ms))
	directive_summary.add_theme_color_override("font_color", TEXT_MUTED)
	footer_hint.add_theme_font_size_override("font_size", int(FONT_BODY_SIZE * ms))
	footer_hint.add_theme_color_override("font_color", TEXT_MUTED)
	body_row.add_theme_constant_override("separation", 10 if PlatformProfile.is_mobile else 14)
	$Content/Root/Body/LeftPanel.custom_minimum_size = Vector2(260 if PlatformProfile.is_mobile else 280, 0)
	$Content/Root/Body/RightPanel/RightCol.add_theme_constant_override("separation", 8 if not PlatformProfile.is_mobile else 6)
	$Content/Root/Body/LeftPanel/LeftCol.add_theme_constant_override("separation", 8 if not PlatformProfile.is_mobile else 6)
	$Content/Root/Body/RightPanel/RightCol/InfoColumn.add_theme_constant_override("separation", 4)
	directive_scroll.custom_minimum_size = Vector2(0, 72 if not PlatformProfile.is_mobile else 140)
	var footer_button_height := _get_pause_control_height() if PlatformProfile.is_mobile else 46.0
	primary_button.custom_minimum_size = Vector2(200, footer_button_height)
	secondary_button.custom_minimum_size = Vector2(140, footer_button_height)
	_style_button(primary_button, Color("173554"), Color("4fdcff"), TEXT_PRIMARY)
	_style_button(secondary_button, Color("2b2238"), Color("ff7b43"), TEXT_PRIMARY)
	_refresh_first_run_brief()


func _style_sub_panel(panel: PanelContainer, fill: Color, border: Color) -> void:
	panel.add_theme_stylebox_override("panel", _make_style(fill, border, 10, 1, 14))


func _style_button(btn: Button, fill: Color, border: Color, tc: Color) -> void:
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal", _make_style(fill, border, 14, 2, 12))
	btn.add_theme_stylebox_override("hover", _make_style(fill.lightened(0.08), border.lightened(0.08), 14, 2, 14))
	btn.add_theme_stylebox_override("pressed", _make_style(fill.darkened(0.12), border, 14, 2, 8))
	btn.add_theme_stylebox_override("disabled", _make_style(fill.darkened(0.2), border.darkened(0.4), 14, 2, 6))
	var font_size := int(17 * PlatformProfile.get_mobile_ui_scale()) if btn == primary_button else int(15 * PlatformProfile.get_mobile_ui_scale())
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", tc)
	btn.add_theme_color_override("font_disabled_color", TEXT_MUTED)


func _make_style(fill: Color, border: Color, radius: int, bw: int = 2, ss: int = 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.border_width_left = bw
	s.border_width_top = bw
	s.border_width_right = bw
	s.border_width_bottom = bw
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	s.shadow_size = ss
	s.shadow_offset = Vector2(0, 8)
	return s


func _get_launch_button_text(operation: Dictionary) -> String:
	var title := String(operation.get("title", "Route"))
	var primary_word := title.split(" ")[0].to_upper() if not title.is_empty() else "RUN"
	match primary_word:
		"BLITZ":
			return "▶ 开始极速突破 (START BLITZ)"
		"GHOST":
			return "▶ 开始幽灵潜行 (START GHOST)"
		"OVERDRIVE":
			return "▶ 开始过载协议 (START OVERDRIVE)"
		_:
			return "▶ 开始行动 (START %s)" % primary_word
