extends Control

@onready var map_controller: Control = %MapController
@onready var turn_label: Label = %TurnLabel
@onready var selection_label: Label = %SelectionLabel
@onready var place_army_button: Button = %PlaceArmyButton
@onready var advance_phase_button: Button = %AdvancePhaseButton
var game_state := GameState.new()

func _ready() -> void:
	game_state.setup()
	game_state.territory_selected.connect(_on_territory_selected)
	game_state.territory_updated.connect(_on_territory_updated)
	game_state.turn_updated.connect(_refresh_interface)
	map_controller.build_map(game_state)
	_refresh_interface()

func _refresh_interface() -> void:
	var player := game_state.players[game_state.turn.current_player_index]
	turn_label.text = "Turno: %s  •  Fase: %s  •  Reserva: %d" % [player.display_name, game_state.turn.phase_name(), player.reserve_armies]
	advance_phase_button.text = "Avançar para a próxima fase"
	advance_phase_button.disabled = not game_state.can_advance_phase()
	_refresh_actions()

func _on_territory_selected(territory: TerritoryData) -> void:
	var owner := game_state.players[territory.owner_id]
	selection_label.text = "%s\nDono: %s\nExércitos: %d" % [territory.display_name, owner.display_name, territory.armies]
	_refresh_actions()

func _on_territory_updated(territory: TerritoryData) -> void:
	map_controller.refresh_territory(territory.id)
	_on_territory_selected(territory)

func _refresh_actions() -> void:
	var can_place := false
	if not game_state.selected_territory_id.is_empty():
		var selected: TerritoryData = game_state.territories[game_state.selected_territory_id]
		var player := game_state.players[game_state.turn.current_player_index]
		can_place = game_state.turn.current_phase == TurnManager.Phase.REINFORCEMENT and selected.owner_id == player.id and player.reserve_armies > 0
	place_army_button.disabled = not can_place

func _on_place_army_pressed() -> void:
	game_state.place_army(game_state.selected_territory_id)

func _on_advance_phase_pressed() -> void:
	game_state.advance_phase()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
