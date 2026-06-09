extends CanvasLayer

const PANEL_BG := Color(0.04, 0.07, 0.13, 0.82)
const PANEL_SOFT := Color(0.07, 0.11, 0.19, 0.7)
const PANEL_BORDER := Color(0.26, 0.79, 1.0, 0.48)
const PANEL_ACCENT := Color(1.0, 0.56, 0.24, 0.86)
const PANEL_GLOW := Color(0.2, 0.86, 1.0, 0.22)
const TEXT_PRIMARY := Color(0.97, 0.98, 1.0)
const TEXT_MUTED := Color(0.64, 0.77, 0.94)
const TEXT_ACCENT := Color(1.0, 0.84, 0.42)
const TEXT_SUCCESS := Color(0.76, 1.0, 0.88)
const TEXT_ALERT := Color(1.0, 0.74, 0.72)
const TEXT_SOFT := Color(0.88, 0.93, 1.0)
const HEALTH_ON := Color(1.0, 0.46, 0.36, 1.0)
const HEALTH_OFF := Color(0.13, 0.2, 0.31, 1.0)
const HEALTH_BASE_MAX := 3
const HEALTH_PIP_SIZE := Vector2(28, 14)
const PANEL_HIGHLIGHT := Color(0.96, 0.55, 0.26, 0.22)
const COMBO_BAR_FILL := Color(1.0, 0.72, 0.22, 0.9)
const COMBO_BAR_BG := Color(0.1, 0.15, 0.25, 0.7)
const DASH_BAR_FILL := Color(0.28, 0.78, 1.0, 0.9)
const DASH_BAR_BG := Color(0.08, 0.14, 0.24, 0.7)

@onready var score_card: PanelContainer = $MarginContainer/RootColumn/TopRow/ScoreCard
@onready var operation_card: PanelContainer = $MarginContainer/RootColumn/TopRow/OperationCard
@onready var telemetry_card: PanelContainer = $MarginContainer/RootColumn/TopRow/TelemetryCard
@onready var objective_card: PanelContainer = $MarginContainer/RootColumn/ObjectiveRow/ObjectiveCard
@onready var directive_card: PanelContainer = $MarginContainer/RootColumn/DirectiveRow/DirectiveCard
@onready var secondary_card: PanelContainer = $MarginContainer/RootColumn/DirectiveRow/SecondaryCard
@onready var cashout_card: PanelContainer = $MarginContainer/RootColumn/CashoutRow/CashoutCard
@onready var title_label: Label = $MarginContainer/RootColumn/TopRow/OperationCard/Margin/VBox/TitleLabel
@onready var subtitle_label: Label = $MarginContainer/RootColumn/TopRow/OperationCard/Margin/VBox/SubtitleLabel
@onready var score_caption: Label = $MarginContainer/RootColumn/TopRow/ScoreCard/Margin/VBox/ScoreCaption
@onready var score_label: Label = $MarginContainer/RootColumn/TopRow/ScoreCard/Margin/VBox/ScoreLabel
@onready var best_label: Label = $MarginContainer/RootColumn/TopRow/ScoreCard/Margin/VBox/BestLabel
@onready var combo_label: Label = $MarginContainer/RootColumn/TopRow/ScoreCard/Margin/VBox/ComboLabel
@onready var objective_title: Label = $MarginContainer/RootColumn/ObjectiveRow/ObjectiveCard/Margin/VBox/ObjectiveTitle
@onready var objective_label: Label = $MarginContainer/RootColumn/ObjectiveRow/ObjectiveCard/Margin/VBox/ObjectiveLabel
@onready var health_caption: Label = $MarginContainer/RootColumn/TopRow/TelemetryCard/Margin/VBox/HealthRow/HealthCaption
@onready var core_caption: Label = $MarginContainer/RootColumn/TopRow/TelemetryCard/Margin/VBox/CoreCaption
@onready var core_label: Label = $MarginContainer/RootColumn/TopRow/TelemetryCard/Margin/VBox/CoreLabel
@onready var time_caption: Label = $MarginContainer/RootColumn/TopRow/TelemetryCard/Margin/VBox/TimeCaption
@onready var time_label: Label = $MarginContainer/RootColumn/TopRow/TelemetryCard/Margin/VBox/TimeLabel
@onready var rank_label: Label = $MarginContainer/RootColumn/TopRow/TelemetryCard/Margin/VBox/RankLabel
@onready var phase_card: PanelContainer = $MarginContainer/RootColumn/ObjectiveRow/PhaseCard
@onready var phase_title: Label = $MarginContainer/RootColumn/ObjectiveRow/PhaseCard/Margin/VBox/PhaseTitle
@onready var phase_name: Label = $MarginContainer/RootColumn/ObjectiveRow/PhaseCard/Margin/VBox/PhaseName
@onready var phase_status: Label = $MarginContainer/RootColumn/ObjectiveRow/PhaseCard/Margin/VBox/PhaseStatus
@onready var directive_title: Label = $MarginContainer/RootColumn/DirectiveRow/DirectiveCard/Margin/VBox/DirectiveTitle
@onready var directive_name: Label = $MarginContainer/RootColumn/DirectiveRow/DirectiveCard/Margin/VBox/DirectiveName
@onready var directive_summary: Label = $MarginContainer/RootColumn/DirectiveRow/DirectiveCard/Margin/VBox/DirectiveSummary
@onready var secondary_title: Label = $MarginContainer/RootColumn/DirectiveRow/SecondaryCard/Margin/VBox/SecondaryTitle
@onready var secondary_name: Label = $MarginContainer/RootColumn/DirectiveRow/SecondaryCard/Margin/VBox/SecondaryName
@onready var secondary_status: Label = $MarginContainer/RootColumn/DirectiveRow/SecondaryCard/Margin/VBox/SecondaryStatus
@onready var cashout_title: Label = $MarginContainer/RootColumn/CashoutRow/CashoutCard/Margin/VBox/CashoutTitle
@onready var cashout_status: Label = $MarginContainer/RootColumn/CashoutRow/CashoutCard/Margin/VBox/CashoutStatus
@onready var nav_card: PanelContainer = $MarginContainer/RootColumn/CashoutRow/NavCard
@onready var nav_title: Label = $MarginContainer/RootColumn/CashoutRow/NavCard/Margin/VBox/NavTitle
@onready var nav_status: Label = $MarginContainer/RootColumn/CashoutRow/NavCard/Margin/VBox/NavStatus
@onready var event_banner: PanelContainer = $MarginContainer/RootColumn/EventBanner
@onready var event_label: Label = $MarginContainer/RootColumn/EventBanner/Margin/EventLabel
@onready var toast_card: PanelContainer = $ToastAnchor/ToastCard
@onready var toast_label: Label = $ToastAnchor/ToastCard/Margin/ToastLabel
@onready var combo_bar: ProgressBar = $MarginContainer/RootColumn/TopRow/ScoreCard/Margin/VBox/ComboBar
@onready var dash_bar: ProgressBar = $MarginContainer/RootColumn/TopRow/TelemetryCard/Margin/VBox/DashBar
@onready var dash_label: Label = $MarginContainer/RootColumn/TopRow/TelemetryCard/Margin/VBox/DashLabel
@onready var health_pip_row: HBoxContainer = $MarginContainer/RootColumn/TopRow/TelemetryCard/Margin/VBox/HealthRow/PipRow
@onready var margin_root: MarginContainer = $MarginContainer
@onready var root_column: VBoxContainer = $MarginContainer/RootColumn
@onready var top_row: HBoxContainer = $MarginContainer/RootColumn/TopRow
@onready var objective_row: HBoxContainer = $MarginContainer/RootColumn/ObjectiveRow
@onready var directive_row: HBoxContainer = $MarginContainer/RootColumn/DirectiveRow
@onready var cashout_row: HBoxContainer = $MarginContainer/RootColumn/CashoutRow
@onready var toast_anchor: Control = $ToastAnchor

