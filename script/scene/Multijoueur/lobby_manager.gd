extends Node

var lobbies: Array = []  # Array of { "code": String, "created_at": float }
const MAX_AGE_SECONDS = 300  # 5 minutes


func _ready():
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 30.0
	timer.timeout.connect(_cleanup)
	timer.start()
	# TODO: supprimer en prod
	add_lobby("A4HUI5", false)
	add_lobby("B7KLM2", true)
	add_lobby("XZ91RT", false)


func add_lobby(code: String, is_private: bool = false):
	lobbies.append({ "code": code, "created_at": Time.get_unix_time_from_system(), "is_private": is_private })


func get_lobbies() -> Array:
	_cleanup()
	return lobbies


func _cleanup():
	var now = Time.get_unix_time_from_system()
	lobbies = lobbies.filter(func(l): return now - l["created_at"] < MAX_AGE_SECONDS)
