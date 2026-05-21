class_name GameScenario
extends Game

func startGame() -> void:
	_setup_scenario()

	var winner = false
	var action_successful = false

	while not winner:
		action_successful = false

		await gameplayScreen.RefreshBasicInfo(self)
		var resDice: int = await DicePhase()
		await EffectPhase(resDice)

		while not action_successful:
			var choice = await gameplayScreen.pause()
			print(choice)
			match choice[0]:
				CHOICE.Build_MONUMENT:
					action_successful = buildPhase(choice[1])
				CHOICE.Build_ESTABLISHMENT:
					action_successful = buyPhase(choice[1])
				CHOICE.SKIP:
					skipPhase(false)
					action_successful = true
			if not action_successful:
				print("[Scénario] Action échouée, réessayez.")

		winner = verifyVictory(getActivePlayer())

		if winner:
			print("[Scénario] ", getActivePlayer().username, " a gagné!")
			gameplayScreen.show_victory_screen(getActivePlayer().username)
			break

		if takes_bonus_turn:
			print("[Scénario] Tour bonus pour ", getActivePlayer().username)
		else:
			currentPlayerIndex = (currentPlayerIndex + 1) % playerArray.size()


func verifyVictory(player: Player) -> bool:
	return player.monumentCount >= 5


func rollDice(numberDice: int) -> Array[int]:
	var res: Array[int] = [0, 0]

	if is_instance_valid(gameplayScreen) and gameplayScreen.forced_dice_total > 0:
		var total = gameplayScreen.forced_dice_total
		gameplayScreen.forced_dice_total = -1
		if numberDice == 2:
			# Split total across two dice (clamp each die to 1-6)
			var d1 = clamp(total - 6, 1, 6)
			var d2 = total - d1
			res[0] = d1
			res[1] = d2
		else:
			res[0] = clamp(total, 1, 6)
		return res

	res[0] = (randi() % 6) + 1
	if numberDice == 2:
		res[1] = (randi() % 6) + 1
	return res


func _setup_scenario() -> void:
	var p1: Player = playerArray[0]
	p1.balance = 5
	p1.deck = [[1, 1], [7, 1]]
	p1.monumentArray[Monument.MONUMENT_ID.Port]  = true
	p1.monumentArray[Monument.MONUMENT_ID.Radio] = true
	p1.monumentArray[Monument.MONUMENT_ID.Parc]  = true
	p1.monumentCount = 3

	var pool_p1: Array = [2, 3, 4, 5, 6, 8, 10, 11, 13, 17, 18, 19]
	pool_p1.shuffle()
	for i in 3:
		p1.deck.append([pool_p1[i], 1])

	var p2: Player = playerArray[1]
	p2.balance = 5
	p2.deck = [[1, 1], [7, 1], [17, 1]]
	p2.monumentArray[Monument.MONUMENT_ID.Port]  = true
	p2.monumentArray[Monument.MONUMENT_ID.Radio] = true
	p2.monumentArray[Monument.MONUMENT_ID.Parc]  = true
	p2.monumentCount = 3

	var pool_p2: Array = [2, 3, 4, 5, 6, 8, 10, 11, 13, 18, 19]
	pool_p2.shuffle()
	for i in 3:
		p2.deck.append([pool_p2[i], 1])

	var scenario_shop: Array = [
		[8,  1],
		[2,  1],
		[18, 1],
		[19, 1],
		[4,  1],
		[10, 1],
		[15, 1],
		[30, 1],
		[32, 1],
	]

	shop.shop.clear()
	for entry in scenario_shop:
		shop.shop.append(Slot.new(entry[0], entry[1]))