var objective_text: String = "Secure the operation and extract."
var toast_timer: float = 0.0
var operation_context: Dictionary = {}
var directive_context: Dictionary = {}
var last_score: int = 0
var last_health: int = 0
var score_pulse_timer: float = 0.0
var damage_pulse_timer: float = 0.0
var cashout_pulse: float = 0.0
var last_event_banner_text: String = ""
var navigation_label: String = "DATA CORE"
var navigation_distance: float = 0.0
var navigation_direction: Vector2 = Vector2.ZERO
var navigation_active: bool = false
var score_popups: Array[Dictionary] = []
var popup_container: Control
var health_pips: Array[PanelContainer] = []
var health_target_scale: Array[float] = []
var displayed_max_health: int = 0
var low_health_overlay: ColorRect
var cashout_border: ColorRect
var combo_celebration_timer: float = 0.0
var last_combo_milestone: int = 0
var combo_multiplier_label: Label
var combo_edge_left: Polygon2D
var combo_edge_right: Polygon2D
var combo_break_timer: float = 0.0
var last_combo_count: int = 0


func _ready() -> void:
	_apply_theme()
	_sync_health_pip_count(_get_current_max_health())
	_create_popup_container()
	_create_screen_overlays()
	toast_card.visible = false
	last_score = GameState.score
	last_health = GameState.health
	GameState.state_changed.connect(_refresh)
	_refresh()


func _process(delta: float) -> void:
	_update_pulses(delta)
	_update_bars(delta)
	_update_popups(delta)
	_update_health_animation(delta)
	if toast_timer <= 0.0:
		return
	toast_timer -= delta
	var fade := minf(1.0, toast_timer / 0.35) if toast_timer < 0.35 else 1.0
	toast_card.modulate.a = fade
	if toast_timer <= 0.0:
		toast_card.visible = false


func spawn_score_popup(amount: int, at_position: Vector2, color: Color = TEXT_ACCENT) -> void:
	var popup := Label.new()
	popup.text = "+%d" % amount
	popup.add_theme_font_size_override("font_size", 20)
	popup.add_theme_color_override("font_color", color)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup.z_index = 90
	popup_container.add_child(popup)
	popup.global_position = at_position - Vector2(30, 0)
	score_popups.append({"node": popup, "life": 1.3, "velocity": Vector2(0, -140)})


func set_operation_context(operation: Dictionary, directive: Dictionary) -> void:
	operation_context = operation.duplicate(true)
	directive_context = directive.duplicate(true)
	_refresh()


