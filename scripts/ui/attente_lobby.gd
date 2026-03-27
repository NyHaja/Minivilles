extends Control

var durations_seconds = [60, 120, 180, 300]
var durations_text = ["1 min", "2 min", "3 min", "5 min"]
var remaining_seconds: int = 120


func _ready():
	var dur_index = get_tree().get_meta("tour_duration_index", 1)
	remaining_seconds = durations_seconds[dur_index]
	$DureeTourRow/LabelDuree.text = durations_text[dur_index]
	_update_display()
	var nb_joueurs = get_tree().get_meta("nb_joueurs", 4)
	$JoueursRow/Joueur1.visible = nb_joueurs >= 1
	$JoueursRow/Joueur2.visible = nb_joueurs >= 2
	$JoueursRow/Joueur3.visible = nb_joueurs >= 3
	$JoueursRow/Joueur4.visible = nb_joueurs >= 4
	$TimerChrono.wait_time = 1.0
	$TimerChrono.timeout.connect(_on_tick)
	$TimerChrono.start()


func _on_tick():
	remaining_seconds = max(0, remaining_seconds - 1)
	_update_display()
	if remaining_seconds == 0:
		$TimerChrono.stop()


func _update_display():
	var m = remaining_seconds / 60
	var s = remaining_seconds % 60
	$LabelTimer.text = "%02d:%02d" % [m, s]
