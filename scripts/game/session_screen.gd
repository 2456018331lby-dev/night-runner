extends CanvasLayer

signal operation_chosen(operation_id: String)
signal launch_requested
signal retry_requested
signal resume_requested
signal hub_requested

const FONT_DISPLAY_SIZE := 34
const FONT_TITLE_SIZE := 22
const FONT_BODY_SIZE := 15
const FONT_CAPTION_SIZE := 12
const PANEL_BG := Color("09121f")
const PANEL_BG_SOFT := Color(0.05, 0.09, 0.16, 0.76)
const PANEL_LINE := Color("4fdcff")
const PANEL_ACCENT := Color("ff7b43")
const TEXT_PRIMARY := Color("f7fbff")
const TEXT_MUTED := Color("9bb0c9")
const TEXT_GOLD := Color("ffd37c")
const TEXT_ALERT := Color("ff9289")
const TEXT_SUCCESS := Color("98ffd2")

@onready var backdrop: ColorRect = $Backdrop
@onready var ambient_a: ColorRect = $Backdrop/AmbientA
@onready var ambient_b: ColorRect = $Backdrop/AmbientB
@onready var grain: ColorRect = $Backdrop/Grain
@onready var frame: PanelContainer = $Margin/Layout/Frame
@onready var title_label: Label = $Margin/Layout/Frame/Margin/Column/HeaderRow/HeaderBox/HeaderMargin/TitleFlow/Title
@onready var subtitle_label: Label = $Margin/Layout/Frame/Margin/Column/HeaderRow/HeaderBox/HeaderMargin/TitleFlow/Subtitle
@onready var status_label: Label = $Margin/Layout/Frame/Margin/Column/HeaderRow/StatusBox/StatusMargin/Status
@onready var deck_title: Label = $Margin/Layout/Frame/Margin/Column/BodyRow/Deck/DeckMargin/DeckColumn/DeckTitle
@onready var deck_subtitle: Label = $Margin/Layout/Frame/Margin/Column/BodyRow/Deck/DeckMargin/DeckColumn/DeckSubtitle
@onready var deck_flow: VBoxContainer = $Margin/Layout/Frame/Margin/Column/BodyRow/Deck/DeckMargin/DeckColumn/DeckScroll/DeckFlow
@onready var focus_mode: Label = $Margin/Layout/Frame/Margin/Column/BodyRow/FocusPanel/FocusMargin/FocusColumn/Mode
@onready var focus_title: Label = $Margin/Layout/Frame/Margin/Column/BodyRow/FocusPanel/FocusMargin/FocusColumn/Title
@onready var focus_summary: Label = $Margin/Layout/Frame/Margin/Column/BodyRow/FocusPanel/FocusMargin/FocusColumn/Summary
@onready var focus_brief: Label = $Margin/Layout/Frame/Margin/Column/BodyRow/FocusPanel/FocusMargin/FocusColumn/Brief
@onready var focus_intel: Label = $Margin/Layout/Frame/Margin/Column/BodyRow/FocusPanel/FocusMargin/FocusColumn/Intel
@onready var record_title: Label = $Margin/Layout/Frame/Margin/Column/BodyRow/FocusPanel/FocusMargin/FocusColumn/RecordsTitle
@onready var record_grid: GridContainer = $Margin/Layout/Frame/Margin/Column/BodyRow/FocusPanel/FocusMargin/FocusColumn/RecordGrid
@onready var directive_title: Label = $Margin/Layout/Frame/Margin/Column/BodyRow/FocusPanel/FocusMargin/FocusColumn/DirectiveTitle
@onready var directive_name: Label = $Margin/Layout/Frame/Margin/Column/BodyRow/FocusPanel/FocusMargin/FocusColumn/DirectiveName
@onready var directive_summary: Label = $Margin/Layout/Frame/Margin/Column/BodyRow/FocusPanel/FocusMargin/FocusColumn/DirectiveSummary
@onready var footer_hint: Label = $Margin/Layout/Frame/Margin/Column/FooterRow/FooterHint
@onready var primary_button: Button = $Margin/Layout/Frame/Margin/Column/FooterRow/ActionRow/Primary
@onready var secondary_button: Button = $Margin/Layout/Frame/Margin/Column/FooterRow/ActionRow/Secondary
@onready var tertiary_button: Button = $Margin/Layout/Frame/Margin/Column/FooterRow/ActionRow/Tertiary