func _refresh() -> void:
	if GameState.score > last_score:
		score_pulse_timer = 0.32
	_sync_health_pip_count(_get_current_max_health())
	if GameState.health < last_health:
		damage_pulse_timer = 0.42
		for i in range(maxi(0, GameState.health), health_pips.size()):
			health_target_scale[i] = 1.5
	last_score = GameState.score
	last_health = GameState.health
	score_label.text = "%04d" % GameState.score
	best_label.text = "CAREER BEST %04d" % int(GameState.meta_progress.get("highest_score", 0))
	if GameState.combo_count > 1 and GameState.combo_timer > 0.0:
		combo_label.text = "COMBO x%d" % GameState.combo_count
		combo_label.add_theme_color_override("font_color", TEXT_ACCENT)
	else:
		combo_label.text = "COMBO READY"
		combo_label.add_theme_color_override("font_color", TEXT_MUTED)
	core_label.text = "%d / %d" % [GameState.data_cores_collected, GameState.data_cores_total]
	time_label.text = GameState.formatted_time()
	if GameState.extraction_unlocked and not GameState.run_success and not GameState.is_run_failed:
		time_label.text = "%s // CASH %s" % [GameState.formatted_time(), GameState.formatted_cashout_time()]
		combo_label.text = "CASHOUT LIVE"
		combo_label.add_theme_color_override("font_color", TEXT_ACCENT)
	objective_label.text = objective_text
	title_label.text = String(operation_context.get("title", "NIGHT RUNNER"))
	subtitle_label.text = String(operation_context.get("subtitle", "Urban combat archive"))
	phase_name.text = GameState.get_route_phase_text()
	phase_status.text = "%s\n%s" % [GameState.get_operation_feel_summary(), GameState.get_route_pressure_text()]
	if directive_context.is_empty():
		directive_title.text = "LOADOUT"
		directive_name.text = "Base Protocol"
		directive_summary.text = "" if PlatformProfile.is_mobile else "No adaptive directive active."
	else:
		directive_title.text = "DIRECTIVE"
		directive_name.text = String(directive_context.get("name", "Adaptive Protocol"))
		directive_summary.text = String(directive_context.get("summary", ""))
	secondary_title.text = "OPTIONAL OBJECTIVE"
	secondary_name.text = GameState.get_secondary_objective_name() if not GameState.get_secondary_objective_name().is_empty() else "No optional objective"
	secondary_status.text = GameState.get_secondary_objective_status_text()
	cashout_title.text = GameState.get_extraction_bonus_label().to_upper() if not GameState.get_extraction_bonus_label().is_empty() else "CASHOUT WINDOW"
	cashout_status.text = GameState.get_extraction_bonus_status_text()
	if operation_context.has("hazards") and Array(operation_context.get("hazards", [])).size() > 0 and not GameState.run_success and not GameState.is_run_failed:
		cashout_status.text += "\n%s" % GameState.get_hazard_status_text()
	if not directive_context.is_empty():
		directive_summary.text = GameState.describe_modifier_block(Dictionary(directive_context.get("modifiers", {})))
	_refresh_event_banner()
	if GameState.run_success:
		rank_label.text = "RANK %s" % GameState.final_rank
		rank_label.add_theme_color_override("font_color", TEXT_SUCCESS)
		objective_title.text = "RUN COMPLETE"
		objective_label.add_theme_color_override("font_color", TEXT_SUCCESS)
		secondary_status.add_theme_color_override("font_color", TEXT_SUCCESS if GameState.secondary_objective_completed else TEXT_ALERT)
		cashout_status.add_theme_color_override("font_color", TEXT_SUCCESS if GameState.pending_extraction_bonus > 0 else TEXT_MUTED)
	elif GameState.is_run_failed:
		rank_label.text = "FAILED"
		rank_label.add_theme_color_override("font_color", TEXT_ALERT)
		objective_title.text = "RUN FAILED"
		objective_label.add_theme_color_override("font_color", TEXT_ALERT)
		secondary_status.add_theme_color_override("font_color", TEXT_ALERT)
		cashout_status.add_theme_color_override("font_color", TEXT_ALERT if GameState.pending_extraction_bonus > 0 else TEXT_MUTED)
	else:
		rank_label.text = "RANK --"
		rank_label.add_theme_color_override("font_color", TEXT_MUTED)
		objective_title.text = "OBJECTIVE"
		objective_label.add_theme_color_override("font_color", TEXT_PRIMARY)
		if GameState.current_secondary_objective.is_empty():
			secondary_status.add_theme_color_override("font_color", TEXT_MUTED)
		else:
			var progress_ratio := GameState.get_secondary_objective_progress_ratio()
			var secondary_color := TEXT_PRIMARY
			if String(GameState.current_secondary_objective.get("type", "")) == "time_limit" and progress_ratio >= 0.8:
				secondary_color = TEXT_ALERT
			elif String(GameState.current_secondary_objective.get("type", "")) == "no_hit" and GameState.hits_taken > 0:
				secondary_color = TEXT_ALERT
			elif String(GameState.current_secondary_objective.get("type", "")) == "score_threshold" and progress_ratio >= 1.0:
				secondary_color = TEXT_SUCCESS
			secondary_status.add_theme_color_override("font_color", secondary_color)
		cashout_status.add_theme_color_override("font_color", TEXT_ACCENT if GameState.pending_extraction_bonus > 0 else TEXT_MUTED)
	if PlatformProfile.is_mobile:
		directive_summary.text = ""
		phase_status.text = GameState.get_route_pressure_text()
		cashout_status.text = GameState.get_extraction_bonus_status_text().split(" // ")[0]
		operation_card.visible = false
		phase_card.visible = false
		secondary_card.visible = false
		nav_card.visible = true
		directive_card.visible = false
		best_label.visible = false
		combo_bar.visible = false
	else:
		operation_card.visible = true
		phase_card.visible = true
		secondary_card.visible = true
		directive_card.visible = true
		best_label.visible = true
		combo_bar.visible = true
	_refresh_navigation()
	_refresh_health_pips()
	_apply_operation_palette()


func set_objective(text: String) -> void:
	objective_text = text
	objective_label.text = text


func set_navigation_target(label: String, distance: float, direction: Vector2, active: bool = true) -> void:
	navigation_label = label
	navigation_distance = distance
	navigation_direction = direction
	navigation_active = active
	_refresh_navigation()


