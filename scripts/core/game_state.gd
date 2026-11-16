class_name GameState
extends RefCounted

signal territory_selected(territory: TerritoryData)
signal territory_updated(territory: TerritoryData)
signal turn_updated
signal game_finished(winner: PlayerData)

var players: Array[PlayerData] = []
var territories: Dictionary = {}
var turn := TurnManager.new()
var selected_territory_id := ""
var attack_source_id := ""
var winner_id := -1
var rng := RandomNumberGenerator.new()

func setup(shuffle_territories: bool = true) -> void:
	players.clear()
	territories.clear()
	selected_territory_id = ""
	attack_source_id = ""
	winner_id = -1
	turn = TurnManager.new()
	rng.randomize()
	players.append(PlayerData.new(0, "Jogador 1", Color("#e05a47")))
	players.append(PlayerData.new(1, "Jogador 2", Color("#3b82d0")))
	_create_prototype_territories()
	_distribute_territories(shuffle_territories)
	_grant_reinforcements_to_current_player()

func select_territory(territory_id: String) -> bool:
	if not territories.has(territory_id):
		return false
	selected_territory_id = territory_id
	territory_selected.emit(territories[territory_id])
	return true

func controlled_territory_count(player_id: int) -> int:
	var total := 0
	for territory: TerritoryData in territories.values():
		if territory.owner_id == player_id:
			total += 1
	return total

func place_army(territory_id: String) -> bool:
	if turn.current_phase != TurnManager.Phase.REINFORCEMENT:
		return false
	if not territories.has(territory_id):
		return false
	var player := players[turn.current_player_index]
	var territory: TerritoryData = territories[territory_id]
	if territory.owner_id != player.id or player.reserve_armies <= 0:
		return false
	territory.armies += 1
	player.reserve_armies -= 1
	territory_updated.emit(territory)
	turn_updated.emit()
	return true

func choose_attack_source(territory_id: String) -> bool:
	if turn.current_phase != TurnManager.Phase.ATTACK or not territories.has(territory_id):
		return false
	var territory: TerritoryData = territories[territory_id]
	var player := players[turn.current_player_index]
	if territory.owner_id != player.id or territory.armies < 2:
		return false
	attack_source_id = territory_id
	turn_updated.emit()
	return true

func can_attack(source_id: String, target_id: String) -> bool:
	if winner_id >= 0 or turn.current_phase != TurnManager.Phase.ATTACK:
		return false
	if not territories.has(source_id) or not territories.has(target_id) or source_id == target_id:
		return false
	var source: TerritoryData = territories[source_id]
	var target: TerritoryData = territories[target_id]
	var player := players[turn.current_player_index]
	return source.owner_id == player.id and target.owner_id != player.id and source.armies >= 2 and source.is_neighbor_of(target.id)

func attack(source_id: String, target_id: String) -> Dictionary:
	if not can_attack(source_id, target_id):
		return {"success": false}
	var source: TerritoryData = territories[source_id]
	var target: TerritoryData = territories[target_id]
	var attacker_dice := GameRules.roll_dice(mini(3, source.armies - 1), rng)
	var defender_dice := GameRules.roll_dice(mini(3, target.armies), rng)
	var losses := GameRules.compare_dice(attacker_dice, defender_dice)
	source.armies -= losses.attacker_losses
	target.armies -= losses.defender_losses
	var conquered := target.armies == 0
	var moved_armies := 0
	if conquered:
		target.owner_id = source.owner_id
		moved_armies = mini(attacker_dice.size(), source.armies - 1)
		source.armies -= moved_armies
		target.armies = moved_armies
	if source.armies < 2:
		attack_source_id = ""
	territory_updated.emit(source)
	territory_updated.emit(target)
	if GameRules.has_won(source.owner_id, territories):
		winner_id = source.owner_id
		game_finished.emit(players[winner_id])
	return {
		"success": true,
		"attacker_dice": attacker_dice,
		"defender_dice": defender_dice,
		"attacker_losses": losses.attacker_losses,
		"defender_losses": losses.defender_losses,
		"conquered": conquered,
		"moved_armies": moved_armies
	}

func can_advance_phase() -> bool:
	if winner_id >= 0:
		return false
	var player := players[turn.current_player_index]
	return turn.current_phase != TurnManager.Phase.REINFORCEMENT or player.reserve_armies == 0

func advance_phase() -> bool:
	if not can_advance_phase():
		return false
	turn.advance_phase(players.size())
	attack_source_id = ""
	if turn.current_phase == TurnManager.Phase.REINFORCEMENT:
		_grant_reinforcements_to_current_player()
	turn_updated.emit()
	return true

func _grant_reinforcements_to_current_player() -> void:
	var player := players[turn.current_player_index]
	player.reserve_armies = GameRules.reinforcement_count(controlled_territory_count(player.id))

func _create_prototype_territories() -> void:
	_add("aurora", "Aurora", "norte", ["brisa", "cedro"])
	_add("brisa", "Brisa", "norte", ["aurora", "delta", "cedro"])
	_add("cedro", "Cedro", "norte", ["aurora", "brisa", "estrela"])
	_add("delta", "Delta", "norte", ["brisa", "farol"])
	_add("estrela", "Estrela", "sul", ["cedro", "farol", "ilha"])
	_add("farol", "Farol", "sul", ["delta", "estrela", "jardim"])
	_add("ilha", "Ilha", "sul", ["estrela", "jardim"])
	_add("jardim", "Jardim", "sul", ["farol", "ilha"])

func _add(id: String, label: String, continent: String, neighbors: Array[String]) -> void:
	territories[id] = TerritoryData.new(id, label, continent, neighbors)

func _distribute_territories(should_shuffle: bool) -> void:
	var ids: Array = territories.keys()
	if should_shuffle:
		ids.shuffle()
	for index in ids.size():
		var territory: TerritoryData = territories[ids[index]]
		territory.owner_id = index % players.size()
		territory.armies = 1
