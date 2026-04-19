extends Node


func _ready():
	_load_translations()
	TranslationServer.set_locale(_load_saved_locale())


func _load_translations():
	var data = {
		"fr": {
			# --- Existant ---
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
			# --- Général ---
			"Retour": "Retour",
			"Annuler": "Annuler",
			"Commencer": "Commencer",
			"Lancer la partie": "Lancer la partie",
			# --- Navigation ---
			"Profil": "Profil",
			"Jouer": "Jouer",
			"Se Connecter": "Se Connecter",
			"Local": "Local",
			"En ligne": "En ligne",
			# --- Page Profil ---
			"MON PROFIL": "MON PROFIL",
			"☰ STATISTIQUES": "☰ STATISTIQUES",
			"PARTIES": "PARTIES",
			"VICTOIRES": "VICTOIRES",
			"DÉFAITES": "DÉFAITES",
			"WIN RATE": "WIN RATE",
			"MODIFIER LE PROFIL": "MODIFIER LE PROFIL",
			"CHANGER DE MOT DE PASSE": "CHANGER DE MOT DE PASSE",
			"DÉCONNEXION": "DÉCONNEXION",
			# --- Popup Connexion ---
			"connexion": "connexion",
			"pseudo/email": "pseudo/email",
			"Mot de Passe": "Mot de Passe",
			"Mot de passe oublié": "Mot de passe oublié",
			"Vous voulez vous inscrire ?": "Vous voulez vous inscrire ?",
			"S'inscrire": "S'inscrire",
			# --- Popup Inscription ---
			"Mot de passe": "Mot de passe",
			"Confirmer votre mot de passe": "Confirmer votre mot de passe",
			"Vous avez déjà un compte ?": "Vous avez déjà un compte ?",
			"Se connecter": "Se connecter",
			# --- Paramètres ---
			" Paramètres": " Paramètres",
			"Réglages": "Réglages",
			"Musique": "Musique",
			"Effets sonores": "Effets sonores",
			"Langue": "Langue",
			"Affichage": "Affichage",
			"Clair": "Clair",
			"Sombre": "Sombre",
			"Français": "Français",
			"Anglais": "Anglais",
			# --- Lobby ---
			"Publique": "Publique",
			"Privée": "Privée",
			"Public": "Public",
			"Sélectionne un lobby": "Sélectionne un lobby",
			"Aucun lobby disponible...": "Aucun lobby disponible...",
			"Code du lobby": "Code du lobby",
			# --- Stats ---
			"Légende": "Légende",
		},
		"en": {
			# --- Existant ---
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
			# --- Général ---
			"Retour": "Back",
			"Annuler": "Cancel",
			"Commencer": "Start",
			"Lancer la partie": "Start Game",
			# --- Navigation ---
			"Profil": "Profile",
			"Jouer": "Play",
			"Se Connecter": "Log In",
			"Local": "Local",
			"En ligne": "Online",
			# --- Page Profil ---
			"MON PROFIL": "MY PROFILE",
			"☰ STATISTIQUES": "☰ STATISTICS",
			"PARTIES": "GAMES",
			"VICTOIRES": "WINS",
			"DÉFAITES": "LOSSES",
			"WIN RATE": "WIN RATE",
			"MODIFIER LE PROFIL": "EDIT PROFILE",
			"CHANGER DE MOT DE PASSE": "CHANGE PASSWORD",
			"DÉCONNEXION": "LOG OUT",
			# --- Popup Connexion ---
			"connexion": "login",
			"pseudo/email": "username/email",
			"Mot de Passe": "Password",
			"Mot de passe oublié": "Forgot password",
			"Vous voulez vous inscrire ?": "Want to sign up?",
			"S'inscrire": "Sign Up",
			# --- Popup Inscription ---
			"Mot de passe": "Password",
			"Confirmer votre mot de passe": "Confirm your password",
			"Vous avez déjà un compte ?": "Already have an account?",
			"Se connecter": "Log in",
			# --- Paramètres ---
			" Paramètres": " Settings",
			"Réglages": "Settings",
			"Musique": "Music",
			"Effets sonores": "Sound Effects",
			"Langue": "Language",
			"Affichage": "Display",
			"Clair": "Light",
			"Sombre": "Dark",
			"Français": "French",
			"Anglais": "English",
			# --- Lobby ---
			"Publique": "Public",
			"Privée": "Private",
			"Public": "Public",
			"Sélectionne un lobby": "Select a lobby",
			"Aucun lobby disponible...": "No lobby available...",
			"Code du lobby": "Lobby code",
			# --- Stats ---
			"Légende": "Legend",
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