func clear_navigation_target() -> void:
	navigation_active = false
	_refresh_navigation()


func show_toast(text: String, duration: float = 2.3) -> void:
	toast_label.text = text
	toast_timer = duration
	toast_card.visible = true
	toast_card.modulate.a = 1.0
	toast_card.scale = Vector2(0.96, 0.96)
	var tween := create_tween()
	tween.tween_property(toast_card, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _apply_theme() -> void:
	var mobile_scale := PlatformProfile.get_mobile_ui_scale()
	var card_h: int = 100 if PlatformProfile.is_mobile else 152
	var card_w_score: int = 180 if PlatformProfile.is_mobile else 232
	var card_w_telem: int = 200 if PlatformProfile.is_mobile else 252
	score_card.custom_minimum_size = Vector2(card_w_score, card_h)
	telemetry_card.custom_minimum_size = Vector2(card_w_telem, card_h + 40 if not PlatformProfile.is_mobile else card_h)
	score_card.add_theme_stylebox_override("panel", _make_panel_style(PANEL_BG, PANEL_BORDER, 22))
	operation_card.add_theme_stylebox_override("panel", _make_panel_style(PANEL_BG, PANEL_BORDER, 22))
	telemetry_card.add_theme_stylebox_override("panel", _make_panel_style(PANEL_BG, PANEL_BORDER, 22))
	objective_card.add_theme_stylebox_override("panel", _make_panel_style(PANEL_SOFT, PANEL_BORDER, 18))
	phase_card.add_theme_stylebox_override("panel", _make_panel_style(PANEL_SOFT, Color(0.96, 0.55, 0.26, 0.42), 18))
	directive_card.add_theme_stylebox_override("panel", _make_panel_style(PANEL_SOFT, PANEL_ACCENT, 18))
	secondary_card.add_theme_stylebox_override("panel", _make_panel_style(PANEL_SOFT, Color(0.82, 0.84, 1.0, 0.3), 18))
	cashout_card.add_theme_stylebox_override("panel", _make_panel_style(PANEL_SOFT, Color(1.0, 0.72, 0.35, 0.4), 18))
	if PlatformProfile.is_mobile:
		objective_card.custom_minimum_size = Vector2(300, 60)
		cashout_card.custom_minimum_size = Vector2(300, 56)
	nav_card.add_theme_stylebox_override("panel", _make_panel_style(Color(0.08, 0.13, 0.21, 0.74), Color(0.42, 0.94, 1.0, 0.42), 18))
	toast_card.add_theme_stylebox_override("panel", _make_panel_style(PANEL_BG, PANEL_ACCENT, 18, 2, 12))
	_combo_bar_style()
	_dash_bar_style()
	for label in [score_caption, best_label, combo_label, health_caption, core_caption, time_caption, objective_title, phase_title, directive_title, secondary_title, cashout_title, nav_title]:
		_style_caption(label)
	_style_caption(dash_label)
	_style_metric(score_label, int(34 * mobile_scale), TEXT_ACCENT)
	_style_metric(core_label, int(22 * mobile_scale), TEXT_PRIMARY)
	_style_metric(time_label, int(24 * mobile_scale), TEXT_PRIMARY)
	_style_metric(rank_label, int(20 * mobile_scale), TEXT_MUTED)
	score_label.pivot_offset = Vector2(80, 22)
	title_label.add_theme_font_size_override("font_size", int(24 * mobile_scale))
	title_label.add_theme_color_override("font_color", Color(0.61, 0.86, 1.0))
	subtitle_label.add_theme_font_size_override("font_size", int(14 * mobile_scale))
	subtitle_label.add_theme_color_override("font_color", TEXT_MUTED)
	objective_label.add_theme_font_size_override("font_size", int(16 * mobile_scale))
	objective_label.add_theme_color_override("font_color", TEXT_PRIMARY)
	phase_name.add_theme_font_size_override("font_size", int(17 * mobile_scale))
	phase_name.add_theme_color_override("font_color", TEXT_ACCENT)
	phase_status.add_theme_font_size_override("font_size", int(14 * mobile_scale))
	phase_status.add_theme_color_override("font_color", TEXT_MUTED)
	directive_name.add_theme_font_size_override("font_size", int(17 * mobile_scale))
	directive_name.add_theme_color_override("font_color", TEXT_PRIMARY)
	directive_summary.add_theme_font_size_override("font_size", int(14 * mobile_scale))
	directive_summary.add_theme_color_override("font_color", TEXT_MUTED)
	secondary_name.add_theme_font_size_override("font_size", int(17 * mobile_scale))
	secondary_name.add_theme_color_override("font_color", TEXT_PRIMARY)
	secondary_status.add_theme_font_size_override("font_size", int(14 * mobile_scale))
	secondary_status.add_theme_color_override("font_color", TEXT_MUTED)
	cashout_status.add_theme_font_size_override("font_size", int(14 * mobile_scale))
	cashout_status.add_theme_color_override("font_color", TEXT_SOFT)
	nav_status.add_theme_font_size_override("font_size", int(14 * mobile_scale))
	nav_status.add_theme_color_override("font_color", TEXT_SOFT)
	toast_label.add_theme_font_size_override("font_size", int(16 * mobile_scale))
	toast_label.add_theme_color_override("font_color", TEXT_PRIMARY)
	var safe := PlatformProfile.get_safe_area_margin()
	var base_margin := 18 if PlatformProfile.is_mobile else 28
	margin_root.add_theme_constant_override("margin_left", int(base_margin + safe.x))
	margin_root.add_theme_constant_override("margin_top", int((14 if PlatformProfile.is_mobile else 20) + safe.y))
	margin_root.add_theme_constant_override("margin_right", int(base_margin + safe.z))
	margin_root.add_theme_constant_override("margin_bottom", int((14 if PlatformProfile.is_mobile else 20) + safe.w))
	root_column.add_theme_constant_override("separation", 10 if PlatformProfile.is_mobile else 14)
	top_row.add_theme_constant_override("separation", 10 if PlatformProfile.is_mobile else 14)
	objective_row.add_theme_constant_override("separation", 8 if PlatformProfile.is_mobile else 12)
	directive_row.add_theme_constant_override("separation", 8 if PlatformProfile.is_mobile else 12)
	cashout_row.add_theme_constant_override("separation", 8 if PlatformProfile.is_mobile else 12)
	if PlatformProfile.is_mobile:
		var toast_bottom := 308.0 * mobile_scale + safe.w
		toast_anchor.offset_left = -220.0
		toast_anchor.offset_top = -(toast_bottom + 86.0)
		toast_anchor.offset_right = 220.0
		toast_anchor.offset_bottom = -toast_bottom
	else:
		toast_anchor.offset_left = -250.0
		toast_anchor.offset_top = -110.0
		toast_anchor.offset_right = 250.0
		toast_anchor.offset_bottom = -24.0
	event_banner.add_theme_stylebox_override("panel", _make_panel_style(Color(0.13, 0.19, 0.3, 0.9), PANEL_ACCENT, 18, 2, 14))
	event_label.add_theme_font_size_override("font_size", 18)
	event_label.add_theme_color_override("font_color", TEXT_PRIMARY)


func _combo_bar_style() -> void:
	combo_bar.max_value = 1.0
	combo_bar.value = 0.0
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = COMBO_BAR_BG
	bg_style.corner_radius_top_left = 6
	bg_style.corner_radius_top_right = 6
	bg_style.corner_radius_bottom_left = 6
	bg_style.corner_radius_bottom_right = 6
	combo_bar.add_theme_stylebox_override("background", bg_style)
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = COMBO_BAR_FILL
	fill_style.corner_radius_top_left = 6
	fill_style.corner_radius_top_right = 6
	fill_style.corner_radius_bottom_left = 6
	fill_style.corner_radius_bottom_right = 6
	combo_bar.add_theme_stylebox_override("fill", fill_style)


func _dash_bar_style() -> void:
	dash_bar.max_value = 1.0
	dash_bar.value = 1.0
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = DASH_BAR_BG
	bg_style.corner_radius_top_left = 6
	bg_style.corner_radius_top_right = 6
	bg_style.corner_radius_bottom_left = 6
	bg_style.corner_radius_bottom_right = 6
	dash_bar.add_theme_stylebox_override("background", bg_style)
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = DASH_BAR_FILL
	fill_style.corner_radius_top_left = 6
	fill_style.corner_radius_top_right = 6
	fill_style.corner_radius_bottom_left = 6
	fill_style.corner_radius_bottom_right = 6
	dash_bar.add_theme_stylebox_override("fill", fill_style)


func _create_popup_container() -> void:
	popup_container = Control.new()
	popup_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_container.z_index = 85
	add_child(popup_container)


func _update_bars(delta: float) -> void:
	var combo_target := 0.0
	if GameState.combo_timer > 0.0 and GameState.combo_count > 0:
		combo_target = GameState.combo_timer / GameState.combo_window
	combo_bar.value = move_toward(combo_bar.value, combo_target, delta * 3.0)
	combo_bar.visible = combo_bar.value > 0.02

	var dash_target := 1.0
	var player_nodes := get_tree().get_nodes_in_group("player")
	if player_nodes.size() > 0:
		var p := player_nodes[0]
		var cd := float(p.get("dash_cooldown_timer"))
		var max_cd := float(p.get("DASH_COOLDOWN"))
		if cd > 0.0 and max_cd > 0.0:
			dash_target = 1.0 - (cd / max_cd)
	dash_bar.value = move_toward(dash_bar.value, dash_target, delta * 5.0)
	dash_bar.visible = true
	if dash_bar.value >= 0.98:
		dash_label.text = "DASH READY"
		var fill_ready := StyleBoxFlat.new()
		fill_ready.bg_color = Color(0.28, 0.88, 1.0, 0.95)
		fill_ready.corner_radius_top_left = 6
		fill_ready.corner_radius_top_right = 6
		fill_ready.corner_radius_bottom_left = 6
		fill_ready.corner_radius_bottom_right = 6
		dash_bar.add_theme_stylebox_override("fill", fill_ready)
		dash_label.add_theme_color_override("font_color", Color(0.42, 0.94, 1.0, 0.85))
	else:
		dash_label.text = "DASH COOLING"
		var fill_cd := StyleBoxFlat.new()
		fill_cd.bg_color = Color(0.18, 0.42, 0.62, 0.8)
		fill_cd.corner_radius_top_left = 6
		fill_cd.corner_radius_top_right = 6
		fill_cd.corner_radius_bottom_left = 6
		fill_cd.corner_radius_bottom_right = 6
		dash_bar.add_theme_stylebox_override("fill", fill_cd)
		dash_label.add_theme_color_override("font_color", Color(0.32, 0.52, 0.68, 0.6))


func _update_popups(delta: float) -> void:
	var to_remove: Array[int] = []
	for i in score_popups.size():
		var data := score_popups[i]
		var node: Label = data["node"]
		if not is_instance_valid(node):
			to_remove.append(i)
			continue
		data["life"] -= delta
		if data["life"] <= 0.0:
			node.queue_free()
			to_remove.append(i)
		else:
			node.position += data["velocity"] * delta
			node.modulate.a = minf(1.0, data["life"] / 0.3)
			node.scale = Vector2.ONE * (1.0 + (1.2 - minf(1.2, data["life"])) * 0.3)
	for i in range(to_remove.size() - 1, -1, -1):
		score_popups.remove_at(to_remove[i])


func _update_health_animation(delta: float) -> void:
	for i in health_pips.size():
		health_target_scale[i] = move_toward(health_target_scale[i], 1.0, delta * 12.0)
		health_pips[i].pivot_offset = health_pips[i].size * 0.5
		health_pips[i].scale = Vector2.ONE * health_target_scale[i]


func _create_screen_overlays() -> void:
	low_health_overlay = ColorRect.new()
	low_health_overlay.color = Color(0.9, 0.12, 0.08, 0.0)
	low_health_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	low_health_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	low_health_overlay.z_index = 78
	low_health_overlay.visible = false
	add_child(low_health_overlay)
	cashout_border = ColorRect.new()
	cashout_border.color = Color(1.0, 0.72, 0.28, 0.0)
	cashout_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cashout_border.set_anchors_preset(Control.PRESET_FULL_RECT)
	cashout_border.z_index = 77
	cashout_border.visible = false
	add_child(cashout_border)
	# Combo multiplier - big center display
	combo_multiplier_label = Label.new()
	combo_multiplier_label.text = ""
	combo_multiplier_label.add_theme_font_size_override("font_size", 48)
	combo_multiplier_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3, 0.0))
	combo_multiplier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_multiplier_label.z_index = 88
	combo_multiplier_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	combo_multiplier_label.position = Vector2(560, 45)
	combo_multiplier_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(combo_multiplier_label)
	# Combo edge flames
	combo_edge_left = Polygon2D.new()
	combo_edge_left.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(60, 0), Vector2(30, 360), Vector2(0, 360),
	])
	combo_edge_left.color = Color(1.0, 0.55, 0.15, 0.0)
	combo_edge_left.z_index = 76
	combo_edge_left.position = Vector2.ZERO
	add_child(combo_edge_left)
	combo_edge_right = Polygon2D.new()
	combo_edge_right.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(60, 0), Vector2(60, 360), Vector2(30, 360),
	])
	combo_edge_right.color = Color(1.0, 0.55, 0.15, 0.0)
	combo_edge_right.z_index = 76
	add_child(combo_edge_right)


