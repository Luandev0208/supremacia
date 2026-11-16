extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	var state := GameState.new()
	state.setup(false)
	_expect(state.players.size() == 2, "A partida deve criar dois participantes.")
	_expect(state.players[1].display_name == "Jogador 2", "A partida deve criar o segundo jogador local.")
	_expect(state.territories.size() == 8, "O protótipo deve criar oito territórios.")
	_expect(state.controlled_territory_count(0) == 4, "Jogador 1 deve receber quatro territórios.")
	_expect(state.controlled_territory_count(1) == 4, "Jogador 2 deve receber quatro territórios.")
	_expect(state.select_territory("aurora"), "Um território existente deve ser selecionável.")
	_expect(state.selected_territory_id == "aurora", "A seleção deve ficar registrada.")
	_expect(not state.select_territory("inexistente"), "Uma seleção inválida deve ser rejeitada.")
	_expect(GameRules.reinforcement_count(4) == 3, "O mínimo de reforços deve ser três.")
	_expect(not GameRules.has_won(0, state.territories), "Ninguém deve vencer na distribuição inicial.")
	if failures.is_empty():
		print("OK: todos os testes básicos passaram.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
