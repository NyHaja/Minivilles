class_name EffectDemenagement
extends Effect

var montant_recu : int  # Montant reçu en échange du don


func _init(p_id: int, p_montant_recu: int):
	var desc = "Donnez 1 établissement non-violet à un adversaire. Recevez " + str(p_montant_recu) + " pièces."
	super._init(p_id, desc)
	montant_recu = p_montant_recu


func appliquer(game: GameServer, owner: Player, roller: Player):
	# Les choix sont stockés dans game
	var carte_a_donner_id = game.carte_choisie_pour_don   # int (card_id)
	var adversaire_cible = game.adversaire_choisi_pour_don  # Player

	if carte_a_donner_id == null or carte_a_donner_id == -1:
		push_error("Aucune carte choisie pour le don")
		return

	if adversaire_cible == null:
		push_error("Aucun adversaire choisi")
		return

	# Vérifier que la carte existe et n'est pas violette
	var card = CardFactory.get_card(carte_a_donner_id)
	if card == null:
		push_error("Carte introuvable en factory")
		return
	if card.color == CardColor.Type.PURPLE:
		push_error("Impossible de donner une carte violette")
		return

	# Trouver l'instance dans le deck de owner (format [card_id, quantity])
	var instance_trouvee = null
	for instance in owner.deck:
		if typeof(instance) != TYPE_ARRAY:
			continue
		if instance[0] == carte_a_donner_id:
			instance_trouvee = instance
			break

	if instance_trouvee == null:
		push_error("Le owner ne possède pas cette carte")
		return

	# Retirer 1 exemplaire du deck owner
	instance_trouvee[1] -= 1
	if instance_trouvee[1] <= 0:
		owner.deck.erase(instance_trouvee)
	owner.establishmentCount -= 1

	# Ajouter au deck adversaire
	var existe = false
	for inst in adversaire_cible.deck:
		if typeof(inst) != TYPE_ARRAY:
			continue
		if inst[0] == carte_a_donner_id:
			inst[1] += 1
			existe = true
			break
	if not existe:
		adversaire_cible.deck.append([carte_a_donner_id, 1])
	adversaire_cible.establishmentCount += 1

	# Recevoir argent banque
	owner.receiveGold(montant_recu)

	print(owner.username, " donne ", card.name, " à ", adversaire_cible.username)
	print(owner.username, " reçoit ", montant_recu, " pièces de la banque")


func peutActiver(game: GameServer, owner: Player, roller: Player) -> bool:
	# Le joueur doit avoir au moins 1 établissement non-violet à donner
	for instance in owner.deck:
		if typeof(instance) != TYPE_ARRAY:
			continue
		var card = CardFactory.get_card(instance[0])
		if card != null and card.color != CardColor.Type.PURPLE:
			return true
	return false
