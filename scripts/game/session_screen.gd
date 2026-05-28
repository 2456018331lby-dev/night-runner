extends CanvasLayer

signal operation_chosen(operation_id: String)
signal launch_requested
signal retry_requested
signal resume_requested
signal hub_requested

const FONT_DISPLAY_SIZE := 36
const FONT_TITLE_SIZE := 20
const FONT_BODY_SIZE := 14
const FONT_CAPTION_SIZE := 11
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
@onready var title_label: Label = $Content/Root/Header/HeaderRow/TitleSection/Title
@onready var subtitle_label: Label = $Content/Root/Header/HeaderRow/TitleSection/Subtitle
@onready var status_label: Label = $Content/Root/Header/HeaderRow/StatusBadge/Status
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
@onready var directive_list: VBoxContainer = $Content/Root/Body/RightPanel/RightCol/DirectiveScroll/DirectiveList
@onready var footer_hint: Label = $Content/Root/Footer/Hint
@onready var primary_button: Button = $Content/Root/Footer/ActionRow/Primary
@onready var secondary_button: Button = $Content/Root/Footer/ActionRow/Secondary

var current_phase: String = FrontendBridge.PHASE_HUB
var operation_buttons: Dictionary = {}
var directive_buttons: Dictionary = {}
var ambient_pulse: float = 0.0


func _ready() -> void:
	_apply_theme()
	_wire_actions()
	visible = true


func _process(delta: float) -> void:
	ambient_pulse += delta
	backdrop.material = null


func build_hub(operations: Array[Dictionary], selected_id: String) -> void:
	current_phase = FrontendBridge.PHASE_HUB
	show()
	_clear_route_list()
	title_label.text = "NIGHT RUNNER"
	subtitle_label.text = "STEAL THE CORES · SURVIVE THE CASHOUT"
	status_label.text = "HUB"
	route_title.text = "SELECT ROUTE"
	footer_hint.text = "Pick a route, then launch."
	primary_button.text = "LAUNCH"
	secondary_button.text = ""
	secondary_button.visible = false
	primary_button.disabled = selected_id.is_empty() or not GameState.is_operation_unlocked(selected_id)
	for operation in operations:
		_add_route_button(operation, selected_id)
	_refresh_focus(FrontendBridge.get_operation(selected_id))


func build_results(operation: Dictionary) -> void:
	current_phase = FrontendBridge.PHASE_RESULTS
	show()
	_clear_route_list()
	title_label.text = "RUN COMPLETE" if GameState.run_success else "RUN FAILED"
	subtitle_label.text = "Rank %s · %04d" % [GameState.final_rank, GameState.score]
	status_label.text = "RESULTS"
	route_title.text = "CAREER"
	footer_hint.text = GameState.result_summary
	primary_button.text = "RETRY"
	secondary_button.text = "HUB"
	secondary_button.visible = true
	secondary_button.disabled = false
	primary_button.disabled = false
	_add_debrief_metrics(operation)
	_refresh_focus(operation)


func build_pause(operation: Dictionary) -> void:
	current_phase = FrontendBridge.PHASE_PAUSE
	show()
	_clear_route_list()
	title_label.text = "PAUSED"
	subtitle_label.text = "Score %04d · Cores %d/%d · HP %d" % [GameState.score, GameState.data_cores_collected, GameState.data_cores_total, GameState.health]
	status_label.text = "HOLD"
	route_title.text = "LIVE DATA"
	footer_hint.text = "Resume to continue, or return to hub."
	primary_button.text = "RESUME"
	secondary_button.text = "HUB"
	secondary_button.visible = true
	secondary_button.disabled = false
	primary_button.disabled = false
	_add_pause_metrics()
	_refresh_focus(operation)


func hide_for_run() -> void:
	hide()


func _clear_route_list() -> void:
	operation_buttons.clear()
	for child in route_list.get_children():
		child.queue_free()


func _clear_directive_list() -> void:
	directive_buttons.clear()
	for child in directive_list.get_children():
		child.queue_free()