var current_phase: String = FrontendBridge.PHASE_HUB
var operation_buttons: Dictionary = {}


func _ready() -> void:
	_apply_theme()
	_wire_actions()
	visible = true


func build_hub(operations: Array[Dictionary], selected_id: String) -> void:
	current_phase = FrontendBridge.PHASE_HUB
	show()
	_clear_operation_buttons()
	title_label.text = "NIGHT RUNNER"
	subtitle_label.text = "Neon break-in operations // urban assault archive"
	status_label.text = "OPERATIONS DECK"
	deck_title.text = "AVAILABLE RUNS"
	deck_subtitle.text = "Three combat fantasies in one career ladder: chase, infiltration and adaptive overdrive."
	footer_hint.text = "Select an operation. The system remembers your best score, rank and survival rate."
	primary_button.text = "LAUNCH OPERATION"
	secondary_button.text = "VIEW RESULTS"
	tertiary_button.text = "PAUSE LOCKED"
	secondary_button.visible = false
	tertiary_button.visible = false
	primary_button.disabled = selected_id.is_empty() or not GameState.is_operation_unlocked(selected_id)
	for operation in operations:
		_add_operation_button(operation, selected_id)
	_refresh_focus(FrontendBridge.get_operation(selected_id))


func build_results(operation: Dictionary) -> void:
	current_phase = FrontendBridge.PHASE_RESULTS
	show()
	title_label.text = "RUN DEBRIEF"
	subtitle_label.text = "Asset recovery status, performance grade and escalation context."
	status_label.text = "RESULTS // %s" % ("SUCCESS" if GameState.run_success else "FAILED")
	deck_title.text = "CAREER STATS"
	deck_subtitle.text = "Best score %04d // success rate %s // career runs %d" % [
		int(GameState.meta_progress.get("highest_score", 0)),
		GameState.formatted_success_rate(),
		int(GameState.meta_progress.get("career_runs", 0)),
	]
	footer_hint.text = GameState.result_summary
	primary_button.text = "RUN IT AGAIN"
	secondary_button.text = "RETURN TO HUB"
	tertiary_button.text = "LOCK DEBRIEF"
	primary_button.disabled = false
	secondary_button.visible = true
	secondary_button.disabled = false
	tertiary_button.visible = false
	_clear_operation_buttons()
	_add_debrief_metrics(operation)
	_refresh_focus(operation)


func build_pause(operation: Dictionary) -> void:
	current_phase = FrontendBridge.PHASE_PAUSE
	show()
	title_label.text = "TACTICAL HOLD"
	subtitle_label.text = "Run frozen. Re-center, review the route and push back into the sector."
	status_label.text = "PAUSED"
	deck_title.text = "LIVE TELEMETRY"
	deck_subtitle.text = "Score %04d // cores %d/%d // health %d" % [
		GameState.score,
		GameState.data_cores_collected,
		GameState.data_cores_total,
		GameState.health,
	]
	footer_hint.text = "Resume to continue the run, or break contact and return to the hub."
	primary_button.text = "RESUME RUN"
	secondary_button.text = "RETURN TO HUB"
	tertiary_button.text = "HOLD"
	primary_button.disabled = false
	secondary_button.visible = true
	secondary_button.disabled = false
	tertiary_button.visible = false
	_clear_operation_buttons()
	_add_pause_metrics()
	_refresh_focus(operation)


func hide_for_run() -> void:
	hide()


