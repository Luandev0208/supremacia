extends Control

@onready var map_controller: Control = %MapController
@onready var turn_label: Label = %TurnLabel
@onready var selection_label: Label = %SelectionLabel
@onready var place_army_button: Button = %PlaceArmyButton
@onready var attack_button: Button = %AttackButton
@onready var advance_phase_button: Button = %AdvancePhaseButton
@onready var attack_origin_label: Label = %AttackOriginLabel
@onready var combat_result_label: Label = %CombatResultLabel
@onready var movement_source_label: Label = %MovementSourceLabel
@onready var movement_amount: SpinBox = %MovementAmount
@onready var move_armies_button: Button = %MoveArmiesButton
@onready var movement_status_label: Label = %MovementStatusLabel
@onready var phase_hint_label: Label = %PhaseHintLabel
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
	movement_source_label.text = "Origem: nenhuma" if game_state.movement_source_id.is_empty() else "Origem: %s" % game_state.territories[game_state.movement_source_id].display_name
	map_controller.show_attack_source(game_state.attack_source_id)
	map_controller.show_movement_source(game_state.movement_source_id)
	_update_phase_controls()
	_refresh_actions()

func _update_phase_controls() -> void:
	var phase := game_state.turn.current_phase
	var reinforcement_phase := phase == TurnManager.Phase.REINFORCEMENT
	var attack_phase := phase == TurnManager.Phase.ATTACK
	var movement_phase := phase == TurnManager.Phase.MOVEMENT
	place_army_button.visible = reinforcement_phase
	attack_origin_label.visible = attack_phase
	attack_button.visible = attack_phase
	combat_result_label.visible = attack_phase or game_state.winner_id >= 0
	movement_source_label.visible = movement_phase
	movement_amount.visible = movement_phase
	move_armies_button.visible = movement_phase
	movement_status_label.visible = movement_phase
	if movement_phase:
		movement_status_label.text = "Remanejamento realizado neste turno." if game_state.movement_used else "Um remanejamento é permitido por turno."
	if reinforcement_phase:
		phase_hint_label.text = "Selecione um território próprio e posicione toda a reserva."
	elif attack_phase:
		phase_hint_label.text = "Selecione uma origem com dois ou mais exércitos e depois um vizinho inimigo."
	else:
		phase_hint_label.text = "Escolha a origem, o destino próprio conectado e a quantidade a mover."

func _on_territory_selected(territory: TerritoryData) -> void:
	var player := game_state.players[game_state.turn.current_player_index]
	if game_state.turn.current_phase == TurnManager.Phase.ATTACK and territory.owner_id == player.id and territory.armies >= 2:
		game_state.choose_attack_source(territory.id)
	elif game_state.turn.current_phase == TurnManager.Phase.MOVEMENT and territory.owner_id == player.id and territory.armies >= 2:
		var current_source := game_state.movement_source_id
		var is_valid_target := not current_source.is_empty() and game_state.can_move_armies(current_source, territory.id, 1)
		if not is_valid_target:
			game_state.choose_movement_source(territory.id)
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
	var can_move := false
	if not game_state.selected_territory_id.is_empty():
		var selected: TerritoryData = game_state.territories[game_state.selected_territory_id]
		var player := game_state.players[game_state.turn.current_player_index]
		can_place = game_state.turn.current_phase == TurnManager.Phase.REINFORCEMENT and selected.owner_id == player.id and player.reserve_armies > 0
		can_attack = game_state.can_attack(game_state.attack_source_id, selected.id)
		if not game_state.movement_source_id.is_empty():
			var source: TerritoryData = game_state.territories[game_state.movement_source_id]
			movement_amount.max_value = source.armies - 1
			movement_amount.value = mini(int(movement_amount.value), source.armies - 1)
			can_move = game_state.can_move_armies(game_state.movement_source_id, selected.id, int(movement_amount.value))
	place_army_button.disabled = not can_place
	attack_button.disabled = not can_attack
	move_armies_button.disabled = not can_move

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
	move_armies_button.disabled = true

func _on_movement_amount_value_changed(_value: float) -> void:
	_refresh_actions()

func _on_move_armies_pressed() -> void:
	if game_state.move_armies(game_state.movement_source_id, game_state.selected_territory_id, int(movement_amount.value)):
		movement_status_label.text = "Remanejamento realizado neste turno."
		_refresh_interface()

func _on_advance_phase_pressed() -> void:
	game_state.advance_phase()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
