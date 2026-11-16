class_name GameRules
extends RefCounted

const MINIMUM_REINFORCEMENTS := 3

static func reinforcement_count(controlled_territories: int) -> int:
	return maxi(MINIMUM_REINFORCEMENTS, controlled_territories / 2)

static func owns_continent(player_id: int, continent_id: String, territories: Dictionary) -> bool:
	var found := false
	for territory: TerritoryData in territories.values():
		if territory.continent_id != continent_id:
			continue
		found = true
		if territory.owner_id != player_id:
			return false
	return found

static func has_won(player_id: int, territories: Dictionary) -> bool:
	if territories.is_empty():
		return false
	for territory: TerritoryData in territories.values():
		if territory.owner_id != player_id:
			return false
	return true