func _refresh_focus(operation: Dictionary) -> void:
	var selected := operation if not operation.is_empty() else FrontendBridge.get_selected_operation()
	var operation_id := String(selected.get("id", ""))
	var record := GameState.get_operation_record(operation_id)
	focus_mode.text = String(selected.get("mode_label", "UNSPECIFIED ROUTE"))
	focus_title.text = String(selected.get("title", "No Operation Selected"))
	focus_summary.text = String(selected.get("summary", "Select an operation to inspect its risk profile."))
	focus_brief.text = String(selected.get("brief", ""))
	focus_intel.text = String(selected.get("intel", ""))
	record_title.text = "FIELD RECORDS"
	_populate_record_grid(record)
	if GameState.get_current_directive_name().is_empty() and current_phase == FrontendBridge.PHASE_HUB:
		directive_title.text = "DIRECTIVE DRAW"
		directive_name.text = "Adaptive directives roll once the operation starts."
		directive_summary.text = "Later routes layer rogue-like twists on top of the base mission rules."
	else:
		directive_title.text = "ACTIVE DIRECTIVE"
		directive_name.text = GameState.get_current_directive_name()
		directive_summary.text = GameState.get_current_directive_summary()
	_update_focus_palette(selected)


func _populate_record_grid(record: Dictionary) -> void:
	for child in record_grid.get_children():
		child.queue_free()
	_add_stat_pair("Best Score", "%04d" % int(record.get("best_score", 0)))
	_add_stat_pair("Best Rank", String(record.get("best_rank", "--")))
	_add_stat_pair("Runs", str(int(record.get("runs", 0))))
	_add_stat_pair("Successes", str(int(record.get("successes", 0))))
	var best_time := float(record.get("best_time", 0.0))
	_add_stat_pair("Best Time", "--" if best_time <= 0.0 else _format_time(best_time))
	_add_stat_pair("Last Directive", String(record.get("last_directive_name", "None")))


func _add_operation_button(operation: Dictionary, selected_id: String) -> void:
	var button := Button.new()
	button.toggle_mode = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text = "%s\n%s" % [String(operation.get("title", "")), String(operation.get("subtitle", ""))]
	button.custom_minimum_size = Vector2(0, 86)
	button.focus_mode = Control.FOCUS_NONE
	var operation_id := String(operation.get("id", ""))
	var unlocked := GameState.is_operation_unlocked(operation_id)
	button.disabled = not unlocked
	button.button_pressed = operation_id == selected_id
	button.pressed.connect(func() -> void:
		_select_button(operation_id)
	)
	button.mouse_entered.connect(func() -> void:
		_refresh_focus(operation)
	)
	var styles := _make_button_styles(operation, button.button_pressed)
	button.add_theme_stylebox_override("normal", styles["normal"])
	button.add_theme_stylebox_override("hover", styles["hover"])
	button.add_theme_stylebox_override("pressed", styles["pressed"])
	button.add_theme_stylebox_override("disabled", styles["disabled"])
	button.add_theme_color_override("font_color", TEXT_PRIMARY)
	button.add_theme_color_override("font_disabled_color", TEXT_MUTED)
	button.add_theme_font_size_override("font_size", 16)
	deck_flow.add_child(button)
	operation_buttons[operation_id] = button


func _select_button(operation_id: String) -> void:
	FrontendBridge.select_operation(operation_id)
	for key in operation_buttons.keys():
		var button: Button = operation_buttons[key]
		button.button_pressed = key == operation_id
		var operation := FrontendBridge.get_operation(String(key))
		var styles := _make_button_styles(operation, button.button_pressed)
		button.add_theme_stylebox_override("normal", styles["normal"])
		button.add_theme_stylebox_override("hover", styles["hover"])
		button.add_theme_stylebox_override("pressed", styles["pressed"])
	primary_button.disabled = not GameState.is_operation_unlocked(operation_id)
	_refresh_focus(FrontendBridge.get_operation(operation_id))
	operation_chosen.emit(operation_id)