func _check_combo_celebration() -> void:
	var health_bonus_val: int = int(GameState.run_modifiers.get("health_bonus", 0))
	var max_hp: float = max(1.0, float(max(1, 3 + health_bonus_val)))
	var health_ratio: float = float(GameState.health) / max_hp
	if GameState.is_run_failed:
		low_health_overlay.visible = false
		cashout_border.visible = false
		combo_multiplier_label.text = ""
		combo_edge_left.visible = false
		combo_edge_right.visible = false
		return
	if health_ratio <= 0.34 and not GameState.run_success:
		low_health_overlay.visible = true
		var pulse := sin(cashout_pulse * 6.0) * 0.5 + 0.5
		low_health_overlay.color = Color(0.9, 0.12, 0.08, 0.06 + pulse * 0.08)
	else:
		low_health_overlay.visible = false
	if GameState.extraction_unlocked and not GameState.run_success and not GameState.is_run_failed:
		cashout_border.visible = true
		var heat := GameState.get_extraction_bonus_progress_ratio()
		var border_pulse := sin(cashout_pulse * 3.5) * 0.5 + 0.5
		cashout_border.color = Color(1.0, 0.68, 0.22, 0.02 + heat * 0.06 + border_pulse * 0.03)
	else:
		cashout_border.visible = false
	# Combo multiplier display
	var combo := GameState.combo_count
	var multiplier: float = 1.0 + max(0, combo - 1) * 0.15
	if combo >= 3 and GameState.combo_timer > 0.0 and not GameState.run_success:
		combo_multiplier_label.text = "x%.1f" % multiplier
		var intensity := clampf(float(combo) / 8.0, 0.0, 1.0)
		var label_pulse := sin(cashout_pulse * 8.0) * 0.12 + 0.88
		combo_multiplier_label.add_theme_color_override("font_color", Color(1.0, 0.85 - intensity * 0.3, 0.3 - intensity * 0.2, label_pulse))
		combo_multiplier_label.scale = Vector2.ONE * (1.0 + intensity * 0.3 + sin(cashout_pulse * 6.0) * 0.04)
		# Edge flames
		combo_edge_left.visible = true
		combo_edge_right.visible = true
		var vp_size := get_viewport().get_visible_rect().size
		combo_edge_right.position = Vector2(vp_size.x - 60, vp_size.y - 360)
		var flame_alpha := 0.04 + intensity * 0.1 + sin(cashout_pulse * 5.0) * 0.02
		combo_edge_left.color = Color(1.0, 0.55 - intensity * 0.2, 0.15 - intensity * 0.1, flame_alpha)
		combo_edge_right.color = combo_edge_left.color
		combo_edge_left.scale.y = 0.7 + intensity * 0.5 + sin(cashout_pulse * 3.0) * 0.08
		combo_edge_right.scale.y = combo_edge_left.scale.y
	else:
		combo_multiplier_label.text = ""
		combo_edge_left.visible = false
		combo_edge_right.visible = false
	# Combo break shake
	if combo == 0 and last_combo_count >= 3:
		combo_break_timer = 0.25
	if combo_break_timer > 0.0:
		combo_break_timer -= get_process_delta_time()
		combo_multiplier_label.text = "BREAK"
		combo_multiplier_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2, combo_break_timer / 0.25))
		combo_multiplier_label.scale = Vector2.ONE * (1.0 + combo_break_timer * 1.5)
	last_combo_count = combo


