class_name TerritoryView
extends Node2D

var territory: TerritoryData
var owner_color: Color
var selected := false
var attack_source := false
var movement_source := false
@onready var shape: Polygon2D = $Shape
@onready var shadow: Polygon2D = $Shadow
@onready var border: Line2D = $Border
@onready var name_label: Label = $NameLabel
@onready var army_label: Label = $ArmyLabel
@onready var army_badge: Polygon2D = $ArmyBadge

func setup(data: TerritoryData, color: Color, points: PackedVector2Array) -> void:
	territory = data
	owner_color = color
	shadow.polygon = points
	shape.polygon = points
	border.points = points + PackedVector2Array([points[0]])
	name_label.text = data.display_name
	army_label.text = str(data.armies)
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	var center := bounds.get_center()
	name_label.offset_left = center.x - 42.0
	name_label.offset_top = center.y - 14.0
	name_label.offset_right = center.x + 42.0
	name_label.offset_bottom = center.y + 1.0
	army_label.offset_left = center.x - 18.0
	army_label.offset_top = center.y + 1.0
	army_label.offset_right = center.x + 18.0
	army_label.offset_bottom = center.y + 20.0
	var badge_points: PackedVector2Array = []
	for index in 16:
		var angle := TAU * index / 16.0
		badge_points.append(Vector2(cos(angle), sin(angle)) * 9.5)
	army_badge.polygon = badge_points
	army_badge.position = center + Vector2(0, 9)
	name_label.add_theme_font_size_override("font_size", 8 if data.display_name.length() > 11 else 10)
	army_label.add_theme_font_size_override("font_size", 13)
	_refresh_color()

func refresh() -> void:
	army_label.text = str(territory.armies)
	_refresh_color()

func set_selected(value: bool) -> void:
	selected = value
	_refresh_color()

func set_attack_source(value: bool) -> void:
	attack_source = value
	_refresh_color()

func set_movement_source(value: bool) -> void:
	movement_source = value
	_refresh_color()

func set_owner_color(color: Color) -> void:
	owner_color = color
	_refresh_color()

func _refresh_color() -> void:
	shape.color = owner_color.lightened(0.18) if selected else owner_color
	border.width = 3.5 if selected or attack_source or movement_source else 1.5
	if selected:
		border.default_color = Color("#ffd166")
	elif attack_source:
		border.default_color = Color("#f5c451")
	elif movement_source:
		border.default_color = Color("#5bd6a2")
	else:
		border.default_color = Color(0.78, 0.91, 0.94, 0.78)
func contains_point(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point - position, shape.polygon)
