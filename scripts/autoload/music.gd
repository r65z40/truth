extends Node
## Lecteur de musique (autoload) : joue le morceau que MusicRules choisit pour le
## moment du jeu, avec un fondu enchaîné. Les scènes ne disent que le contexte
## (play_context("desk")) ; le morceau dépend de l'état de la partie.
##
## Un fichier absent n'est pas une erreur : la musique se tait.

## Émis quand une scène annonce un nouveau moment du jeu (les ambiances suivent).
signal context_changed(context: String)

const BUS := "Music"
const FADE_SECONDS := 1.5

## Contexte demandé en dernier ("menu", "desk", "evening"...).
var current_context := ""
## Morceau choisi pour ce contexte ("" : silence), même si son fichier manque.
var current_track := ""

var _player: CrossfadePlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	CrossfadePlayer.ensure_bus(BUS)
	_player = CrossfadePlayer.new(BUS, FADE_SECONDS)
	add_child(_player)
	Settings.changed.connect(apply_volume)
	GameState.state_changed.connect(refresh)
	apply_volume()


## Passe au contexte donné ; le morceau change seulement s'il est différent.
func play_context(context: String) -> void:
	var changed := context != current_context
	current_context = context
	refresh()
	if changed:
		context_changed.emit(context)


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
	context_changed.emit("")


func is_playing() -> bool:
	return _player.is_playing()


func apply_volume() -> void:
	CrossfadePlayer.set_bus_level(BUS, Settings.music_volume)


func _play_track(track_id: String) -> void:
	current_track = track_id
	var track := MusicRules.get_track(track_id)
	# Les morceaux bouclent sans réglage d'import (sauf "loop": false).
	var stream := MediaLibrary.load_stream(track.get("file", ""), bool(track.get("loop", true)))
	_player.crossfade_to(stream, float(track.get("volume_db", 0.0)))
