class_name EffectEchange
extends Effect


func _init(p_id: int):
	var desc = "Échangez un de vos établissements (non-violet) avec celui d'un adversaire."
	super._init(p_id, desc)


func appliquer(game: GameServer, owner: Player, roller: Player):
	# Les choix sont stockés dans game
	var id_owner = game.carte_owner_pour_echange          # int (card_id)
	var adversaire_cible = game.adversaire_choisi_pour_echange  # Player
	var id_adversaire = game.carte_adversaire_pour_echange  # int (card_id)

	if id_owner == null or adversaire_cible == null or id_adversaire == null:
		push_error("Choix incomplets pour l'échange")
		return

	# Vérifier que les deux cartes existent et sont non-violettes
	var card_owner = CardFactory.get_card(id_owner)
	var card_adv = CardFactory.get_card(id_adversaire)

	if card_owner == null or card_adv == null:
		push_error("Carte introuvable en factory")
		return
	if card_owner.color == CardColor.Type.PURPLE:
		push_error("Impossible d'échanger une carte violette (owner)")
		return
	if card_adv.color == CardColor.Type.PURPLE:
		push_error("Impossible d'échanger une carte violette (adversaire)")
		return

	# Trouver les instances dans les decks (format [card_id, quantity])
	var inst_owner = _trouver_instance(owner.deck, id_owner)
	var inst_adv = _trouver_instance(adversaire_cible.deck, id_adversaire)

	if inst_owner == null:
		push_error("Le owner ne possède pas cette carte")
		return
	if inst_adv == null:
		push_error("L'adversaire ne possède pas cette carte")
		return

	# Retirer 1 exemplaire de chaque côté
	_retirer_un(owner.deck, inst_owner)
	owner.establishmentCount -= 1
	_retirer_un(adversaire_cible.deck, inst_adv)
	adversaire_cible.establishmentCount -= 1

	# Ajouter de l'autre côté
	_ajouter_un(owner.deck, id_adversaire)
	owner.establishmentCount += 1
	_ajouter_un(adversaire_cible.deck, id_owner)
	adversaire_cible.establishmentCount += 1

	print(owner.username, " échange ", card_owner.name, " contre ", card_adv.name, " de ", adversaire_cible.username)


func _trouver_instance(deck: Array, card_id: int):
	for instance in deck:
		if typeof(instance) != TYPE_ARRAY:
			continue
		if instance[0] == card_id:
			return instance
	return null


func _retirer_un(deck: Array, instance) -> void:
	instance[1] -= 1
	if instance[1] <= 0:
		deck.erase(instance)


func _ajouter_un(deck: Array, card_id: int) -> void:
	for instance in deck:
		if typeof(instance) != TYPE_ARRAY:
			continue
		if instance[0] == card_id:
			instance[1] += 1
			return
	deck.append([card_id, 1])


func peutActiver(game: GameServer, owner: Player, roller: Player) -> bool:
	# Le joueur doit avoir au moins 1 établissement non-violet à échanger
	for instance in owner.deck:
		if typeof(instance) != TYPE_ARRAY:
			continue
		var card = CardFactory.get_card(instance[0])
		if card != null and card.color != CardColor.Type.PURPLE:
			return true
	return false
