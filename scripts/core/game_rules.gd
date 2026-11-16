class_name GameRules
extends RefCounted

const MINIMUM_REINFORCEMENTS := 3
const CONTINENT_BONUSES := {
	"norte": 2,
	"sul": 2
}

static func reinforcement_count(controlled_territories: int) -> int:
	return maxi(MINIMUM_REINFORCEMENTS, floori(controlled_territories / 2.0))

static func continent_bonus_count(player_id: int, territories: Dictionary) -> int:
	var total := 0
	for continent_id: String in CONTINENT_BONUSES:
		if owns_continent(player_id, continent_id, territories):
			total += CONTINENT_BONUSES[continent_id]
	return total

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
