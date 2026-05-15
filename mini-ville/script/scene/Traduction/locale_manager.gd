extends Node


func _ready():
	_load_translations()
	TranslationServer.set_locale(_load_saved_locale())


func _load_translations():
	var data = {
		"fr": {
			# --- Existant ---

			# --- Boutons de l'UI ---
			"PASSER_LE_TOUR": "Passer le tour",
			"LANCER_1_DE": "Lancer 1 dé",
			"LANCER_2_DES": "Lancer 2 dés",
			"Refaire le lancer": "Refaire le lancer",
			"Conserver le résultat": "Conserver le résultat",
			"Ajouter 2 au résultat": "Ajouter 2 au résultat",
			"PARAMETRES": "Paramètres",
			"CONTINUER": "Continuer",
			"MENU_PRINCIPAL": "Menu principal",
			"QUITTER": "Quitter",
			"RECUPERER": "Récupérer",
			   
			# --- Monuments ---
			"Port": "Port",
			"Gare": "Gare",
			"Centre commercial": "Centre commercial",
			"Parc d'attraction": "Parc d'attraction",
			"Tour radio": "Tour radio",
			"Aéroport": "Aéroport",
			"Construire": "Construire",
			
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
			"Veuillez remplir tous les champs.": "Veuillez remplir tous les champs.",
			"Connexion réussie !": "Connexion réussie !",
			"Identifiants incorrects.": "Identifiants incorrects.",
			"Erreur : Scène popup introuvable.": "Erreur : Scène popup introuvable.",
			# --- Popup Inscription & Mdp ---
			"Mot de passe": "Mot de passe",
			"Confirmer votre mot de passe": "Confirmer votre mot de passe",
			"Vous avez déjà un compte ?": "Vous avez déjà un compte ?",
			"Se connecter": "Se connecter",
			"Le format de l'email est invalide.": "Le format de l'email est invalide.",
			"Le mot de passe doit faire au moins 6 caractères.": "Le mot de passe doit faire au moins 6 caractères.",
			"Les mots de passe ne correspondent pas !": "Les mots de passe ne correspondent pas !",
			"Les mots de passe ne correspondent pas.": "Les mots de passe ne correspondent pas.",
			"Inscription en cours": "Inscription en cours",
			"Compte créé !\nVeuillez vous connecter": "Compte créé !\nVeuillez vous connecter",
			"Ce pseudo est déjà utilisé.": "Ce pseudo est déjà utilisé.",
			"Cette adresse email est déjà enregistrée.": "Cette adresse email est déjà enregistrée.",
			"Veuillez entrer le code à 6 chiffres complet.": "Veuillez entrer le code à 6 chiffres complet.",
			"Veuillez entrer un nouveau mot de passe.": "Veuillez entrer un nouveau mot de passe.",
			"Modification en cours...": "Modification en cours...",
			"Veuillez entrer votre adresse email.": "Veuillez entrer votre adresse email.",
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
			"STATISTIQUES": "STATISTIQUES",
			# --- Jeu ---
			"ACHETER": "ACHETER",
			"CONSTRUIRE": "CONSTRUIRE",
			"DECK": "DECK",
			"SHOP": "SHOP",
			"Pause": "Pause",
			"Menu principal": "Menu principal",
			"Monuments": "Monuments",
			"Oui": "Oui",
			"Question": "Question",
			"Confirmer": "Confirmer",
			"Résultat du lancer": "Résultat du lancer",
			"Combien de dé lancez-vous ?": "Combien de dé lancez-vous ?",
			"Choississez un adversaire:": "Choississez un adversaire :",
			"Choississez une carte pour donnez:": "Choississez une carte à donner :",
			"gagne la partie!": "gagne la partie !",
			"GAGNE!": "GAGNE !",
			"Tour de ": "Tour de ",
			"Tour d' ": "Tour d' ",
			"Joueur ": "Joueur ",
			"Or: ": "Or : ",
			"Sélectionnez les cartes à échanger": "Sélectionnez les cartes à échanger",
			"Sélectionnez une carte et un adversaire": "Sélectionnez une carte et un adversaire",
			"Chalutier de ": "Chalutier de ",
			"Prise de ": "Prise de ",
			# --- Lobby / Réseau ---
			"En attente de joueur ": "En attente de joueur ",
			"En attente... (1/%d)": "En attente... (1/%d)",
			"Minimum %d joueurs requis": "Minimum %d joueurs requis",
			"En attente du host...": "En attente du host...",
			"En attente joueur %d/%d": "En attente joueur %d/%d",
			"Entrer le code du lobby": "Entrer le code du lobby",
			"Rejoindre un lobby": "Rejoindre un lobby",
			"Veuillez entrer le code complet": "Veuillez entrer le code complet",
		},
		"en": {
			# --- Boutons de l'UI ---
			"PASSER_LE_TOUR": "End Turn",
			"LANCER_1_DE": "Roll 1 die",
			"LANCER_2_DES": "Roll 2 dice",
			"Refaire le lancer": "Reroll",
			"Conserver le résultat": "Keep the result",
			"Ajouter 2 au résultat": "Add 2 to result",
			"PARAMETRES": "Settings",
			"CONTINUER": "Continue",
			"MENU_PRINCIPAL": "Main Menu",
			"QUITTER": "Quit",
			"RECUPERER": "Collect",

			# --- Monuments ---
			"Port": "Harbor",
			"Gare": "Train Station",
			"Centre commercial": "Shopping Mall",
			"Parc d'attraction": "Amusement Park",
			"Tour radio": "Radio Tower",
			"Aéroport": "Airport",			
			"Construire": "Build",
			
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
			"Veuillez remplir tous les champs.": "Please fill in all fields.",
			"Connexion réussie !": "Login successful!",
			"Identifiants incorrects.": "Incorrect credentials.",
			"Erreur : Scène popup introuvable.": "Error: Popup scene not found.",
			# --- Popup Inscription & Mdp ---
			"Mot de passe": "Password",
			"Confirmer votre mot de passe": "Confirm your password",
			"Vous avez déjà un compte ?": "Already have an account?",
			"Se connecter": "Log in",
			"Le format de l'email est invalide.": "Invalid email format.",
			"Le mot de passe doit faire au moins 6 caractères.": "Password must be at least 6 characters long.",
			"Les mots de passe ne correspondent pas !": "Passwords do not match!",
			"Les mots de passe ne correspondent pas.": "Passwords do not match.",
			"Inscription en cours": "Registration in progress...",
			"Compte créé !\nVeuillez vous connecter": "Account created!\nPlease log in",
			"Ce pseudo est déjà utilisé.": "This username is already taken.",
			"Cette adresse email est déjà enregistrée.": "This email address is already registered.",
			"Veuillez entrer le code à 6 chiffres complet.": "Please enter the full 6-digit code.",
			"Veuillez entrer un nouveau mot de passe.": "Please enter a new password.",
			"Modification en cours...": "Modification in progress...",
			"Veuillez entrer votre adresse email.": "Please enter your email address.",
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
			"STATISTIQUES": "STATISTICS",
			# --- Jeu ---
			"ACHETER": "BUY",
			"CONSTRUIRE": "BUILD",
			"DECK": "DECK",
			"SHOP": "SHOP",
			"Pause": "Pause",
			"Menu principal": "Main Menu",
			"Monuments": "Monuments",
			"Oui": "Yes",
			"Question": "Question",
			"Confirmer": "Confirm",
			"Résultat du lancer": "Dice Result",
			"Combien de dé lancez-vous ?": "How many dice do you roll?",
			"Choississez un adversaire:": "Choose an opponent:",
			"Choississez une carte pour donnez:": "Choose a card to give:",
			"gagne la partie!": "wins the game!",
			"GAGNE!": "WINS!",
			"Tour de ": "Turn: ",
			"Tour d' ": "Turn: ",
			"Joueur ": "Player ",
			"Or: ": "Gold: ",
			"Sélectionnez les cartes à échanger": "Select cards to trade",
			"Sélectionnez une carte et un adversaire": "Select a card and an opponent",
			"Chalutier de ": "Trawler: ",
			"Prise de ": "Catch from ",
			# --- Lobby / Réseau ---
			"En attente de joueur ": "Waiting for player ",
			"En attente... (1/%d)": "Waiting... (1/%d)",
			"Minimum %d joueurs requis": "Minimum %d players required",
			"En attente du host...": "Waiting for host...",
			"En attente joueur %d/%d": "Waiting for player %d/%d",
			"Entrer le code du lobby": "Enter lobby code",
			"Rejoindre un lobby": "Join a lobby",
			"Veuillez entrer le code complet": "Please enter the full code",
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
