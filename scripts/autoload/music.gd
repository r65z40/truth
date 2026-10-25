extends Node
## Lecteur de musique (autoload) : joue le morceau que MusicRules choisit pour le
## moment du jeu, avec un fondu enchaîné. Les scènes ne disent que le contexte
## (play_context("desk")) ; le morceau dépend de l'état de la partie.
##
## Un fichier absent n'est pas une erreur : la musique se tait.

const BUS := "Music"
const FADE_SECONDS := 1.5
const SILENT_DB := -60.0

## Contexte demandé en dernier ("menu", "desk", "evening"...).
var current_context := ""
## Morceau choisi pour ce contexte ("" : silence), même si son fichier manque.
var current_track := ""

var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if AudioServer.get_bus_index(BUS) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, BUS)
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = BUS
		player.volume_db = SILENT_DB
		add_child(player)
		_players.append(player)
	Settings.changed.connect(apply_volume)
	GameState.state_changed.connect(refresh)
	apply_volume()


## Passe au contexte donné ; le morceau change seulement s'il est différent.
func play_context(context: String) -> void:
	current_context = context
	refresh()


## Réévalue le morceau (l'acte, un drapeau ou un indicateur a pu changer).
func refresh() -> void:
	if current_context == "":
		return
	var state := GameState.get_condition_state()
	state["indicators"] = GameState.indicators
	var track_id := MusicRules.track_for(current_context, state)
	if track_id != current_track:
		_play_track(track_id)


func stop() -> void:
	current_context = ""
	_play_track("")


func is_playing() -> bool:
	return _players[_active].playing


func apply_volume() -> void:
	var index := AudioServer.get_bus_index(BUS)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(Settings.music_volume, 0.0001)))
	AudioServer.set_bus_mute(index, Settings.music_volume <= 0.0)


func _play_track(track_id: String) -> void:
	current_track = track_id
	var track := MusicRules.get_track(track_id)
	var file: String = track.get("file", "")
	var stream: AudioStream = load(file) if file != "" and ResourceLoader.exists(file) else null
	var old := _players[_active]
	if _tween:
		_tween.kill()
	# Fondu enchaîné : l'ancien morceau baisse pendant que le nouveau monte.
	_tween = create_tween().set_parallel()
	_tween.tween_property(old, "volume_db", SILENT_DB, FADE_SECONDS)
	if stream != null:
		_active = 1 - _active
		var new := _players[_active]
		new.stream = stream
		new.volume_db = SILENT_DB
		new.play()
		_tween.tween_property(new, "volume_db", float(track.get("volume_db", 0.0)), FADE_SECONDS)
	_tween.chain().tween_callback(old.stop)
