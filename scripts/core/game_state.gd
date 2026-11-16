class_name GameState
extends RefCounted

signal territory_selected(territory: TerritoryData)

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
