extends Control

const TERRITORY_SCENE := preload("res://scenes/territory.tscn")
var territory_layout: Dictionary = {
	"alaska": [Vector2(18, 48), Vector2(55, 36)],
	"mackenzie": [Vector2(78, 43), Vector2(64, 40)],
	"groenlandia": [Vector2(160, 23), Vector2(67, 44)],
	"vancouver": [Vector2(43, 89), Vector2(59, 39)],
	"ottawa": [Vector2(106, 87), Vector2(57, 41)],
	"labrador": [Vector2(169, 79), Vector2(51, 39)],
	"california": [Vector2(46, 134), Vector2(57, 43)],
	"nova_york": [Vector2(108, 131), Vector2(58, 42)],
	"mexico": [Vector2(77, 179), Vector2(57, 40)],
	"colombia": [Vector2(139, 220), Vector2(56, 41)],
	"brasil": [Vector2(177, 254), Vector2(70, 57)],
	"chile": [Vector2(142, 280), Vector2(38, 91)],
	"argentina": [Vector2(174, 326), Vector2(50, 82)],
	"islandia": [Vector2(276, 52), Vector2(40, 29)],
	"inglaterra": [Vector2(290, 94), Vector2(40, 36)],
	"suecia": [Vector2(343, 52), Vector2(47, 50)],
	"alemanha": [Vector2(338, 108), Vector2(47, 39)],
	"polonia": [Vector2(389, 105), Vector2(50, 40)],
	"portugal": [Vector2(290, 141), Vector2(47, 36)],
	"moscou": [Vector2(430, 53), Vector2(72, 77)],
	"argelia_nigeria": [Vector2(318, 199), Vector2(77, 62)],
	"egito": [Vector2(400, 188), Vector2(50, 43)],
	"sudao": [Vector2(399, 235), Vector2(62, 66)],
	"congo": [Vector2(353, 270), Vector2(52, 56)],
	"africa_sul": [Vector2(368, 335), Vector2(60, 76)],
	"madagascar": [Vector2(445, 346), Vector2(37, 62)],
	"oriente_medio": [Vector2(455, 190), Vector2(62, 56)],
	"aral": [Vector2(505, 139), Vector2(50, 46)],
	"omsk": [Vector2(520, 80), Vector2(47, 46)],
	"dudinka": [Vector2(529, 29), Vector2(57, 46)],
	"siberia": [Vector2(590, 43), Vector2(57, 47)],
	"tchita": [Vector2(585, 99), Vector2(50, 44)],
	"mongolia": [Vector2(570, 145), Vector2(57, 46)],
	"vladivostok": [Vector2(650, 69), Vector2(77, 57)],
	"china": [Vector2(620, 189), Vector2(72, 67)],
	"india": [Vector2(550, 220), Vector2(57, 72)],
	"vietna": [Vector2(636, 261), Vector2(42, 57)],
	"japao": [Vector2(711, 184), Vector2(30, 47)],
	"sumatra": [Vector2(555, 335), Vector2(37, 52)],
	"borneu": [Vector2(620, 320), Vector2(42, 44)],
	"nova_guine": [Vector2(684, 335), Vector2(57, 42)],
	"australia": [Vector2(640, 381), Vector2(82, 72)]
}
var game_state: GameState
var views: Dictionary = {}

func _draw() -> void:
	var globe: PackedVector2Array = []
	for index in 64:
		var angle := TAU * index / 64.0
		globe.append(Vector2(380.0 + cos(angle) * 374.0, 236.0 + sin(angle) * 226.0))
	draw_colored_polygon(globe, Color("#e9ecef"))
	if game_state == null:
		return
	var drawn_connections: Dictionary = {}
	for territory: TerritoryData in game_state.territories.values():
		for neighbor_id: String in territory.neighbor_ids:
			var key := territory.id + ":" + neighbor_id if territory.id < neighbor_id else neighbor_id + ":" + territory.id
			if drawn_connections.has(key) or not territory_layout.has(neighbor_id):
				continue
			drawn_connections[key] = true
			draw_dashed_line(_territory_center(territory.id), _territory_center(neighbor_id), Color(0.32, 0.36, 0.4, 0.38), 1.0, 5.0)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(22, 32), "AMÉRICA DO NORTE  +5", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#d97706"))
	draw_string(font, Vector2(140, 445), "AMÉRICA DO SUL  +2", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#22a447"))
	draw_string(font, Vector2(285, 32), "EUROPA  +5", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#2878c8"))
	draw_string(font, Vector2(320, 190), "ÁFRICA  +3", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#6f4cab"))
	draw_string(font, Vector2(535, 22), "ÁSIA  +7", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#d6a600"))
	draw_string(font, Vector2(635, 465), "OCEANIA  +2", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#e33188"))

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	for territory_id: String in territory_layout:
		var territory_position: Vector2 = territory_layout[territory_id][0]
		var territory_polygon := _make_polygon(territory_layout[territory_id][1], territory_id)
		if Geometry2D.is_point_in_polygon(event.position - territory_position, territory_polygon):
			_on_territory_pressed(territory_id)
			accept_event()
			return

func build_map(state: GameState) -> void:
	game_state = state
	views.clear()
	queue_redraw()
	for territory_id: String in territory_layout:
		var view := TERRITORY_SCENE.instantiate()
		var territory: TerritoryData = game_state.territories[territory_id]
		add_child(view)
		view.position = territory_layout[territory_id][0]
		view.setup(territory, game_state.players[territory.owner_id].color, _make_polygon(territory_layout[territory_id][1], territory_id))
		view.pressed.connect(_on_territory_pressed)
		views[territory_id] = view

func _make_polygon(size: Vector2, territory_id: String) -> PackedVector2Array:
	var variation: int = absi(territory_id.hash()) % 3
	var top_left: float = 0.10 + variation * 0.03
	return PackedVector2Array([
		Vector2(0, size.y * 0.24),
		Vector2(size.x * top_left, size.y * 0.05),
		Vector2(size.x * 0.72, 0),
		Vector2(size.x, size.y * (0.30 + variation * 0.04)),
		Vector2(size.x * 0.84, size.y),
		Vector2(size.x * 0.18, size.y * 0.92)
	])

func _territory_center(territory_id: String) -> Vector2:
	var territory_position: Vector2 = territory_layout[territory_id][0]
	var territory_size: Vector2 = territory_layout[territory_id][1]
	return territory_position + territory_size / 2.0

func _on_territory_pressed(territory_id: String) -> void:
	if game_state.select_territory(territory_id):
		for id: String in views:
			views[id].set_selected(id == territory_id)

func refresh_territory(territory_id: String) -> void:
	if views.has(territory_id):
		var territory: TerritoryData = game_state.territories[territory_id]
		views[territory_id].set_owner_color(game_state.players[territory.owner_id].color)
		views[territory_id].refresh()

func show_attack_source(territory_id: String) -> void:
	for id: String in views:
		views[id].set_attack_source(id == territory_id)

func show_movement_source(territory_id: String) -> void:
	for id: String in views:
		views[id].set_movement_source(id == territory_id)
