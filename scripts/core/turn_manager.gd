class_name TurnManager
extends RefCounted

enum Phase { REINFORCEMENT, ATTACK, MOVEMENT }
var current_player_index := 0
var current_phase := Phase.REINFORCEMENT
var round_number := 1

func advance_phase(player_count: int) -> void:
	match current_phase:
		Phase.REINFORCEMENT: current_phase = Phase.ATTACK
		Phase.ATTACK: current_phase = Phase.MOVEMENT
		Phase.MOVEMENT:
			current_phase = Phase.REINFORCEMENT
			current_player_index = (current_player_index + 1) % player_count
			if current_player_index == 0:
				round_number += 1

func phase_name() -> String:
	match current_phase:
		Phase.REINFORCEMENT: return "Reforço"
		Phase.ATTACK: return "Ataque"
		Phase.MOVEMENT: return "Movimentação"
	return ""