func _spawn_combo_burst() -> void:
	var center := score_label.global_position + score_label.size * 0.5
	for index in 6:
		var spark := Polygon2D.new()
		spark.polygon = PackedVector2Array([
			Vector2(0.0, -4.0), Vector2(10.0, 0.0), Vector2(0.0, 4.0), Vector2(-10.0, 0.0),
		])
		var angle := TAU * float(index) / 6.0
		spark.global_position = center
		spark.rotation = angle
		spark.color = Color(1.0, 0.84, 0.32, 0.8)
		spark.z_index = 92
		popup_container.add_child(spark)
		var tween := spark.create_tween()
		tween.set_parallel(true)
		tween.tween_property(spark, "global_position", center + Vector2(cos(angle), sin(angle)) * 36.0, 0.22)
		tween.tween_property(spark, "modulate:a", 0.0, 0.24)
		tween.tween_property(spark, "scale", Vector2.ONE * 0.3, 0.22)
		tween.set_parallel(false)
		tween.tween_callback(spark.queue_free)


func _refresh_health_pips() -> void:
	_sync_health_pip_count(_get_current_max_health())
	for index in health_pips.size():
		var fill := HEALTH_ON if index < GameState.health else HEALTH_OFF
		var border := Color(1.0, 0.62, 0.45, 0.8) if index < GameState.health else Color(0.22, 0.33, 0.49, 0.7)
		health_pips[index].add_theme_stylebox_override("panel", _make_panel_style(fill, border, 999, 1, 0))


