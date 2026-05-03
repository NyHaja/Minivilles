extends Control

var pop_rule_scene = preload("res://scene/popup/rules_panel.tscn")
var popup_rule

var pop_setting_scene = preload("res://scene/popup/popup_parametres.tscn")
var popup_setting

# --- NOUVEAU : Preload de la scène du profil ---
var popup_profil_scene = preload("res://scene/Ecran principale/profil.tscn")

func _ready() -> void:
	popup_rule = pop_rule_scene.instantiate()
	popup_setting = pop_setting_scene.instantiate()
	
	
	if NetworkManager.has_signal("stats_received"):
		NetworkManager.stats_received.connect(_on_stats_received)
	
	add_child(popup_rule)
	add_child(popup_setting)
	
	popup_setting.hide()
	popup_rule.hide()

	popup_rule.on_back.connect(_on_popup_back)
	popup_setting.on_back.connect(_on_popup_back)
	
	$Header/header/rulebtn/TextureButton.pressed.connect(affiche_popup_rule)
	$Header/header/settingbtn/TextureButton.pressed.connect(affiche_parametre)
	
	# --- MODIFIÉ : On appelle une fonction pour demander les stats ---
	$Header/header/profilbtn/TextureButton2.pressed.connect(affiche_profil)

	$gameMode/playbtn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scene/Ecran principale/mode_de_jeu.tscn"))


#------------- HEADER --------------

# bouton pour afficher les règles
func affiche_popup_rule():
	if typeof(SoundManager) != TYPE_NIL: SoundManager.play_click()
	$gameMode.hide()
	popup_rule.show()
	
func affiche_parametre():
	if typeof(SoundManager) != TYPE_NIL: SoundManager.play_click()
	$gameMode.hide()
	popup_setting.show()

# --- NOUVEAU : Fonction du bouton Profil ---
func affiche_profil():
	if typeof(SoundManager) != TYPE_NIL: SoundManager.play_click()
	
	# On demande les stats au Game Server (VM 0)
	var mon_id = NetworkManager.get_joueur_id()
	if mon_id != -1:
		Client.get_player_stats(mon_id)
	else:
		print("Erreur : ID joueur introuvable.")

func _on_popup_back():
	$gameMode.show()
	
#------------ BODY ----------------

func _on_stats_received(data: Dictionary):
	$gameMode.hide()
	
	# Les données sont arrivées ! On instancie le popup Profil
	var popup_profil = popup_profil_scene.instantiate()
	
	# On l'ajoute à la scène actuelle
	add_child(popup_profil)
	
	# On lui passe les données pour qu'il remplisse ses Labels
	popup_profil.update_stats(data)
	
	# On connecte la fermeture du popup pour réafficher le menu principal
	# (Adapte "on_back" par "on_close" si c'est le nom du signal dans ton popup_profil.gd)
	if popup_profil.has_signal("on_back"):
		popup_profil.on_back.connect(_on_popup_back)
	elif popup_profil.has_signal("on_close"):
		popup_profil.on_close.connect(_on_popup_back)
