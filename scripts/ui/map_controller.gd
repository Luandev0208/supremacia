extends Control

const TERRITORY_SCENE := preload("res://scenes/territory.tscn")
const LAYOUT := {
	"aurora": [Vector2(55, 60), PackedVector2Array([Vector2(0,25),Vector2(45,0),Vector2(112,16),Vector2(100,83),Vector2(32,92)])],
	"brisa": [Vector2(180, 60), PackedVector2Array([Vector2(0,17),Vector2(70,0),Vector2(121,34),Vector2(98,91),Vector2(22,83)])],
	"cedro": [Vector2(60, 180), PackedVector2Array([Vector2(0,20),Vector2(73,0),Vector2(112,37),Vector2(94,97),Vector2(18,84)])],
	"delta": [Vector2(320, 85), PackedVector2Array([Vector2(0,18),Vector2(68,0),Vector2(116,42),Vector2(91,101),Vector2(17,84)])],
	"estrela": [Vector2(185, 220), PackedVector2Array([Vector2(0,31),Vector2(55,0),Vector2(119,19),Vector2(107,91),Vector2(30,104)])],
	"farol": [Vector2(330, 220), PackedVector2Array([Vector2(0,18),Vector2(66,0),Vector2(119,34),Vector2(104,98),Vector2(23,89)])],
	"ilha": [Vector2(120, 355), PackedVector2Array([Vector2(0,27),Vector2(49,0),Vector2(103,18),Vector2(92,76),Vector2(27,88)])],
	"jardim": [Vector2(280, 355), PackedVector2Array([Vector2(0,18),Vector2(62,0),Vector2(111,31),Vector2(94,87),Vector2(20,80)])]
}
var game_state: GameState
var views: Dictionary = {}

func build_map(state: GameState) -> void:
	game_state = state
	views.clear()
	for territory_id: String in LAYOUT:
		var view := TERRITORY_SCENE.instantiate()
		var territory: TerritoryData = game_state.territories[territory_id]
		add_child(view)
		view.position = LAYOUT[territory_id][0]
		view.setup(territory, game_state.players[territory.owner_id].color, LAYOUT[territory_id][1])
		view.pressed.connect(_on_territory_pressed)
		views[territory_id] = view

func _on_territory_pressed(territory_id: String) -> void:
	if game_state.select_territory(territory_id):
		for id: String in views:
			views[id].set_selected(id == territory_id)

func refresh_territory(territory_id: String) -> void:
	if views.has(territory_id):
		views[territory_id].refresh()
