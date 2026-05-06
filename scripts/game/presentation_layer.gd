extends Node2D

const SKYLINE_FAR := Color(0.07, 0.11, 0.2, 0.96)
const SKYLINE_NEAR := Color(0.09, 0.16, 0.28, 0.98)
const WINDOW_CYAN := Color(0.38, 0.9, 1.0, 0.3)
const WINDOW_GOLD := Color(1.0, 0.73, 0.38, 0.24)
const FOG_COLOR := Color(0.22, 0.42, 0.58, 0.12)
const BEAM_COLOR := Color(0.34, 0.82, 1.0, 0.08)
const RAIL_CYAN := Color(0.32, 0.82, 1.0, 0.78)
const RAIL_ORANGE := Color(1.0, 0.6, 0.28, 0.72)

var sweep_time: float = 0.0
var fog_nodes: Array[Polygon2D] = []
var fog_offsets: Array[Vector2] = []
var beam_nodes: Array[Polygon2D] = []


func _ready() -> void:
	z_as_relative = false
	_build_glows()
	_build_city_layer(
		[
			{"x": 130.0, "width": 120.0, "height": 150.0},
			{"x": 280.0, "width": 90.0, "height": 215.0},
			{"x": 400.0, "width": 150.0, "height": 178.0},
			{"x": 590.0, "width": 110.0, "height": 244.0},
			{"x": 760.0, "width": 168.0, "height": 194.0},
			{"x": 970.0, "width": 134.0, "height": 264.0},
			{"x": 1160.0, "width": 120.0, "height": 186.0},
			{"x": 1310.0, "width": 172.0, "height": 230.0},
			{"x": 1535.0, "width": 118.0, "height": 198.0},
			{"x": 1710.0, "width": 142.0, "height": 250.0},
			{"x": 1890.0, "width": 116.0, "height": 188.0},
		],
		SKYLINE_FAR,
		564.0,
		-16,
		false
	)
	_build_city_layer(
		[
			{"x": 180.0, "width": 156.0, "height": 122.0},
			{"x": 420.0, "width": 190.0, "height": 146.0},
			{"x": 690.0, "width": 168.0, "height": 164.0},
			{"x": 950.0, "width": 205.0, "height": 134.0},
			{"x": 1235.0, "width": 180.0, "height": 176.0},
			{"x": 1495.0, "width": 192.0, "height": 144.0},
			{"x": 1765.0, "width": 210.0, "height": 168.0},
		],
		SKYLINE_NEAR,
		618.0,
		-10,
		true
	)
	_build_beams()
	_build_fog()
	_build_neon_rails()


func _process(delta: float) -> void:
	sweep_time += delta
	for index in fog_nodes.size():
		var fog := fog_nodes[index]
		var offset := fog_offsets[index]
		fog.position = offset + Vector2(sin(sweep_time * (0.22 + index * 0.07)) * (26.0 + index * 18.0), cos(sweep_time * (0.16 + index * 0.05)) * 8.0)
		fog.modulate.a = 0.62 + sin(sweep_time * (0.5 + index * 0.08)) * 0.16
	for index in beam_nodes.size():
		beam_nodes[index].modulate.a = 0.34 + sin(sweep_time * (1.4 + index * 0.33)) * 0.18


func _build_glows() -> void:
	var moon_halo := _make_ellipse(Vector2(1090.0, 112.0), Vector2(148.0, 148.0), Color(1.0, 0.83, 0.38, 0.12), -18)
	add_child(moon_halo)
	var skyline_glow := _make_ellipse(Vector2(1220.0, 265.0), Vector2(720.0, 220.0), Color(0.1, 0.55, 0.92, 0.08), -19)
	add_child(skyline_glow)
	var chase_glow := _make_ellipse(Vector2(1630.0, 348.0), Vector2(360.0, 120.0), Color(1.0, 0.48, 0.22, 0.09), -18)
	add_child(chase_glow)


