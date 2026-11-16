extends Control

@onready var map_controller: Control = %MapController
@onready var turn_label: Label = %TurnLabel
@onready var selection_label: Label = %SelectionLabel
var game_state := GameState.new()

func _ready() -> void:
	game_state.setup()
	game_state.territory_selected.connect(_on_territory_selected)
	map_controller.build_map(game_state)
	var player := game_state.players[game_state.turn.current_player_index]
	turn_label.text = "Turno: %s  •  Fase: %s" % [player.display_name, game_state.turn.phase_name()]

func _on_territory_selected(territory: TerritoryData) -> void:
	var owner := game_state.players[territory.owner_id]
	selection_label.text = "%s\nDono: %s\nExércitos: %d" % [territory.display_name, owner.display_name, territory.armies]

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
