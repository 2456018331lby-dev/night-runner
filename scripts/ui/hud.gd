extends CanvasLayer

const PANEL_BG := Color(0.04, 0.07, 0.13, 0.82)
const PANEL_BORDER := Color(0.26, 0.79, 1.0, 0.48)
const TOAST_BORDER := Color(1.0, 0.56, 0.24, 0.86)
const TEXT_PRIMARY := Color(0.96, 0.98, 1.0)
const TEXT_MUTED := Color(0.67, 0.79, 0.95)
const TEXT_ACCENT := Color(1.0, 0.84, 0.42)
const TEXT_SUCCESS := Color(0.76, 1.0, 0.88)
const HEALTH_ON := Color(1.0, 0.46, 0.36, 1.0)
const HEALTH_OFF := Color(0.13, 0.2, 0.31, 1.0)

@onready var score_card: PanelContainer = $MarginContainer/RootColumn/TopRow/ScoreCard
@onready var right_card: PanelContainer = $MarginContainer/RootColumn/TopRow/RightCard
@onready var objective_card: PanelContainer = $MarginContainer/RootColumn/ObjectiveRow/ObjectiveCard
@onready var title_label: Label = $MarginContainer/RootColumn/TopRow/CenterColumn/TitleLabel
@onready var score_caption: Label = $MarginContainer/RootColumn/TopRow/ScoreCard/Margin/VBox/ScoreCaption
@onready var score_label: Label = $MarginContainer/RootColumn/TopRow/ScoreCard/Margin/VBox/ScoreLabel
@onready var best_label: Label = $MarginContainer/RootColumn/TopRow/ScoreCard/Margin/VBox/BestLabel
@onready var combo_label: Label = $MarginContainer/RootColumn/TopRow/ScoreCard/Margin/VBox/ComboLabel
@onready var objective_title: Label = $MarginContainer/RootColumn/ObjectiveRow/ObjectiveCard/Margin/VBox/ObjectiveTitle
@onready var objective_label: Label = $MarginContainer/RootColumn/ObjectiveRow/ObjectiveCard/Margin/VBox/ObjectiveLabel
@onready var health_caption: Label = $MarginContainer/RootColumn/TopRow/RightCard/Margin/VBox/HealthRow/HealthCaption
@onready var core_caption: Label = $MarginContainer/RootColumn/TopRow/RightCard/Margin/VBox/CoreCaption
@onready var core_label: Label = $MarginContainer/RootColumn/TopRow/RightCard/Margin/VBox/CoreLabel
@onready var time_caption: Label = $MarginContainer/RootColumn/TopRow/RightCard/Margin/VBox/TimeCaption
@onready var time_label: Label = $MarginContainer/RootColumn/TopRow/RightCard/Margin/VBox/TimeLabel
@onready var rank_label: Label = $MarginContainer/RootColumn/TopRow/RightCard/Margin/VBox/RankLabel
@onready var toast_card: PanelContainer = $ToastAnchor/ToastCard
@onready var toast_label: Label = $ToastAnchor/ToastCard/Margin/ToastLabel
@onready var health_pips: Array[PanelContainer] = [
	$MarginContainer/RootColumn/TopRow/RightCard/Margin/VBox/HealthRow/PipRow/Pip1,
	$MarginContainer/RootColumn/TopRow/RightCard/Margin/VBox/HealthRow/PipRow/Pip2,
	$MarginContainer/RootColumn/TopRow/RightCard/Margin/VBox/HealthRow/PipRow/Pip3,
]

var objective_text: String = "Steal all data cores and extract."
var toast_timer: float = 0.0


func _ready() -> void:
	_apply_theme()
	toast_card.visible = false
	GameState.state_changed.connect(_refresh)
	_refresh()


func _process(delta: float) -> void:
	if toast_timer <= 0.0:
		return
	toast_timer -= delta
	var fade := minf(1.0, toast_timer / 0.35) if toast_timer < 0.35 else 1.0
	toast_card.modulate.a = fade
	if toast_timer <= 0.0:
		toast_card.visible = false


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
	objective_label.text = objective_text
	if GameState.run_success:
		rank_label.text = "RANK %s" % GameState.final_rank
		rank_label.add_theme_color_override("font_color", TEXT_SUCCESS)
		objective_title.text = "RUN COMPLETE"
		objective_label.add_theme_color_override("font_color", TEXT_SUCCESS)
	elif GameState.is_run_failed:
		rank_label.text = "FAILED"
		rank_label.add_theme_color_override("font_color", Color(1.0, 0.74, 0.72))
		objective_title.text = "RUN FAILED"
		objective_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.8))
	else:
		rank_label.text = "RANK --"
		rank_label.add_theme_color_override("font_color", TEXT_MUTED)
		objective_title.text = "OBJECTIVE"
		objective_label.add_theme_color_override("font_color", TEXT_PRIMARY)
	_refresh_health_pips()


func set_objective(text: String) -> void:
	objective_text = text
	objective_label.text = text


func show_toast(text: String, duration: float = 2.3) -> void:
	toast_label.text = text
	toast_timer = duration
	toast_card.visible = true
	toast_card.modulate.a = 1.0


func _apply_theme() -> void:
	score_card.add_theme_stylebox_override("panel", _make_panel_style(PANEL_BG, PANEL_BORDER, 22))
	right_card.add_theme_stylebox_override("panel", _make_panel_style(PANEL_BG, PANEL_BORDER, 22))
	objective_card.add_theme_stylebox_override("panel", _make_panel_style(PANEL_BG, PANEL_BORDER, 18))
	toast_card.add_theme_stylebox_override("panel", _make_panel_style(PANEL_BG, TOAST_BORDER, 18, 2, 12))
	_style_caption(score_caption)
	_style_caption(best_label)
	_style_caption(combo_label)
	_style_caption(health_caption)
	_style_caption(core_caption)
	_style_caption(time_caption)
	_style_caption(objective_title)
	_style_metric(score_label, 30, TEXT_ACCENT)
	_style_metric(core_label, 22, TEXT_PRIMARY)
	_style_metric(time_label, 28, TEXT_PRIMARY)
	_style_metric(rank_label, 20, TEXT_MUTED)
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(0.61, 0.86, 1.0))
	objective_label.add_theme_font_size_override("font_size", 16)
	objective_label.add_theme_color_override("font_color", TEXT_PRIMARY)
	toast_label.add_theme_font_size_override("font_size", 16)
	toast_label.add_theme_color_override("font_color", TEXT_PRIMARY)


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