func _add_debrief_metrics(operation: Dictionary) -> void:
	_clear_operation_buttons()
	var record := GameState.get_operation_record(String(operation.get("id", "")))
	_add_panel_note("Rank %s // Score %04d" % [GameState.final_rank, GameState.score], TEXT_GOLD)
	_add_panel_note("Operation best %04d // Career best %04d" % [int(record.get("best_score", 0)), int(GameState.meta_progress.get("highest_score", 0))], TEXT_MUTED)
	_add_panel_note("Directive %s" % (GameState.get_current_directive_name() if not GameState.get_current_directive_name().is_empty() else "None"), TEXT_PRIMARY)


func _add_pause_metrics() -> void:
	_clear_operation_buttons()
	_add_panel_note("Elapsed %s" % GameState.formatted_time(), TEXT_PRIMARY)
	_add_panel_note("Combo %d // Health %d" % [GameState.combo_count, GameState.health], TEXT_MUTED)
	_add_panel_note("Objective remains active. No score is lost while paused.", TEXT_MUTED)


func _add_panel_note(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	deck_flow.add_child(label)


func _clear_operation_buttons() -> void:
	operation_buttons.clear()
	for child in deck_flow.get_children():
		child.queue_free()


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
	backdrop.color = Color(0.02, 0.03, 0.06, 0.94)
	ambient_a.color = Color(0.15, 0.5, 0.78, 0.16)
	ambient_b.color = Color(0.78, 0.39, 0.2, 0.14)
	grain.color = Color(1.0, 1.0, 1.0, 0.02)
	frame.add_theme_stylebox_override("panel", _make_panel_style(PANEL_BG, PANEL_LINE, 30, 2, 24))
	_style_panel($Margin/Layout/Frame/Margin/Column/HeaderRow/HeaderBox, PANEL_BG_SOFT, PANEL_LINE)
	_style_panel($Margin/Layout/Frame/Margin/Column/HeaderRow/StatusBox, PANEL_BG_SOFT, PANEL_ACCENT)
	_style_panel($Margin/Layout/Frame/Margin/Column/BodyRow/Deck, PANEL_BG_SOFT, PANEL_LINE)
	_style_panel($Margin/Layout/Frame/Margin/Column/BodyRow/FocusPanel, PANEL_BG_SOFT, PANEL_ACCENT)
	title_label.add_theme_font_size_override("font_size", FONT_DISPLAY_SIZE)
	title_label.add_theme_color_override("font_color", TEXT_PRIMARY)
	subtitle_label.add_theme_font_size_override("font_size", FONT_BODY_SIZE)
	subtitle_label.add_theme_color_override("font_color", TEXT_MUTED)
	status_label.add_theme_font_size_override("font_size", FONT_TITLE_SIZE)
	status_label.add_theme_color_override("font_color", TEXT_GOLD)
	deck_title.add_theme_font_size_override("font_size", FONT_TITLE_SIZE)
	deck_title.add_theme_color_override("font_color", TEXT_PRIMARY)
	deck_subtitle.add_theme_font_size_override("font_size", FONT_BODY_SIZE)
	deck_subtitle.add_theme_color_override("font_color", TEXT_MUTED)
	focus_mode.add_theme_font_size_override("font_size", FONT_CAPTION_SIZE)
	focus_mode.add_theme_color_override("font_color", TEXT_GOLD)
	focus_title.add_theme_font_size_override("font_size", 28)
	focus_title.add_theme_color_override("font_color", TEXT_PRIMARY)
	focus_summary.add_theme_font_size_override("font_size", 16)
	focus_summary.add_theme_color_override("font_color", TEXT_PRIMARY)
	focus_brief.add_theme_font_size_override("font_size", FONT_BODY_SIZE)
	focus_brief.add_theme_color_override("font_color", TEXT_MUTED)
	focus_intel.add_theme_font_size_override("font_size", FONT_BODY_SIZE)
	focus_intel.add_theme_color_override("font_color", TEXT_SUCCESS)
	record_title.add_theme_font_size_override("font_size", FONT_CAPTION_SIZE)
	record_title.add_theme_color_override("font_color", TEXT_GOLD)
	directive_title.add_theme_font_size_override("font_size", FONT_CAPTION_SIZE)
	directive_title.add_theme_color_override("font_color", TEXT_GOLD)
	directive_name.add_theme_font_size_override("font_size", 18)
	directive_name.add_theme_color_override("font_color", TEXT_PRIMARY)
	directive_summary.add_theme_font_size_override("font_size", FONT_BODY_SIZE)
	directive_summary.add_theme_color_override("font_color", TEXT_MUTED)
	footer_hint.add_theme_font_size_override("font_size", FONT_BODY_SIZE)
	footer_hint.add_theme_color_override("font_color", TEXT_MUTED)
	_style_action_button(primary_button, Color("173554"), Color("4fdcff"), TEXT_PRIMARY)
	_style_action_button(secondary_button, Color("2b2238"), Color("ff7b43"), TEXT_PRIMARY)
	_style_action_button(tertiary_button, Color("111924"), Color("2a3b53"), TEXT_MUTED)


func _style_panel(panel: PanelContainer, fill: Color, border: Color) -> void:
	panel.add_theme_stylebox_override("panel", _make_panel_style(fill, border, 22, 1, 18))


func _style_action_button(button: Button, fill: Color, border: Color, text_color: Color) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", _make_panel_style(fill, border, 18, 2, 14))
	button.add_theme_stylebox_override("hover", _make_panel_style(fill.lightened(0.08), border.lightened(0.08), 18, 2, 16))
	button.add_theme_stylebox_override("pressed", _make_panel_style(fill.darkened(0.12), border, 18, 2, 10))
	button.add_theme_stylebox_override("disabled", _make_panel_style(fill.darkened(0.2), border.darkened(0.4), 18, 2, 8))
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_disabled_color", TEXT_MUTED)


func _make_button_styles(operation: Dictionary, selected: bool) -> Dictionary:
	var theme: Dictionary = operation.get("theme", {})
	var primary: Color = theme.get("primary", PANEL_LINE)
	var secondary: Color = theme.get("secondary", PANEL_ACCENT)
	var fill := Color(0.05, 0.09, 0.15, 0.88)
	var line := primary if selected else Color(primary.r, primary.g, primary.b, 0.36)
	return {
		"normal": _make_panel_style(fill, line, 18, 2 if selected else 1, 14),
		"hover": _make_panel_style(fill.lightened(0.05), primary, 18, 2, 16),
		"pressed": _make_panel_style(fill.darkened(0.12), secondary, 18, 2, 10),
		"disabled": _make_panel_style(fill.darkened(0.15), Color(0.22, 0.28, 0.36, 0.5), 18, 1, 8),
	}


func _add_stat_pair(caption: String, value: String) -> void:
	var label_caption := Label.new()
	label_caption.text = caption
	label_caption.add_theme_font_size_override("font_size", FONT_CAPTION_SIZE)
	label_caption.add_theme_color_override("font_color", TEXT_MUTED)
	record_grid.add_child(label_caption)
	var label_value := Label.new()
	label_value.text = value
	label_value.add_theme_font_size_override("font_size", 15)
	label_value.add_theme_color_override("font_color", TEXT_PRIMARY)
	record_grid.add_child(label_value)


func _update_focus_palette(operation: Dictionary) -> void:
	var theme: Dictionary = operation.get("theme", {})
	var primary: Color = theme.get("primary", PANEL_LINE)
	var secondary: Color = theme.get("secondary", PANEL_ACCENT)
	status_label.add_theme_color_override("font_color", secondary)
	focus_mode.add_theme_color_override("font_color", secondary)
	title_label.add_theme_color_override("font_color", primary.lightened(0.2))
	ambient_a.color = Color(primary.r, primary.g, primary.b, 0.14)
	ambient_b.color = Color(secondary.r, secondary.g, secondary.b, 0.12)


func _make_panel_style(fill: Color, border: Color, radius: int, border_width: int, shadow_size: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(0, 10)
	return style


func _format_time(time_value: float) -> String:
	var total_seconds := int(time_value)
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]
