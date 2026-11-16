class_name GameRules
extends RefCounted

const MINIMUM_REINFORCEMENTS := 3

static func reinforcement_count(controlled_territories: int) -> int:
	return maxi(MINIMUM_REINFORCEMENTS, floori(controlled_territories / 2.0))

static func roll_dice(amount: int, random: RandomNumberGenerator) -> Array[int]:
	var rolls: Array[int] = []
	for _index in amount:
		rolls.append(random.randi_range(1, 6))
	rolls.sort()
	rolls.reverse()
	return rolls

static func compare_dice(attacker_dice: Array[int], defender_dice: Array[int]) -> Dictionary:
	var attacker_losses := 0
	var defender_losses := 0
	var comparisons := mini(attacker_dice.size(), defender_dice.size())
	for index in comparisons:
		if attacker_dice[index] > defender_dice[index]:
			defender_losses += 1
		else:
			attacker_losses += 1
	return {
		"attacker_losses": attacker_losses,
		"defender_losses": defender_losses
	}

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
