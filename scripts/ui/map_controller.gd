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
var views: Dictionary[String, TerritoryView] = {}
const BOARD_SIZE := Vector2(768, 476)
var board := Node2D.new()

func _ready() -> void:
	add_child(board)
	resized.connect(_fit_board)
	_fit_board()

func _fit_board() -> void:
	var board_scale := minf(size.x / BOARD_SIZE.x, size.y / BOARD_SIZE.y)
	board.scale = Vector2.ONE * maxf(0.01, board_scale)
	board.position = (size - BOARD_SIZE * board.scale) / 2.0
	queue_redraw()


func _draw() -> void:
	# Mar em camadas, sem o antigo fundo circular de planeta.
	var ocean_top := Color("#0d6684")
	var ocean_bottom := Color("#07364f")
	for band in 10:
		var band_height := size.y / 10.0
		draw_rect(Rect2(0, band * band_height, size.x, band_height + 1.0), ocean_top.lerp(ocean_bottom, band / 9.0))
	for x in range(20, int(size.x), 48):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.5, 0.82, 0.9, 0.07), 1.0)
	for y in range(20, int(size.y), 48):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.5, 0.82, 0.9, 0.07), 1.0)
	draw_set_transform(board.position, 0, board.scale)
	# Massas continentais unem visualmente os territórios e aproximam o mapa da referência.
	_draw_landmass(PackedVector2Array([Vector2(8,38),Vector2(62,20),Vector2(145,24),Vector2(232,12),Vector2(253,64),Vector2(223,135),Vector2(160,190),Vector2(83,220),Vector2(24,175),Vector2(5,105)]), Color("#d98a28"))
	_draw_landmass(PackedVector2Array([Vector2(125,205),Vector2(210,215),Vector2(255,270),Vector2(230,365),Vector2(205,428),Vector2(158,382),Vector2(135,305)]), Color("#31a84b"))
	_draw_landmass(PackedVector2Array([Vector2(268,40),Vector2(348,28),Vector2(443,42),Vector2(515,88),Vector2(476,168),Vector2(387,178),Vector2(294,166),Vector2(271,108)]), Color("#428fd4"))
	_draw_landmass(PackedVector2Array([Vector2(303,183),Vector2(413,175),Vector2(483,220),Vector2(480,322),Vector2(436,424),Vector2(358,415),Vector2(329,327)]), Color("#7b56ae"))
	_draw_landmass(PackedVector2Array([Vector2(445,25),Vector2(564,8),Vector2(702,36),Vector2(754,105),Vector2(740,225),Vector2(682,302),Vector2(582,306),Vector2(505,247),Vector2(475,160)]), Color("#e2b51f"))
	_draw_landmass(PackedVector2Array([Vector2(540,310),Vector2(650,301),Vector2(751,328),Vector2(758,445),Vector2(666,468),Vector2(575,420)]), Color("#df3d8e"))
	if game_state == null:
		return
	var drawn_connections: Dictionary = {}
	for territory: TerritoryData in game_state.territories.values():
		for neighbor_id: String in territory.neighbor_ids:
			var key := territory.id + ":" + neighbor_id if territory.id < neighbor_id else neighbor_id + ":" + territory.id
			if drawn_connections.has(key) or not territory_layout.has(neighbor_id):
				continue
			drawn_connections[key] = true
			draw_dashed_line(_territory_center(territory.id), _territory_center(neighbor_id), Color(0.78, 0.9, 0.94, 0.5), 1.2, 5.0)

func _draw_landmass(points: PackedVector2Array, continent_color: Color) -> void:
	var fill := continent_color.darkened(0.28)
	fill.a = 0.82
	draw_colored_polygon(points, fill)
	var border_points := points + PackedVector2Array([points[0]])
	draw_polyline(border_points, continent_color.lightened(0.22), 2.0, true)

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	var point: Vector2 = board.transform.affine_inverse() * event.position
	var ids := views.keys()
	ids.reverse()
	for territory_id: String in ids:
		if views[territory_id].contains_point(point):
			game_state.select_territory(territory_id)
			accept_event()
			return

func build_map(state: GameState) -> void:
	game_state = state
	for view: TerritoryView in views.values():
		board.remove_child(view)
		view.queue_free()
	views.clear()
	for territory_id: String in territory_layout:
		var view: TerritoryView = TERRITORY_SCENE.instantiate()
		var territory: TerritoryData = game_state.territories[territory_id]
		board.add_child(view)
		view.position = territory_layout[territory_id][0]
		view.setup(territory, game_state.players[territory.owner_id].color, _make_polygon(territory_layout[territory_id][1], territory_id))
		views[territory_id] = view
	queue_redraw()

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

func show_selection(territory_id: String) -> void:
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