func _refresh_focus(operation: Dictionary) -> void:
	var selected := operation if not operation.is_empty() else FrontendBridge.get_selected_operation()
	var operation_id := String(selected.get("id", ""))
	var record := GameState.get_operation_record(operation_id)
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
	if current_phase == FrontendBridge.PHASE_HUB:
		var selected_directive := FrontendBridge.get_selected_directive(operation_id)
		directive_name.text = String(selected_directive.get("name", "Base Protocol"))
		directive_summary.text = String(selected_directive.get("summary", ""))
		var modifier_summary := GameState.describe_modifier_block(Dictionary(selected_directive.get("modifiers", {})))
		if not modifier_summary.is_empty():
			directive_summary.text += "\n" + modifier_summary
		_populate_directive_list(selected)
	else:
		directive_name.text = GameState.get_current_directive_name()
		directive_summary.text = GameState.get_current_directive_summary()
		_clear_directive_list()
		if current_phase == FrontendBridge.PHASE_RESULTS:
			_add_directive_note(GameState.get_run_verdict_text(), TEXT_TEAL)
			for line in GameState.get_run_score_breakdown_lines():
				_add_directive_note(line, TEXT_PRIMARY)
		elif current_phase == FrontendBridge.PHASE_PAUSE:
			_add_directive_note("Optional: %s" % GameState.get_secondary_objective_status_text(), TEXT_PRIMARY)
	_update_palette(selected)


func _populate_directive_list(operation: Dictionary) -> void:
	_clear_directive_list()
	var operation_id := String(operation.get("id", ""))
	var selected_directive := FrontendBridge.get_selected_directive(operation_id)
	for directive in operation.get("directive_pool", []):
		_add_directive_button(operation, directive, String(directive.get("id", "")) == String(selected_directive.get("id", "")))


func _add_route_button(operation: Dictionary, selected_id: String) -> void:
	var btn := Button.new()
	var operation_id := String(operation.get("id", ""))
	var unlocked := GameState.is_operation_unlocked(operation_id)
	btn.text = "%s  %s" % [("READY" if unlocked else "LOCKED"), String(operation.get("title", ""))]
	btn.custom_minimum_size = Vector2(0, 64)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.focus_mode = Control.FOCUS_NONE
	btn.disabled = not unlocked
	btn.button_pressed = operation_id == selected_id
	btn.pressed.connect(func(): _select_route(operation_id))
	var fill := Color(0.04, 0.08, 0.14, 0.9) if btn.button_pressed else Color(0.03, 0.06, 0.11, 0.7)
	var line: Color = (Color("4fdcff") if btn.button_pressed else Color(0.2, 0.5, 0.7, 0.3))
	btn.add_theme_stylebox_override("normal", _make_style(fill, line, 8, 2 if btn.button_pressed else 1))
	btn.add_theme_stylebox_override("hover", _make_style(fill.lightened(0.06), line.lightened(0.1), 8, 2))
	btn.add_theme_stylebox_override("pressed", _make_style(fill.darkened(0.08), line, 8, 2))
	btn.add_theme_color_override("font_color", TEXT_PRIMARY)
	btn.add_theme_color_override("font_disabled_color", TEXT_MUTED)
	btn.add_theme_font_size_override("font_size", 16)
	route_list.add_child(btn)
	operation_buttons[operation_id] = btn