func _get_current_max_health() -> int:
	return maxi(GameState.health, maxi(1, HEALTH_BASE_MAX + int(GameState.run_modifiers.get("health_bonus", 0))))


func _sync_health_pip_count(max_health: int) -> void:
	var target_count := maxi(1, max_health)
	if displayed_max_health == target_count and health_pips.size() == target_count:
		return
	health_pips.clear()
	health_target_scale.clear()
	for child in health_pip_row.get_children():
		health_pip_row.remove_child(child)
		child.queue_free()
	for index in target_count:
		var pip := PanelContainer.new()
		pip.name = "Pip%d" % (index + 1)
		pip.custom_minimum_size = HEALTH_PIP_SIZE
		health_pip_row.add_child(pip)
		health_pips.append(pip)
		health_target_scale.append(1.0)
	displayed_max_health = target_count


func _update_pulses(delta: float) -> void:
	cashout_pulse += delta
	if combo_celebration_timer > 0.0:
		combo_celebration_timer -= delta
	_check_combo_celebration()
	var current_combo := GameState.combo_count
	if current_combo > last_combo_milestone and current_combo >= 3:
		combo_celebration_timer = 0.4
		_spawn_combo_burst()
	last_combo_milestone = current_combo
	if score_pulse_timer > 0.0:
		score_pulse_timer -= delta
		var combo_bonus := clampf(float(GameState.combo_count) / 6.0, 0.0, 1.0) * 0.12
		var score_scale := 1.0 + clampf(score_pulse_timer / 0.32, 0.0, 1.0) * (0.16 + combo_bonus)
		score_label.scale = Vector2.ONE * score_scale
		score_card.modulate = Color(1.0, 0.9 + score_pulse_timer, 0.72 - combo_bonus * 0.4, 1.0)
	else:
		score_label.scale = score_label.scale.move_toward(Vector2.ONE, delta * 8.0)
		score_card.modulate = score_card.modulate.lerp(Color.WHITE, delta * 8.0)
	if damage_pulse_timer > 0.0:
		damage_pulse_timer -= delta
		var hit_mix := clampf(damage_pulse_timer / 0.42, 0.0, 1.0)
		telemetry_card.modulate = Color(1.0, 0.58 + hit_mix * 0.28, 0.52 + hit_mix * 0.24, 1.0)
	else:
		telemetry_card.modulate = telemetry_card.modulate.lerp(Color.WHITE, delta * 8.0)
	if GameState.extraction_unlocked and not GameState.run_success and not GameState.is_run_failed:
		var glow := 0.84 + sin(cashout_pulse * 5.4) * 0.12
		cashout_card.modulate = Color(1.0, glow, 0.62, 1.0)
	else:
		cashout_card.modulate = cashout_card.modulate.lerp(Color.WHITE, delta * 6.0)


func _style_caption(label: Label) -> void:
	label.add_theme_font_size_override("font_size", int(12 * PlatformProfile.get_mobile_ui_scale()))
	label.add_theme_color_override("font_color", TEXT_MUTED)


func _style_metric(label: Label, size: int, color: Color) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)


