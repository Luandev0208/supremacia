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
var movement_source_id := ""
var movement_used := false
var winner_id := -1
var last_base_reinforcements := 0
var last_continent_bonus := 0
var rng := RandomNumberGenerator.new()

func setup(shuffle_territories: bool = true) -> void:
	players.clear()
	territories.clear()
	selected_territory_id = ""
	attack_source_id = ""
	movement_source_id = ""
	movement_used = false
	winner_id = -1
	last_base_reinforcements = 0
	last_continent_bonus = 0
	turn = TurnManager.new()
	rng.randomize()
	players.append(PlayerData.new(0, "Jogador 1", Color("#e05a47")))
	players.append(PlayerData.new(1, "Jogador 2", Color("#3b82d0")))
	_create_world_territories()
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

func choose_movement_source(territory_id: String) -> bool:
	if turn.current_phase != TurnManager.Phase.MOVEMENT or movement_used or not territories.has(territory_id):
		return false
	var territory: TerritoryData = territories[territory_id]
	var player := players[turn.current_player_index]
	if territory.owner_id != player.id or territory.armies < 2:
		return false
	movement_source_id = territory_id
	turn_updated.emit()
	return true

func can_move_armies(source_id: String, target_id: String, amount: int) -> bool:
	if winner_id >= 0 or movement_used or turn.current_phase != TurnManager.Phase.MOVEMENT:
		return false
	if not territories.has(source_id) or not territories.has(target_id) or source_id == target_id:
		return false
	var source: TerritoryData = territories[source_id]
	var target: TerritoryData = territories[target_id]
	var player := players[turn.current_player_index]
	if source.owner_id != player.id or target.owner_id != player.id:
		return false
	if amount < 1 or amount >= source.armies:
		return false
	return _has_owned_path(source_id, target_id, player.id)

func move_armies(source_id: String, target_id: String, amount: int) -> bool:
	if not can_move_armies(source_id, target_id, amount):
		return false
	var source: TerritoryData = territories[source_id]
	var target: TerritoryData = territories[target_id]
	source.armies -= amount
	target.armies += amount
	movement_used = true
	movement_source_id = ""
	territory_updated.emit(source)
	territory_updated.emit(target)
	turn_updated.emit()
	return true

func _has_owned_path(source_id: String, target_id: String, player_id: int) -> bool:
	var pending: Array[String] = [source_id]
	var visited: Dictionary = {}
	visited[source_id] = true
	while not pending.is_empty():
		var current_id: String = pending.pop_front()
		var current: TerritoryData = territories[current_id]
		for neighbor_id: String in current.neighbor_ids:
			if visited.has(neighbor_id):
				continue
			var neighbor: TerritoryData = territories[neighbor_id]
			if neighbor.owner_id != player_id:
				continue
			if neighbor_id == target_id:
				return true
			visited[neighbor_id] = true
			pending.append(neighbor_id)
	return false

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
	movement_source_id = ""
	if turn.current_phase == TurnManager.Phase.MOVEMENT:
		movement_used = false
	if turn.current_phase == TurnManager.Phase.REINFORCEMENT:
		movement_used = false
		_grant_reinforcements_to_current_player()
	turn_updated.emit()
	return true

func _grant_reinforcements_to_current_player() -> void:
	var player := players[turn.current_player_index]
	last_base_reinforcements = GameRules.reinforcement_count(controlled_territory_count(player.id))
	last_continent_bonus = GameRules.continent_bonus_count(player.id, territories)
	player.reserve_armies = last_base_reinforcements + last_continent_bonus

