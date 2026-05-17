extends Node
class_name Player

@export var username: String = ""

var id: int
var balance: int
var monumentCount: int
var establishmentCount: int
var deck: Array = []
var monumentArray: Dictionary = {}


func _init(_username: String, _id: int, _balance: int) -> void:
	self.username = _username
	self.id = _id
	self.balance = _balance
	self.monumentArray = {22: false, 23: false, 24: false, 25: false, 26: false, 27: false}

func getBalance() -> int:
	return balance

func receiveGold(amount: int) -> void:
	balance += amount
	
func loseGold(amount: int) -> void:
	var amountToPay = min(amount, balance)
	balance -= amountToPay

func buyCard(establishment: Establishment) -> bool:
	
	if balance < establishment.cost:
		return false
		
	if establishment.color == CardColor.Type.PURPLE:
		for instance in deck:
			if instance[0] == establishment.id:
				print(username, " tried to buy a duplicate Purple card!")
				return false
	
	balance -= establishment.cost
	
	var hasEstablishment = false
	
	for instance in deck:
		if instance[0] == establishment.id:
			instance[1] += 1
			hasEstablishment = true
			break
	if not hasEstablishment:
		deck.append([establishment.id, 1])
		
	establishmentCount += 1
	
	return true


func constructMonument(monument: Monument) -> bool:
	if balance < monument.cost:
		return false
	
	balance -= monument.cost
	
	monumentArray[monument.id] = true
	monumentCount += 1
	
	return true

func demolishMonument(monumentToDemolish: Monument) -> void:
	
	monumentArray[monumentToDemolish.id] = false
	monumentCount -= 1
	
func monumentIsActive(monumentId: int) -> bool:
	return monumentArray[monumentId]
	

func cardsWithIcon(icons: Array) -> int:
	var numberOfCards: int = 0
	for instance in deck:
		var cardId = instance[0]
		var quantity = instance[1]
		
		var card = CardFactory.get_card(cardId)
		
		if card == null:
			continue
		
		if icons.has(card.icon):
			numberOfCards += quantity
			
	return numberOfCards

func activateEffect(color: int, game: Game, roller: Player) -> void: 
	var dice_roll = game.current_roll_value
	
	for instance in deck:
		if typeof(instance) != TYPE_ARRAY:
			continue
			
		var cardId = instance[0]
		var quantity = instance[1]
		var card = CardFactory.get_card(cardId)
		
		if card == null:
			continue
		
		if card.color == color: 
			if dice_roll >= card.activation[0] and dice_roll <= card.activation[1]: 
				if card.effect.peutActiver(game, self, roller): 
					for i in range(quantity): 
						# 1. Enregistrer l'état des finances pour les animations de pièces
						var old_balances = {}
						for p in game.playerArray:
							old_balances[p] = p.balance
						
						# 2. Détection et préparation des cartes interactives (ex: Centre d'Affaire)
						var is_interactive = (card.effect is EffectVolChoix or card.effect is EffectEchange or card.effect is EffectDemenagement or card.effect is EffectDemolition)
						var noeud_carte = null
						
						if is_interactive:
							var p_idx = game.playerArray.find(self)
							if p_idx != -1:
								var board_visuel = game.gameplayScreen.active_boards[p_idx]
								noeud_carte = board_visuel.get_card_node(cardId)
								
								# ON LÈVE LA CARTE AVANT D'AFFICHER L'OVERLAY
								if is_instance_valid(noeud_carte) and noeud_carte.has_method("animer_montee"):
									var tween_montee = noeud_carte.animer_montee()
									if tween_montee: await tween_montee.finished

						# 3. Gestion des menus et effets spécifiques
						if card.effect is EffectVolChoix:
							var cible = await game.gameplayScreen.ask_choose_player(self, game.playerArray) 
							card.effect.choisir_cible(cible) 
							
						elif card.effect is EffectEchange: 
							var trade_data = await game.gameplayScreen.ask_trade_cards(self, game.playerArray)
							game.carte_owner_pour_echange = trade_data[0] 
							game.adversaire_choisi_pour_echange = trade_data[1] 
							game.carte_adversaire_pour_echange = trade_data[2] 
							# Animation de vol des cartes pour l'échange
							await game.gameplayScreen.animer_echange_cartes(self, trade_data[0], trade_data[1], trade_data[2])
							
						elif card.effect is EffectDemenagement:
							var move_data = await game.gameplayScreen.ask_give_card(self, game.playerArray) 
							game.carte_choisie_pour_don = move_data[0]  
							game.adversaire_choisi_pour_don = move_data[1]
							
							await game.gameplayScreen.animer_don_carte(self, move_data[0], move_data[1])
							
						elif card.effect is EffectDemolition: 
							var monu_id = await game.gameplayScreen.ask_demolish_monument(self) 
							game.monument_choisi_pour_demolition = monu_id 
						
						# 4. Application physique de l'effet
						card.effect.appliquer(game, self, roller)
						
						# Bonus Centre Commercial (compté avant le calcul de différence)
						if card.icon == Icon.Type.BREAD and monumentIsActive(Monument.MONUMENT_ID.Centre_Commercial):
							self.receiveGold(1) 
						
						# 5. Calcul des gains/pertes d'or pour tout le monde
						var balance_changes = {}
						for p in game.playerArray:
							var diff = p.balance - old_balances[p]
							if diff != 0:
								balance_changes[p] = diff

						# 6. Finalisation visuelle
						if is_interactive:
							# Déclencher immédiatement l'or pour les cartes à menu
							for p in balance_changes:
								var target_idx = game.playerArray.find(p)
								if target_idx != -1:
									game.gameplayScreen.animer_gain_gold(game.gameplayScreen.active_boards[target_idx], balance_changes[p])
									game.gameplayScreen.active_boards[target_idx].update_info()
							
							if not balance_changes.is_empty():
								await game.gameplayScreen.get_tree().create_timer(1.2).timeout
							
							# Redescendre la carte interactive
							if is_instance_valid(noeud_carte) and noeud_carte.has_method("animer_descente"):
								var tween_descente = noeud_carte.animer_descente()
								if tween_descente: await tween_descente.finished
							
							# Rafraîchir les plateaux après un échange ou un don
							game.gameplayScreen.update_all_boards()
						else:
							# Pour les cartes automatiques, on passe par la file d'attente classique
							game.gameplayScreen.notifier_activation(self, cardId, balance_changes)