func _add_directive_button(operation: Dictionary, directive: Dictionary, selected: bool) -> void:
	var btn := Button.new()
	var modifier_summary := GameState.describe_modifier_block(Dictionary(directive.get("modifiers", {})))
	btn.text = "%s  %s" % [("ACTIVE" if selected else "OPTION"), String(directive.get("name", ""))]
	if not PlatformProfile.is_mobile:
		btn.text += "\n%s" % String(directive.get("summary", ""))
	btn.text += "\n%s" % modifier_summary
	btn.custom_minimum_size = Vector2(0, 72)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.focus_mode = Control.FOCUS_NONE
	btn.button_pressed = selected
	var operation_id := String(operation.get("id", ""))
	var directive_id := String(directive.get("id", ""))
	btn.pressed.connect(func(): _select_directive(operation_id, directive_id))
	var fill := Color(0.05, 0.06, 0.13, 0.9) if selected else Color(0.04, 0.06, 0.11, 0.7)
	var line: Color = (PANEL_ACCENT if selected else Color(0.3, 0.45, 0.6, 0.3))
	btn.add_theme_stylebox_override("normal", _make_style(fill, line, 8, 2 if selected else 1))
	btn.add_theme_stylebox_override("hover", _make_style(fill.lightened(0.06), line.lightened(0.1), 8, 2))
	btn.add_theme_stylebox_override("pressed", _make_style(fill.darkened(0.08), line, 8, 2))
	btn.add_theme_color_override("font_color", TEXT_PRIMARY)
	btn.add_theme_color_override("font_disabled_color", TEXT_MUTED)
	btn.add_theme_font_size_override("font_size", 14)
	directive_list.add_child(btn)
	directive_buttons[directive_id] = btn


func _select_route(operation_id: String) -> void:
	FrontendBridge.select_operation(operation_id)
	for key in operation_buttons.keys():
		var btn: Button = operation_buttons[key]
		btn.button_pressed = key == operation_id
	primary_button.disabled = not GameState.is_operation_unlocked(operation_id)
	_refresh_focus(FrontendBridge.get_operation(operation_id))
	operation_chosen.emit(operation_id)


func _select_directive(operation_id: String, directive_id: String) -> void:
	FrontendBridge.select_directive(operation_id, directive_id)
	var operation := FrontendBridge.get_operation(operation_id)
	for key in directive_buttons.keys():
		var btn: Button = directive_buttons[key]
		var sel := String(key) == directive_id
		btn.button_pressed = sel
	directive_name.text = String(FrontendBridge.get_selected_directive(operation_id).get("name", ""))
	directive_summary.text = String(FrontendBridge.get_selected_directive(operation_id).get("summary", ""))


func _add_debrief_metrics(operation: Dictionary) -> void:
	var record := GameState.get_operation_record(String(operation.get("id", "")))
	var metrics := GameState.get_run_metrics()
	_add_route_note("Rank %s · %04d" % [GameState.final_rank, GameState.score], TEXT_GOLD)
	_add_route_note("Career best %04d" % int(GameState.meta_progress.get("highest_score", 0)), TEXT_MUTED)
	_add_route_note("Combat +%d · Cores +%d" % [int(metrics.get("combat_score", 0)), int(metrics.get("core_score", 0))], TEXT_TEAL)
	_add_route_note("Exit +%d · Cashout +%d" % [int(metrics.get("exit_bonus", 0)), int(metrics.get("cashout_bonus", 0))], TEXT_PRIMARY)


func _add_pause_metrics() -> void:
	_add_route_note("Time %s" % GameState.formatted_time(), TEXT_PRIMARY)
	_add_route_note("Combo %d · HP %d" % [GameState.combo_count, GameState.health], TEXT_MUTED)


