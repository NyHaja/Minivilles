extends Control

var durations_seconds = [60, 120, 180, 300]
var durations_text = ["1 min", "2 min", "3 min", "5 min"]
var remaining_seconds: int = 120

var joueurs_prets: Array[bool] = [false, false, false, false]
var nb_joueurs_actifs: int = 2


func _ready():
	$LabelCode.text = get_tree().get_meta("lobby_code", "A4HUI5")
	var dur_index = get_tree().get_meta("tour_duration_index", 1)
	$DureeTourRow/LabelDuree.text = durations_text[dur_index]
	_update_display()
	nb_joueurs_actifs = get_tree().get_meta("nb_joueurs", 2)
	$JoueursRow/Joueur1.visible = nb_joueurs_actifs >= 1
	$JoueursRow/Joueur2.visible = nb_joueurs_actifs >= 2
	$JoueursRow/Joueur3.visible = nb_joueurs_actifs >= 3
	$JoueursRow/Joueur4.visible = nb_joueurs_actifs >= 4
	_setup_joueur_click($JoueursRow/Joueur1, "Joueur 1")
	_setup_joueur_click($JoueursRow/Joueur2, "Joueur 2")
	_setup_joueur_click($JoueursRow/Joueur3, "Joueur 3")
	_setup_joueur_click($JoueursRow/Joueur4, "Joueur 4")
	$BtnPret.pressed.connect(_on_pret_pressed)
	$BtnCommencer.pressed.connect(_on_commencer_pressed)
	$TimerChrono.wait_time = 1.0
	$TimerChrono.timeout.connect(_on_tick)
	$TimerChrono.start()


func _on_pret_pressed():
	# Toggle prêt pour le joueur local (joueur 1)
	joueurs_prets[0] = !joueurs_prets[0]
	$JoueursRow/Joueur1/ReadyBadge.visible = joueurs_prets[0]
	_verifier_tous_prets()


func _verifier_tous_prets():
	var tous_prets = true
	for i in range(nb_joueurs_actifs):
		if not joueurs_prets[i]:
			tous_prets = false
			break
	if tous_prets:
		$BtnPret.visible = false
		$BtnCommencer.visible = true
	else:
		$BtnPret.visible = true
		$BtnCommencer.visible = false


func _on_commencer_pressed():
	# TODO: lancer la scène de jeu
	print("Lancement de la partie...")


func _setup_joueur_click(joueur: Control, nom: String):
	var icon = joueur.get_node("Icon")
	icon.mouse_filter = Control.MOUSE_FILTER_STOP
	icon.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if not event.pressed:
				_ouvrir_stats(nom))


func _ouvrir_stats(nom: String):
	var stats = load("res://scene/Multijoueur/stats_joueur.tscn").instantiate()
	get_tree().root.add_child(stats)
	stats.setup(
		PlayerData.nom if PlayerData.is_logged_in() else nom,
		PlayerData.parties_jouees,
		PlayerData.parties_gagnees,
		PlayerData.rang
	)


func _on_tick():
	remaining_seconds = max(0, remaining_seconds - 1)
	_update_display()
	if remaining_seconds == 0:
		$TimerChrono.stop()


func _update_display():
	var m = remaining_seconds / 60
	var s = remaining_seconds % 60
	$LabelTimer.text = "%02d:%02d" % [m, s]
	if remaining_seconds <= 10:
		# Rouge + clignotement rapide
		$LabelTimer.modulate = Color(1, 0.15, 0.15, 1)
		var t = $LabelTimer.create_tween()
		t.tween_property($LabelTimer, "modulate:a", 0.3, 0.25)
		t.tween_property($LabelTimer, "modulate:a", 1.0, 0.25)
	elif remaining_seconds <= 30:
		# Orange fixe
		$LabelTimer.modulate = Color(1, 0.55, 0.1, 1)
	else:
		$LabelTimer.modulate = Color(1, 1, 1, 1)
