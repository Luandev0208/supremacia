extends Control

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	var ocean_top := Color("#0c5670")
	var ocean_bottom := Color("#042a3d")
	for band in 12:
		var band_height := size.y / 12.0
		draw_rect(Rect2(0, band * band_height, size.x, band_height + 1.0), ocean_top.lerp(ocean_bottom, band / 11.0))
	for x in range(0, int(size.x), 64):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.55, 0.84, 0.9, 0.055), 1.0)
	for y in range(0, int(size.y), 64):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.55, 0.84, 0.9, 0.055), 1.0)
	var scale_factor := minf(size.x / 1152.0, size.y / 648.0)
	var center := size / 2.0
	_draw_shape(center + Vector2(-420, -170) * scale_factor, PackedVector2Array([Vector2(0,40),Vector2(90,0),Vector2(180,24),Vector2(215,110),Vector2(145,150),Vector2(40,130)]), Color(0.93,0.56,0.16,0.16), scale_factor)
	_draw_shape(center + Vector2(-360, 30) * scale_factor, PackedVector2Array([Vector2(0,0),Vector2(110,12),Vector2(160,90),Vector2(115,215),Vector2(55,165)]), Color(0.2,0.72,0.36,0.15), scale_factor)
	_draw_shape(center + Vector2(230, -150) * scale_factor, PackedVector2Array([Vector2(0,25),Vector2(160,0),Vector2(270,55),Vector2(240,160),Vector2(90,175),Vector2(15,100)]), Color(0.96,0.73,0.15,0.14), scale_factor)
	_draw_shape(center + Vector2(350, 120) * scale_factor, PackedVector2Array([Vector2(0,25),Vector2(100,0),Vector2(170,48),Vector2(145,130),Vector2(35,120)]), Color(0.95,0.25,0.55,0.14), scale_factor)

func _draw_shape(origin: Vector2, points: PackedVector2Array, color: Color, scale_factor: float) -> void:
	var transformed := PackedVector2Array()
	for point in points:
		transformed.append(origin + point * scale_factor)
	draw_colored_polygon(transformed, color)
	draw_polyline(transformed + PackedVector2Array([transformed[0]]), Color(color.r, color.g, color.b, 0.28), 2.0, true)
