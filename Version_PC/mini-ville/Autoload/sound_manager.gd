# sound_manager.gd
extends Node

# Un player par catégorie pour éviter les conflits
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer
@onready var music_player: AudioStreamPlayer = $MusicPlayer

func _ready():
	sfx_player.bus = "SFX"
	music_player.bus = "Music"

# --- Sons d'effets ---
func play_click():
	_play_sfx("res://Assets/Sound/SFX/mouse-click.mp3")


#func play_dice():
	#_play_sfx("res://sounds/dice_roll.ogg")
#
##func play_buy_card():
	#_play_sfx("res://sounds/buy_card.ogg")
#
#func play_coins():
	#_play_sfx("res://sounds/coins.ogg")
#
#func play_monument():
	#_play_sfx("res://sounds/build_monument.ogg")
#
#func play_victory():
	#_play_sfx("res://sounds/victory.ogg")

# --- Musique ---
func play_music(path: String):
 # Évite de redémarrer si c'est déjà la même musique
	if music_player.stream != null:
		if music_player.stream.resource_path == path and music_player.playing:
			return
	music_player.stream = load("res://Assets/Sound/Music/how-delightful-jonny-boyle-main-version-45457-01-45.ogg")
	music_player.play()

func stop_music():
	music_player.stop()

func set_music_volume(value: float):  # 0.0 à 1.0
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(value)
	)

func set_sfx_volume(value: float):
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		linear_to_db(value)
	)

# --- Interne ---
func _play_sfx(path: String, pitch_variation: bool = true):
	sfx_player.stream = load(path)
	if pitch_variation:
		sfx_player.pitch_scale = randf_range(0.95, 1.05)
	else:
		sfx_player.pitch_scale = 1.0
	sfx_player.play()