func _apply_operation_palette() -> void:
	var theme: Dictionary = operation_context.get("theme", {})
	if theme.is_empty():
		return
	var primary: Color = theme.get("primary", PANEL_BORDER)
	var secondary: Color = theme.get("secondary", PANEL_ACCENT)
	operation_card.add_theme_stylebox_override("panel", _make_panel_style(PANEL_BG, primary, 22))
	directive_card.add_theme_stylebox_override("panel", _make_panel_style(PANEL_SOFT, secondary, 18))
	objective_card.add_theme_stylebox_override("panel", _make_panel_style(PANEL_SOFT, primary, 18))
	phase_card.add_theme_stylebox_override("panel", _make_panel_style(PANEL_SOFT, secondary.lightened(0.04), 18))
	secondary_card.add_theme_stylebox_override("panel", _make_panel_style(PANEL_SOFT, primary.lightened(0.12), 18))
	cashout_card.add_theme_stylebox_override("panel", _make_panel_style(PANEL_SOFT, secondary.lightened(0.08), 18))
	nav_card.add_theme_stylebox_override("panel", _make_panel_style(Color(primary.r * 0.28, primary.g * 0.3, primary.b * 0.36, 0.78), primary.lightened(0.08), 18))
	title_label.add_theme_color_override("font_color", primary.lightened(0.18))
	phase_title.add_theme_color_override("font_color", secondary.lightened(0.12))
	phase_name.add_theme_color_override("font_color", secondary.lightened(0.18))
	directive_title.add_theme_color_override("font_color", secondary.lightened(0.1))
	cashout_title.add_theme_color_override("font_color", secondary.lightened(0.12))
	nav_title.add_theme_color_override("font_color", primary.lightened(0.16))
	event_banner.add_theme_stylebox_override("panel", _make_panel_style(Color(primary.r * 0.35, primary.g * 0.35, primary.b * 0.35, 0.92), secondary.lightened(0.08), 18, 2, 14))
	event_label.add_theme_color_override("font_color", secondary.lightened(0.22))


func _refresh_navigation() -> void:
	nav_card.visible = navigation_active and not GameState.run_success and not GameState.is_run_failed
	if not nav_card.visible:
		return
	var arrow := _direction_to_arrow(navigation_direction)
	var distance_text := "%dm" % max(1, int(round(navigation_distance / 10.0)))
	var vector_line := "%s  %s // %s" % [arrow, navigation_label.to_upper(), distance_text]
	if PlatformProfile.is_mobile:
		var context_line := _get_mobile_navigation_context_line()
		nav_status.text = "%s\n%s" % [vector_line, context_line] if not context_line.is_empty() else vector_line
	else:
		nav_status.text = vector_line
	if navigation_label.to_lower().contains("extract"):
		nav_status.add_theme_color_override("font_color", TEXT_ACCENT)
	else:
		nav_status.add_theme_color_override("font_color", TEXT_SOFT)


func _get_mobile_navigation_context_line() -> String:
	var fragments: Array[String] = []
	var pressure_line := _get_mobile_route_pressure_text()
	if not pressure_line.is_empty():
		fragments.append(pressure_line)
	var optional_status := _get_mobile_optional_status_text()
	if not optional_status.is_empty():
		fragments.append(optional_status)
	return " // ".join(fragments)


func _get_mobile_route_pressure_text() -> String:
	var pressure_line := GameState.get_route_pressure_text()
	if pressure_line.is_empty():
		return ""
	var primary_clause := pressure_line.split(".")[0].strip_edges()
	if primary_clause.is_empty():
		primary_clause = pressure_line.split(" // ")[0].strip_edges()
	if primary_clause.length() > 34:
		primary_clause = primary_clause.substr(0, 31).strip_edges() + "..."
	var phase_text := GameState.get_route_phase_text().to_upper()
	if phase_text.is_empty():
		return primary_clause
	return "%s %s" % [phase_text, primary_clause]


func _get_mobile_optional_status_text() -> String:
	if GameState.current_secondary_objective.is_empty():
		return ""
	var objective_type := String(GameState.current_secondary_objective.get("type", ""))
	match objective_type:
		"time_limit":
			var target_time := float(GameState.current_secondary_objective.get("target_time", 0.0))
			var delta_time := target_time - GameState.elapsed_time
			if delta_time >= 0.0:
				return "OPT %s LEFT" % _format_mobile_time(delta_time)
			return "OPT %s OVER" % _format_mobile_time(absf(delta_time))
		"no_hit":
			return "OPT CLEAN" if GameState.hits_taken <= 0 else "OPT BROKEN %dH" % GameState.hits_taken
		"score_threshold":
			var target_score := int(GameState.current_secondary_objective.get("target_score", 0))
			var score_gap := maxi(0, target_score - GameState.score)
			return "OPT ARMED" if score_gap <= 0 else "OPT %d SCORE LEFT" % score_gap
		_:
			return "OPT %s" % GameState.get_secondary_objective_name().to_upper()


func _format_mobile_time(time_value: float) -> String:
	var total_seconds := maxi(0, int(time_value))
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]


func _direction_to_arrow(direction: Vector2) -> String:
	if direction.length() < 0.05:
		return "◆"
	if absf(direction.x) > absf(direction.y) * 1.45:
		return "→" if direction.x >= 0.0 else "←"
	if absf(direction.y) > absf(direction.x) * 1.45:
		return "↓" if direction.y >= 0.0 else "↑"
	return "%s%s" % [("S" if direction.y >= 0.0 else "N"), ("E" if direction.x >= 0.0 else "W")]


func _refresh_event_banner() -> void:
	var banner_text := GameState.get_event_banner_text()
	var emphasis := GameState.get_event_banner_emphasis()
	event_banner.visible = not banner_text.is_empty() and emphasis > 0.02 and not GameState.run_success and not GameState.is_run_failed
	if not event_banner.visible:
		return
	if banner_text != last_event_banner_text:
		last_event_banner_text = banner_text
		event_banner.scale = Vector2(1.04, 1.12)
		var tween := create_tween()
		tween.tween_property(event_banner, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	event_label.text = banner_text.to_upper()
	event_banner.modulate.a = clampf(0.3 + emphasis * 0.7, 0.2, 1.0)

func _make_panel_style(fill: Color, border: Color, radius: int, border_width: int = 2, shadow_size: int = 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.3)
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(0, 8)
	style.expand_margin_left = 0
	style.expand_margin_top = 0
	style.expand_margin_right = 0
	style.expand_margin_bottom = 0
	return style
