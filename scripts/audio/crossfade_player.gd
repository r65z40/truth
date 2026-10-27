class_name CrossfadePlayer
extends Node
## Lecteur en boucle à fondu enchaîné : l'ancien son baisse pendant que le
## nouveau monte. Utilisé par la musique (Music) et les ambiances (Sound).

const SILENT_DB := -60.0

var fade_seconds := 1.5

var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _tween: Tween


func _init(bus: String, fade := 1.5) -> void:
	fade_seconds = fade
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = bus
		player.volume_db = SILENT_DB
		add_child(player)
		_players.append(player)


## Passe à ce son (null : silence), avec un fondu.
func crossfade_to(stream: AudioStream, volume_db := 0.0) -> void:
	var old := _players[_active]
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel()
	_tween.tween_property(old, "volume_db", SILENT_DB, fade_seconds)
	if stream != null:
		_active = 1 - _active
		var new := _players[_active]
		new.stream = stream
		new.volume_db = SILENT_DB
		new.play()
		_tween.tween_property(new, "volume_db", volume_db, fade_seconds)
	_tween.chain().tween_callback(old.stop)


func is_playing() -> bool:
	return _players[_active].playing


## Crée le bus audio s'il n'existe pas encore (branché sur Master).
static func ensure_bus(bus: String) -> int:
	if AudioServer.get_bus_index(bus) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	return AudioServer.get_bus_index(bus)


## Volume d'un bus d'après un réglage de 0 à 1 (0 : coupé).
static func set_bus_level(bus: String, level: float) -> void:
	var index := ensure_bus(bus)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(level, 0.0001)))
	AudioServer.set_bus_mute(index, level <= 0.0)