func _build_city_layer(specs: Array, body_color: Color, baseline_y: float, z_order: int, warm_windows: bool) -> void:
	for spec: Dictionary in specs:
		var width: float = float(spec["width"])
		var height: float = float(spec["height"])
		var pos_x: float = float(spec["x"])
		var body := _make_rect(Vector2(pos_x, baseline_y - height * 0.5), Vector2(width, height), body_color, z_order)
		add_child(body)
		var trim_color := WINDOW_GOLD if warm_windows else WINDOW_CYAN
		var trim := _make_rect(Vector2(pos_x, baseline_y - height + 8.0), Vector2(width * 0.86, 4.0), trim_color, z_order + 1)
		add_child(trim)

		var columns: int = max(2, int(width / 36.0))
		var rows: int = max(2, int(height / 44.0))
		for row in rows:
			for column in columns:
				if (row + column + int(pos_x / 40.0)) % 2 == 0:
					continue
				var window_width := 10.0
				var window_height := 7.0
				var offset_x: float = -width * 0.5 + 20.0 + column * ((width - 40.0) / max(1, columns - 1))
				var offset_y: float = -height * 0.5 + 24.0 + row * ((height - 46.0) / max(1, rows - 1))
				var window_color := WINDOW_GOLD if warm_windows and row % 2 == 0 else WINDOW_CYAN
				var window := _make_rect(Vector2(pos_x + offset_x, baseline_y - height * 0.5 + offset_y), Vector2(window_width, window_height), window_color, z_order + 1)
				add_child(window)


func _build_beams() -> void:
	var beam_a := Polygon2D.new()
	beam_a.polygon = PackedVector2Array([
		Vector2(248.0, 642.0),
		Vector2(382.0, 138.0),
		Vector2(462.0, 138.0),
		Vector2(320.0, 642.0),
	])
	beam_a.color = BEAM_COLOR
	beam_a.z_index = -12
	add_child(beam_a)
	beam_nodes.append(beam_a)

	var beam_b := Polygon2D.new()
	beam_b.polygon = PackedVector2Array([
		Vector2(1494.0, 642.0),
		Vector2(1604.0, 184.0),
		Vector2(1690.0, 184.0),
		Vector2(1580.0, 642.0),
	])
	beam_b.color = BEAM_COLOR
	beam_b.z_index = -12
	add_child(beam_b)
	beam_nodes.append(beam_b)


func _build_fog() -> void:
	var fog_a := _make_ellipse(Vector2(610.0, 566.0), Vector2(390.0, 78.0), FOG_COLOR, -9)
	add_child(fog_a)
	fog_nodes.append(fog_a)
	fog_offsets.append(fog_a.position)

	var fog_b := _make_ellipse(Vector2(1260.0, 512.0), Vector2(450.0, 94.0), FOG_COLOR, -9)
	add_child(fog_b)
	fog_nodes.append(fog_b)
	fog_offsets.append(fog_b.position)

	var fog_c := _make_ellipse(Vector2(1750.0, 440.0), Vector2(320.0, 68.0), FOG_COLOR, -9)
	add_child(fog_c)
	fog_nodes.append(fog_c)
	fog_offsets.append(fog_c.position)


func _build_neon_rails() -> void:
	for strip in [
		{"position": Vector2(790.0, 632.0), "size": Vector2(1780.0, 6.0), "color": RAIL_CYAN},
		{"position": Vector2(690.0, 408.0), "size": Vector2(250.0, 5.0), "color": RAIL_ORANGE},
		{"position": Vector2(1124.0, 322.0), "size": Vector2(228.0, 5.0), "color": RAIL_CYAN},
		{"position": Vector2(1500.0, 222.0), "size": Vector2(228.0, 5.0), "color": RAIL_ORANGE},
	]:
		var position: Vector2 = strip["position"]
		var size: Vector2 = strip["size"]
		var color: Color = strip["color"]
		var rail := _make_rect(position, size, color, -1)
		add_child(rail)
		var glow := _make_rect(position, Vector2(size.x, size.y * 2.4), Color(color.r, color.g, color.b, 0.18), -2)
		add_child(glow)


func _make_rect(center: Vector2, size: Vector2, color: Color, z_order: int) -> Polygon2D:
	var polygon := Polygon2D.new()
	var half := size * 0.5
	polygon.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	polygon.position = center
	polygon.color = color
	polygon.z_index = z_order
	return polygon


func _make_ellipse(center: Vector2, radius: Vector2, color: Color, z_order: int) -> Polygon2D:
	var polygon := Polygon2D.new()
	var points := PackedVector2Array()
	for step in 24:
		var angle := TAU * float(step) / 24.0
		points.append(Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	polygon.polygon = points
	polygon.position = center
	polygon.color = color
	polygon.z_index = z_order
	return polygon
