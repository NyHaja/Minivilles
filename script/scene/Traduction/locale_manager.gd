extends Node


func _ready():
	_load_translations()
	TranslationServer.set_locale(_load_saved_locale())


func _load_translations():
	var data = {
		"fr": {
			"Connexion": "Connexion",
			"Jouer en invité": "Jouer en invité",
			"Règles": "Règles",
			"Paramètres": "Paramètres",
			"Solo": "Solo",
			"Multijoueur": "Multijoueur",
			"Créer une partie": "Créer une partie",
			"Rejoindre": "Rejoindre",
			"Créer": "Créer",
			"Prêt": "Prêt",
			"Retour au\nlobby": "Retour au\nlobby",
			"Durée d'un tour": "Durée d'un tour",
			"Nombre de joueurs": "Nombre de joueurs",
			"Rejoindre une partie": "Rejoindre une partie",
			"Entre le code donné par l'hôte du lobby": "Entre le code donné par l'hôte du lobby",
			"Durée du tour :": "Durée du tour :",
			"Nombre de partie(s) jouée(s) : %d": "Nombre de partie(s) jouée(s) : %d",
			"Nombre de partie(s) gagnée(s) : %d": "Nombre de partie(s) gagnée(s) : %d",
		},
		"en": {
			"Connexion": "Login",
			"Jouer en invité": "Play as Guest",
			"Règles": "Rules",
			"Paramètres": "Settings",
			"Solo": "Solo",
			"Multijoueur": "Multiplayer",
			"Créer une partie": "Create a game",
			"Rejoindre": "Join",
			"Créer": "Create",
			"Prêt": "Ready",
			"Retour au\nlobby": "Back to\nlobby",
			"Durée d'un tour": "Turn duration",
			"Nombre de joueurs": "Number of players",
			"Rejoindre une partie": "Join a game",
			"Entre le code donné par l'hôte du lobby": "Enter the code given by the lobby host",
			"Durée du tour :": "Turn duration:",
			"Nombre de partie(s) jouée(s) : %d": "Games played: %d",
			"Nombre de partie(s) gagnée(s) : %d": "Games won: %d",
		},
		"de": {
			"Connexion": "Anmelden",
			"Jouer en invité": "Als Gast spielen",
			"Règles": "Regeln",
			"Paramètres": "Einstellungen",
			"Solo": "Solo",
			"Multijoueur": "Mehrspieler",
			"Créer une partie": "Spiel erstellen",
			"Rejoindre": "Beitreten",
			"Créer": "Erstellen",
			"Prêt": "Bereit",
			"Retour au\nlobby": "Zurück zur\nLobby",
			"Durée d'un tour": "Rundendauer",
			"Nombre de joueurs": "Spieleranzahl",
			"Rejoindre une partie": "Spiel beitreten",
			"Entre le code donné par l'hôte du lobby": "Gib den Code des Lobby-Hosts ein",
			"Durée du tour :": "Rundendauer:",
			"Nombre de partie(s) jouée(s) : %d": "Gespielte Partien: %d",
			"Nombre de partie(s) gagnée(s) : %d": "Gewonnene Partien: %d",
		},
		"es": {
			"Connexion": "Iniciar sesión",
			"Jouer en invité": "Jugar como invitado",
			"Règles": "Reglas",
			"Paramètres": "Ajustes",
			"Solo": "Solo",
			"Multijoueur": "Multijugador",
			"Créer une partie": "Crear partida",
			"Rejoindre": "Unirse",
			"Créer": "Crear",
			"Prêt": "Listo",
			"Retour au\nlobby": "Volver al\nlobby",
			"Durée d'un tour": "Duración del turno",
			"Nombre de joueurs": "Número de jugadores",
			"Rejoindre une partie": "Unirse a una partida",
			"Entre le code donné par l'hôte du lobby": "Introduce el código del anfitrión",
			"Durée du tour :": "Duración del turno:",
			"Nombre de partie(s) jouée(s) : %d": "Partidas jugadas: %d",
			"Nombre de partie(s) gagnée(s) : %d": "Partidas ganadas: %d",
		},
	}
	for locale_code in data:
		var t = Translation.new()
		t.locale = locale_code
		for key in data[locale_code]:
			t.add_message(key, data[locale_code][key])
		TranslationServer.add_translation(t)


func set_language(locale: String):
	TranslationServer.set_locale(locale)
	_save_locale(locale)


func _save_locale(locale: String):
	var config = ConfigFile.new()
	config.set_value("settings", "locale", locale)
	config.save("user://settings.cfg")


func _load_saved_locale() -> String:
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		return config.get_value("settings", "locale", "fr")
	return "fr"