func _create_world_territories() -> void:
	# América do Norte
	_add("alaska", "Alaska", "america_norte", ["mackenzie", "vancouver", "vladivostok"])
	_add("mackenzie", "Mackenzie", "america_norte", ["alaska", "vancouver", "ottawa", "groenlandia"])
	_add("groenlandia", "Groenlândia", "america_norte", ["mackenzie", "ottawa", "labrador", "islandia"])
	_add("vancouver", "Vancouver", "america_norte", ["alaska", "mackenzie", "ottawa", "california"])
	_add("ottawa", "Ottawa", "america_norte", ["mackenzie", "groenlandia", "labrador", "vancouver", "california", "nova_york"])
	_add("labrador", "Labrador", "america_norte", ["groenlandia", "ottawa", "nova_york"])
	_add("california", "Califórnia", "america_norte", ["vancouver", "ottawa", "nova_york", "mexico"])
	_add("nova_york", "Nova York", "america_norte", ["ottawa", "labrador", "california", "mexico"])
	_add("mexico", "México", "america_norte", ["california", "nova_york", "colombia"])
	# América do Sul
	_add("colombia", "Colômbia", "america_sul", ["mexico", "brasil", "chile"])
	_add("brasil", "Brasil", "america_sul", ["colombia", "chile", "argentina", "argelia_nigeria"])
	_add("chile", "Chile", "america_sul", ["colombia", "brasil", "argentina"])
	_add("argentina", "Argentina", "america_sul", ["chile", "brasil"])
	# Europa
	_add("islandia", "Islândia", "europa", ["groenlandia", "inglaterra", "suecia"])
	_add("inglaterra", "Inglaterra", "europa", ["islandia", "suecia", "alemanha", "portugal"])
	_add("suecia", "Suécia", "europa", ["islandia", "inglaterra", "alemanha", "polonia", "moscou"])
	_add("alemanha", "Alemanha", "europa", ["inglaterra", "suecia", "polonia", "portugal"])
	_add("polonia", "Polônia", "europa", ["alemanha", "suecia", "moscou", "oriente_medio", "egito"])
	_add("portugal", "Portugal", "europa", ["inglaterra", "alemanha", "egito", "argelia_nigeria"])
	_add("moscou", "Moscou", "europa", ["suecia", "polonia", "omsk", "aral", "oriente_medio"])
	# África
	_add("argelia_nigeria", "Argélia Nigéria", "africa", ["portugal", "egito", "sudao", "congo", "brasil"])
	_add("egito", "Egito", "africa", ["argelia_nigeria", "portugal", "polonia", "oriente_medio", "sudao"])
	_add("sudao", "Sudão", "africa", ["argelia_nigeria", "egito", "congo", "africa_sul", "oriente_medio", "madagascar"])
	_add("congo", "Congo", "africa", ["argelia_nigeria", "sudao", "africa_sul"])
	_add("africa_sul", "África do Sul", "africa", ["congo", "sudao", "madagascar"])
	_add("madagascar", "Madagascar", "africa", ["sudao", "africa_sul"])
	# Ásia
	_add("oriente_medio", "Oriente Médio", "asia", ["moscou", "polonia", "egito", "sudao", "aral", "india"])
	_add("aral", "Aral", "asia", ["moscou", "omsk", "mongolia", "china", "india", "oriente_medio"])
	_add("omsk", "Omsk", "asia", ["moscou", "dudinka", "siberia", "tchita", "mongolia", "aral"])
	_add("dudinka", "Dudinka", "asia", ["omsk", "siberia"])
	_add("siberia", "Sibéria", "asia", ["dudinka", "omsk", "tchita", "vladivostok"])
	_add("tchita", "Tchita", "asia", ["siberia", "omsk", "mongolia", "vladivostok"])
	_add("mongolia", "Mongólia", "asia", ["omsk", "tchita", "aral", "vladivostok", "china", "japao"])
	_add("vladivostok", "Vladivostok", "asia", ["siberia", "tchita", "mongolia", "japao", "alaska"])
	_add("china", "China", "asia", ["aral", "mongolia", "india", "vietna", "japao"])
	_add("india", "Índia", "asia", ["oriente_medio", "aral", "china", "vietna", "sumatra"])
	_add("vietna", "Vietnã", "asia", ["india", "china", "borneu"])
	_add("japao", "Japão", "asia", ["vladivostok", "mongolia", "china"])
	# Oceania
	_add("sumatra", "Sumatra", "oceania", ["india", "australia"])
	_add("borneu", "Bornéu", "oceania", ["vietna", "nova_guine", "australia"])
	_add("nova_guine", "Nova Guiné", "oceania", ["borneu", "australia"])
	_add("australia", "Austrália", "oceania", ["sumatra", "borneu", "nova_guine"])

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