func _add_route_note(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	route_list.add_child(label)


func _add_directive_note(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	directive_list.add_child(label)


func _add_stat_pair(caption: String, value: String) -> void:
	var l1 := Label.new()
	l1.text = caption
	l1.add_theme_font_size_override("font_size", 11)
	l1.add_theme_color_override("font_color", TEXT_MUTED)
	record_grid.add_child(l1)
	var l2 := Label.new()
	l2.text = value
	l2.add_theme_font_size_override("font_size", 14)
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


func _apply_theme() -> void:
	var ms := PlatformProfile.get_mobile_ui_scale()
	backdrop.color = Color(0.015, 0.025, 0.06, 1.0)
	$Content.add_theme_constant_override("margin_left", int(20 * ms))
	$Content.add_theme_constant_override("margin_top", int(16 * ms))
	$Content.add_theme_constant_override("margin_right", int(20 * ms))
	$Content.add_theme_constant_override("margin_bottom", int(16 * ms))
	$Content/Root/Header.add_theme_stylebox_override("panel", _make_style(Color("09121f"), PANEL_LINE, 12, 2, 18))
	_style_sub_panel($Content/Root/Body/LeftPanel, Color("0a1628"), PANEL_LINE)
	_style_sub_panel($Content/Root/Body/RightPanel, Color("0a1628"), PANEL_ACCENT)
	$Content/Root/Header/HeaderRow/StatusBadge.add_theme_stylebox_override("panel", _make_style(Color("0d1a2c"), PANEL_ACCENT, 8, 1, 8))
	title_label.add_theme_font_size_override("font_size", int(FONT_DISPLAY_SIZE * ms))
	title_label.add_theme_color_override("font_color", TEXT_PRIMARY)
	subtitle_label.add_theme_font_size_override("font_size", int(FONT_BODY_SIZE * ms))
	subtitle_label.add_theme_color_override("font_color", TEXT_MUTED)
	status_label.add_theme_font_size_override("font_size", int(FONT_TITLE_SIZE * ms))
	status_label.add_theme_color_override("font_color", TEXT_GOLD)
	route_title.add_theme_font_size_override("font_size", int(FONT_TITLE_SIZE * ms))
	route_title.add_theme_color_override("font_color", TEXT_PRIMARY)
	focus_mode.add_theme_font_size_override("font_size", int(FONT_CAPTION_SIZE * ms))
	focus_mode.add_theme_color_override("font_color", TEXT_GOLD)
	focus_title.add_theme_font_size_override("font_size", int(26 * ms))
	focus_title.add_theme_color_override("font_color", TEXT_PRIMARY)
	focus_summary.add_theme_font_size_override("font_size", int(15 * ms))
	focus_summary.add_theme_color_override("font_color", TEXT_PRIMARY)
	focus_brief.add_theme_font_size_override("font_size", int(FONT_BODY_SIZE * ms))
	focus_brief.add_theme_color_override("font_color", TEXT_MUTED)
	focus_intel.add_theme_font_size_override("font_size", int(FONT_BODY_SIZE * ms))
	focus_intel.add_theme_color_override("font_color", TEXT_SUCCESS)
	directive_name.add_theme_font_size_override("font_size", int(17 * ms))
	directive_name.add_theme_color_override("font_color", TEXT_PRIMARY)
	directive_summary.add_theme_font_size_override("font_size", int(FONT_BODY_SIZE * ms))
	directive_summary.add_theme_color_override("font_color", TEXT_MUTED)
	footer_hint.add_theme_font_size_override("font_size", int(FONT_BODY_SIZE * ms))
	footer_hint.add_theme_color_override("font_color", TEXT_MUTED)
	_style_button(primary_button, Color("173554"), Color("4fdcff"), TEXT_PRIMARY)
	_style_button(secondary_button, Color("2b2238"), Color("ff7b43"), TEXT_PRIMARY)


func _style_sub_panel(panel: PanelContainer, fill: Color, border: Color) -> void:
	panel.add_theme_stylebox_override("panel", _make_style(fill, border, 10, 1, 14))


func _style_button(btn: Button, fill: Color, border: Color, tc: Color) -> void:
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal", _make_style(fill, border, 14, 2, 12))
	btn.add_theme_stylebox_override("hover", _make_style(fill.lightened(0.08), border.lightened(0.08), 14, 2, 14))
	btn.add_theme_stylebox_override("pressed", _make_style(fill.darkened(0.12), border, 14, 2, 8))
	btn.add_theme_stylebox_override("disabled", _make_style(fill.darkened(0.2), border.darkened(0.4), 14, 2, 6))
	btn.add_theme_font_size_override("font_size", int(15 * PlatformProfile.get_mobile_ui_scale()))
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
