class_name TerritoryView
extends Area2D

signal pressed(territory_id: String)
var territory: TerritoryData
var owner_color: Color
var selected := false
var attack_source := false
var movement_source := false
@onready var shape: Polygon2D = $Shape
@onready var border: Line2D = $Border
@onready var collision: CollisionPolygon2D = $Collision
@onready var name_label: Label = $NameLabel
@onready var army_label: Label = $ArmyLabel

func setup(data: TerritoryData, color: Color, points: PackedVector2Array) -> void:
	territory = data
	owner_color = color
	shape.polygon = points
	collision.polygon = points
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
		border.default_color = Color.WHITE
	elif attack_source:
		border.default_color = Color("#f5c451")
	elif movement_source:
		border.default_color = Color("#5bd6a2")
	else:
		border.default_color = Color("#253249")

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pressed.emit(territory.id)

func _on_mouse_entered() -> void:
	if not selected:
		shape.color = owner_color.lightened(0.1)

func _on_mouse_exited() -> void:
	_refresh_color()
