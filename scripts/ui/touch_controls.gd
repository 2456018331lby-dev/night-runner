extends CanvasLayer

const PAD_BG := Color(0.04, 0.07, 0.13, 0.72)
const PAD_BORDER := Color(0.23, 0.75, 1.0, 0.36)
const LABEL_COLOR := Color(0.95, 0.98, 1.0)

@onready var left_pad: PanelContainer = $Controls/LeftPad
@onready var action_pad: PanelContainer = $Controls/ActionPad
@onready var left_button: Button = $Controls/LeftPad/Margin/MoveRow/MoveLeft
@onready var right_button: Button = $Controls/LeftPad/Margin/MoveRow/MoveRight
@onready var jump_button: Button = $Controls/ActionPad/Margin/VBox/Jump
@onready var attack_button: Button = $Controls/ActionPad/Margin/VBox/ActionRow/Attack
@onready var dash_button: Button = $Controls/ActionPad/Margin/VBox/ActionRow/Dash


func _ready() -> void:
	_apply_theme()
	_wire_move_button(left_button, -1.0)
	_wire_move_button(right_button, 1.0)
	_wire_action_button(jump_button, "jump")
	_wire_action_button(attack_button, "attack")
	_wire_action_button(dash_button, "dash")
	call_deferred("_finalize_button_pivots")


func configure(visible_on_platform: bool) -> void:
	visible = visible_on_platform


func _release_move(expected: float) -> void:
	if is_equal_approx(InputRouter.move_axis, expected):
		InputRouter.set_move_axis(0.0)


func _apply_theme() -> void:
	left_pad.add_theme_stylebox_override("panel", _make_panel_style(PAD_BG, PAD_BORDER, 32))
	action_pad.add_theme_stylebox_override("panel", _make_panel_style(PAD_BG, PAD_BORDER, 32))
	_style_button(left_button, Color(0.12, 0.24, 0.39, 0.92), Color(0.38, 0.85, 1.0, 0.82), 28, 17)
	_style_button(right_button, Color(0.12, 0.24, 0.39, 0.92), Color(0.38, 0.85, 1.0, 0.82), 28, 17)
	_style_button(jump_button, Color(0.12, 0.35, 0.55, 0.94), Color(0.47, 0.91, 1.0, 0.9), 26, 18)
	_style_button(attack_button, Color(0.57, 0.18, 0.22, 0.95), Color(1.0, 0.55, 0.42, 0.92), 30, 18)
	_style_button(dash_button, Color(0.48, 0.34, 0.08, 0.95), Color(1.0, 0.82, 0.35, 0.9), 30, 17)


func _wire_move_button(button: Button, axis: float) -> void:
	button.button_down.connect(func() -> void:
		InputRouter.set_move_axis(axis)
		_set_button_visual(button, true)
	)
	button.button_up.connect(func() -> void:
		_release_move(axis)
		_set_button_visual(button, false)
	)


func _wire_action_button(button: Button, action_name: String) -> void:
	button.button_down.connect(func() -> void:
		InputRouter.press_action(action_name)
		_set_button_visual(button, true)
	)
	button.button_up.connect(func() -> void:
		_set_button_visual(button, false)
	)


func _style_button(button: Button, fill: Color, border: Color, radius: int, font_size: int) -> void:
	button.add_theme_stylebox_override("normal", _make_panel_style(fill, border, radius))
	button.add_theme_stylebox_override("hover", _make_panel_style(fill.lightened(0.08), border.lightened(0.08), radius))
	button.add_theme_stylebox_override("pressed", _make_panel_style(fill.darkened(0.12), border.lightened(0.12), radius))
	button.add_theme_stylebox_override("focus", _make_panel_style(fill.lightened(0.08), border.lightened(0.08), radius))
	button.add_theme_color_override("font_color", LABEL_COLOR)
	button.add_theme_color_override("font_hover_color", LABEL_COLOR)
	button.add_theme_color_override("font_pressed_color", LABEL_COLOR)
	button.add_theme_font_size_override("font_size", font_size)
	button.modulate = Color(1.0, 1.0, 1.0, 0.94)


func _finalize_button_pivots() -> void:
	for button in [left_button, right_button, jump_button, attack_button, dash_button]:
		button.pivot_offset = button.size * 0.5
		_set_button_visual(button, false)


func _set_button_visual(button: Button, pressed: bool) -> void:
	button.scale = Vector2.ONE * (0.94 if pressed else 1.0)
	button.modulate = Color(1.0, 1.0, 1.0, 1.0 if pressed else 0.94)


func _make_panel_style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.24)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 6)
	return style
