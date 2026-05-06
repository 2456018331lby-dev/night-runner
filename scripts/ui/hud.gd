extends CanvasLayer

const PANEL_BG := Color(0.04, 0.07, 0.13, 0.82)
const PANEL_BORDER := Color(0.26, 0.79, 1.0, 0.48)
const STATUS_BORDER := Color(1.0, 0.56, 0.24, 0.74)
const ALERT_BORDER := Color(1.0, 0.34, 0.32, 0.84)
const SUCCESS_BORDER := Color(0.4, 1.0, 0.79, 0.92)
const TEXT_PRIMARY := Color(0.96, 0.98, 1.0)
const TEXT_MUTED := Color(0.67, 0.79, 0.95)
const TEXT_ACCENT := Color(1.0, 0.84, 0.42)
const TEXT_SUCCESS := Color(0.76, 1.0, 0.88)
const HEALTH_ON := Color(1.0, 0.46, 0.36, 1.0)
const HEALTH_OFF := Color(0.13, 0.2, 0.31, 1.0)

@onready var score_card: PanelContainer = $MarginContainer/TopRow/ScoreCard
@onready var status_card: PanelContainer = $MarginContainer/TopRow/CenterColumn/StatusCard
@onready var right_card: PanelContainer = $MarginContainer/TopRow/RightCard
@onready var title_label: Label = $MarginContainer/TopRow/CenterColumn/TitleLabel
@onready var score_caption: Label = $MarginContainer/TopRow/ScoreCard/Margin/VBox/ScoreCaption
@onready var score_label: Label = $MarginContainer/TopRow/ScoreCard/Margin/VBox/ScoreLabel
@onready var best_label: Label = $MarginContainer/TopRow/ScoreCard/Margin/VBox/BestLabel
@onready var combo_label: Label = $MarginContainer/TopRow/ScoreCard/Margin/VBox/ComboLabel
@onready var status_label: Label = $MarginContainer/TopRow/CenterColumn/StatusCard/Margin/StatusLabel
@onready var health_caption: Label = $MarginContainer/TopRow/RightCard/Margin/VBox/HealthRow/HealthCaption
@onready var core_caption: Label = $MarginContainer/TopRow/RightCard/Margin/VBox/CoreCaption
@onready var core_label: Label = $MarginContainer/TopRow/RightCard/Margin/VBox/CoreLabel
@onready var time_caption: Label = $MarginContainer/TopRow/RightCard/Margin/VBox/TimeCaption
@onready var time_label: Label = $MarginContainer/TopRow/RightCard/Margin/VBox/TimeLabel
@onready var rank_label: Label = $MarginContainer/TopRow/RightCard/Margin/VBox/RankLabel
@onready var health_pips: Array[PanelContainer] = [
	$MarginContainer/TopRow/RightCard/Margin/VBox/HealthRow/PipRow/Pip1,
	$MarginContainer/TopRow/RightCard/Margin/VBox/HealthRow/PipRow/Pip2,
	$MarginContainer/TopRow/RightCard/Margin/VBox/HealthRow/PipRow/Pip3,
]

var status_text: String = "Run the roofs."


func _ready() -> void:
	status_text = status_label.text
	_apply_theme()
	GameState.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	score_label.text = "%04d" % GameState.score
	best_label.text = "BEST %04d" % int(GameState.meta_progress.get("highest_score", 0))
	if GameState.combo_count > 1 and GameState.combo_timer > 0.0:
		combo_label.text = "COMBO x%d" % GameState.combo_count
		combo_label.add_theme_color_override("font_color", TEXT_ACCENT)
	else:
		combo_label.text = "COMBO READY"
		combo_label.add_theme_color_override("font_color", TEXT_MUTED)
	core_label.text = "%d / %d" % [GameState.data_cores_collected, GameState.data_cores_total]
	time_label.text = GameState.formatted_time()
	if GameState.run_success:
		rank_label.text = "RANK %s" % GameState.final_rank
		rank_label.add_theme_color_override("font_color", TEXT_SUCCESS)
	elif GameState.is_run_failed:
		rank_label.text = "FAILED"
		rank_label.add_theme_color_override("font_color", Color(1.0, 0.74, 0.72))
	else:
		rank_label.text = "RANK --"
		rank_label.add_theme_color_override("font_color", TEXT_MUTED)
	status_label.text = status_text
	_refresh_status_style()
	_refresh_health_pips()


func set_status(text: String) -> void:
	status_text = text
	status_label.text = text
	_refresh_status_style()


func _apply_theme() -> void:
	score_card.add_theme_stylebox_override("panel", _make_panel_style(PANEL_BG, PANEL_BORDER, 22))
	right_card.add_theme_stylebox_override("panel", _make_panel_style(PANEL_BG, PANEL_BORDER, 22))
	_style_caption(score_caption)
	_style_caption(best_label)
	_style_caption(combo_label)
	_style_caption(health_caption)
	_style_caption(core_caption)
	_style_caption(time_caption)
	_style_metric(score_label, 30, TEXT_ACCENT)
	_style_metric(core_label, 22, TEXT_PRIMARY)
	_style_metric(time_label, 28, TEXT_PRIMARY)
	_style_metric(rank_label, 20, TEXT_MUTED)
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(0.61, 0.86, 1.0))
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", TEXT_PRIMARY)


func _refresh_status_style() -> void:
	var border := STATUS_BORDER
	var text_color := TEXT_PRIMARY
	if GameState.is_run_failed:
		border = ALERT_BORDER
		text_color = Color(1.0, 0.82, 0.8)
	elif GameState.run_success:
		border = SUCCESS_BORDER
		text_color = TEXT_SUCCESS
	status_card.add_theme_stylebox_override("panel", _make_panel_style(PANEL_BG, border, 20))
	status_label.add_theme_color_override("font_color", text_color)


func _refresh_health_pips() -> void:
	for index in health_pips.size():
		var fill := HEALTH_ON if index < GameState.health else HEALTH_OFF
		var border := Color(1.0, 0.62, 0.45, 0.8) if index < GameState.health else Color(0.22, 0.33, 0.49, 0.7)
		health_pips[index].add_theme_stylebox_override("panel", _make_panel_style(fill, border, 999, 1, 0))


func _style_caption(label: Label) -> void:
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", TEXT_MUTED)


func _style_metric(label: Label, size: int, color: Color) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)


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
	return style
