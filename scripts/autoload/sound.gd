extends Node
## Bruitages et ambiances (autoload). Les scènes appellent Sound.play("stamp") ;
## le fichier, le volume et les variantes viennent de data/sounds.json
## (SoundRules). L'ambiance suit le moment du jeu annoncé à la musique
## (Music.play_context) et l'état de la partie.
##
## Tous les boutons du jeu font un clic, sans code dans les scènes : un bouton
## peut choisir un autre son avec la métadonnée « sound » (« » : muet).
## Un fichier absent n'est pas une erreur : le son se tait.

const SFX_BUS := "Sfx"
const AMBIENCE_BUS := "Ambience"
## Nombre de sons brefs pouvant se superposer.
const VOICES := 8
## Un même son n'est pas rejoué plus souvent que cela (millisecondes).
const MIN_REPEAT_MS := 45
const AMBIENCE_FADE_SECONDS := 2.0

## Contexte du jeu ("desk", "evening"...) et ambiance choisie ("" : aucune).
var current_context := ""
var current_ambiance := ""
## Dernier son demandé (même s'il est absent) : utile aux tests.
var last_effect := ""

var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _last_played: Dictionary = {}
var _ambience: CrossfadePlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	CrossfadePlayer.ensure_bus(SFX_BUS)
	CrossfadePlayer.ensure_bus(AMBIENCE_BUS)
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = SFX_BUS
		add_child(player)
		_voices.append(player)
	_ambience = CrossfadePlayer.new(AMBIENCE_BUS, AMBIENCE_FADE_SECONDS)
	add_child(_ambience)
	Settings.changed.connect(apply_volume)
	Music.context_changed.connect(set_context)
	GameState.state_changed.connect(refresh_ambiance)
	_connect_game_events()
	get_tree().node_added.connect(_on_node_added)
	apply_volume()


## Joue un son bref déclaré dans data/sounds.json (variante au hasard).
func play(effect_id: String) -> void:
	if effect_id == "":
		return
	last_effect = effect_id
	var now := Time.get_ticks_msec()
	if now - int(_last_played.get(effect_id, -MIN_REPEAT_MS)) < MIN_REPEAT_MS:
		return
	_last_played[effect_id] = now
	var stream := MediaLibrary.load_stream(SoundRules.pick_file(effect_id, randf()))
	if stream == null:
		return
	var effect := SoundRules.get_effect(effect_id)
	var player := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	var spread := float(effect.get("pitch_variation", 0.0))
	player.stream = stream
	player.volume_db = float(effect.get("volume_db", 0.0))
	player.pitch_scale = 1.0 + randf_range(-spread, spread)
	player.play()


## Nouveau moment du jeu : l'ambiance change s'il le faut.
func set_context(context: String) -> void:
	current_context = context
	refresh_ambiance()


func refresh_ambiance() -> void:
	var ambiance_id := ""
	if current_context != "":
		var state := GameState.get_condition_state()
		state["indicators"] = GameState.indicators
		ambiance_id = SoundRules.ambiance_for(current_context, state)
	if ambiance_id == current_ambiance:
		return
	current_ambiance = ambiance_id
	var ambiance := SoundRules.get_ambiance(ambiance_id)
	_ambience.crossfade_to(MediaLibrary.load_stream(ambiance.get("file", ""), true),
			float(ambiance.get("volume_db", 0.0)))


func apply_volume() -> void:
	CrossfadePlayer.set_bus_level(SFX_BUS, Settings.sfx_volume)
	CrossfadePlayer.set_bus_level(AMBIENCE_BUS, Settings.ambience_volume)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), Settings.sound_muted)


## Chaque signal de GameState listé dans « game_events » joue son effet.
func _connect_game_events() -> void:
	var events := SoundRules.game_events()
	for info in GameState.get_signal_list():
		if events.has(info.name):
			GameState.connect(info.name, play.bind(events[info.name]).unbind(info.args.size()))


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		var button := node as BaseButton
		button.pressed.connect(func() -> void: play(button.get_meta("sound", "ui_click")))
		button.mouse_entered.connect(func() -> void:
			if not button.disabled and button.get_meta("sound", "ui_click") != "":
				play("ui_hover"))
