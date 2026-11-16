class_name GameState
extends RefCounted

signal territory_selected(territory: TerritoryData)
signal territory_updated(territory: TerritoryData)
signal turn_updated

var players: Array[PlayerData] = []
var territories: Dictionary = {}
var turn := TurnManager.new()
var selected_territory_id := ""

func setup(randomize: bool = true) -> void:
	players.clear()
	territories.clear()
	selected_territory_id = ""
	turn = TurnManager.new()
	players.append(PlayerData.new(0, "Jogador 1", Color("#e05a47")))
	players.append(PlayerData.new(1, "Jogador 2", Color("#3b82d0")))
	_create_prototype_territories()
	_distribute_territories(randomize)
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

func can_advance_phase() -> bool:
	var player := players[turn.current_player_index]
	return turn.current_phase != TurnManager.Phase.REINFORCEMENT or player.reserve_armies == 0

func advance_phase() -> bool:
	if not can_advance_phase():
		return false
	turn.advance_phase(players.size())
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

func _distribute_territories(randomize: bool) -> void:
	var ids: Array = territories.keys()
	if randomize:
		ids.shuffle()
	for index in ids.size():
		var territory: TerritoryData = territories[ids[index]]
		territory.owner_id = index % players.size()
		territory.armies = 1
