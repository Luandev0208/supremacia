extends Control

@onready var map_controller: Control = %MapController
@onready var turn_label: Label = %TurnLabel
@onready var selection_label: Label = %SelectionLabel
@onready var place_army_button: Button = %PlaceArmyButton
@onready var attack_button: Button = %AttackButton
@onready var advance_phase_button: Button = %AdvancePhaseButton
@onready var attack_origin_label: Label = %AttackOriginLabel
@onready var combat_result_label: Label = %CombatResultLabel
var game_state := GameState.new()

func _ready() -> void:
	game_state.setup()
	game_state.territory_selected.connect(_on_territory_selected)
	game_state.territory_updated.connect(_on_territory_updated)
	game_state.turn_updated.connect(_refresh_interface)
	game_state.game_finished.connect(_on_game_finished)
	map_controller.build_map(game_state)
	_refresh_interface()

func _refresh_interface() -> void:
	var player := game_state.players[game_state.turn.current_player_index]
	turn_label.text = "Turno: %s  •  Fase: %s  •  Reserva: %d" % [player.display_name, game_state.turn.phase_name(), player.reserve_armies]
	advance_phase_button.text = "Avançar para a próxima fase"
	advance_phase_button.disabled = not game_state.can_advance_phase()
	attack_origin_label.text = "Origem: nenhuma" if game_state.attack_source_id.is_empty() else "Origem: %s" % game_state.territories[game_state.attack_source_id].display_name
	map_controller.show_attack_source(game_state.attack_source_id)
	_refresh_actions()

func _on_territory_selected(territory: TerritoryData) -> void:
	var player := game_state.players[game_state.turn.current_player_index]
	if game_state.turn.current_phase == TurnManager.Phase.ATTACK and territory.owner_id == player.id and territory.armies >= 2:
		game_state.choose_attack_source(territory.id)
	_show_territory_details(territory)
	_refresh_actions()

func _show_territory_details(territory: TerritoryData) -> void:
	var territory_owner := game_state.players[territory.owner_id]
	selection_label.text = "%s\nDono: %s\nExércitos: %d" % [territory.display_name, territory_owner.display_name, territory.armies]

func _on_territory_updated(territory: TerritoryData) -> void:
	map_controller.refresh_territory(territory.id)
	if game_state.selected_territory_id == territory.id:
		_show_territory_details(territory)

func _refresh_actions() -> void:
	var can_place := false
	var can_attack := false
	if not game_state.selected_territory_id.is_empty():
		var selected: TerritoryData = game_state.territories[game_state.selected_territory_id]
		var player := game_state.players[game_state.turn.current_player_index]
		can_place = game_state.turn.current_phase == TurnManager.Phase.REINFORCEMENT and selected.owner_id == player.id and player.reserve_armies > 0
		can_attack = game_state.can_attack(game_state.attack_source_id, selected.id)
	place_army_button.disabled = not can_place
	attack_button.disabled = not can_attack

func _on_place_army_pressed() -> void:
	game_state.place_army(game_state.selected_territory_id)

func _on_attack_pressed() -> void:
	var result := game_state.attack(game_state.attack_source_id, game_state.selected_territory_id)
	if not result.success:
		return
	combat_result_label.text = "Ataque: %s  |  Defesa: %s\nPerdas: atacante %d, defensor %d" % [
		_format_dice(result.attacker_dice),
		_format_dice(result.defender_dice),
		result.attacker_losses,
		result.defender_losses
	]
	if result.conquered:
		combat_result_label.text += "\nTerritório conquistado! %d exército(s) avançaram." % result.moved_armies
	if game_state.winner_id >= 0:
		combat_result_label.text += "\nVITÓRIA DE %s!" % game_state.players[game_state.winner_id].display_name.to_upper()
	_refresh_interface()

func _format_dice(values: Array) -> String:
	var labels: PackedStringArray = []
	for value in values:
		labels.append(str(value))
	return "[" + ", ".join(labels) + "]"

func _on_game_finished(winner: PlayerData) -> void:
	combat_result_label.text = "VITÓRIA DE %s!" % winner.display_name.to_upper()
	attack_button.disabled = true
	place_army_button.disabled = true

func _on_advance_phase_pressed() -> void:
	game_state.advance_phase()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
