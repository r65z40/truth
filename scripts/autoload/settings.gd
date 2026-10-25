extends Node
## Paramètres utilisateur, stockés séparément de la partie (user://settings.cfg).

signal changed

const PATH := "user://settings.cfg"
const UI_SCALES := [1.0, 1.15, 1.3]
## Résolutions proposées pour la fenêtre (en mode fenêtré).
const WINDOW_SIZES: Array[Vector2i] = [
	Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1600, 900), Vector2i(1920, 1080),
]
## Crans du volume de la musique proposés dans Paramètres.
const MUSIC_LEVELS := [0.0, 0.25, 0.5, 0.8, 1.0]

var fullscreen := false
## Résolution de la fenêtre en mode fenêtré.
var window_size := Vector2i(1280, 720)
var crt_effect := true
## Affiche l'objectif conseillé en haut du bureau.
var guidance := true
## Agrandit toute l'interface (lisibilité, petits écrans).
var ui_scale := 1.0
## Scènes de terrain en 3D (sinon décors dessinés en 2D, plus légers).
var field_3d := true
## Volume de la musique, de 0 (coupée) à 1.
var music_volume := 0.8
## Langue de l'interface et des dossiers ("fr" ou "en").
var language := "fr"


func _ready() -> void:
	load_settings()
	apply()


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		return
	fullscreen = config.get_value("display", "fullscreen", fullscreen)
	window_size = config.get_value("display", "window_size", window_size)
	crt_effect = config.get_value("display", "crt_effect", crt_effect)
	guidance = config.get_value("gameplay", "guidance", guidance)
	ui_scale = config.get_value("display", "ui_scale", ui_scale)
	field_3d = config.get_value("display", "field_3d", field_3d)
	music_volume = config.get_value("audio", "music_volume", music_volume)
	language = config.get_value("general", "language", language)


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "window_size", window_size)
	config.set_value("display", "crt_effect", crt_effect)
	config.set_value("gameplay", "guidance", guidance)
	config.set_value("display", "ui_scale", ui_scale)
	config.set_value("display", "field_3d", field_3d)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("general", "language", language)
	config.save(PATH)


## Applique les paramètres à la fenêtre, puis prévient les écouteurs.
func apply() -> void:
	if supports_fullscreen_toggle():
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)
		# En mode fenêtré, appliquer la résolution choisie et recentrer la fenêtre.
		if not fullscreen and DisplayServer.window_get_size() != window_size:
			DisplayServer.window_set_size(window_size)
			var screen := DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
			DisplayServer.window_set_position((screen - window_size) / 2)
	get_tree().root.content_scale_factor = ui_scale
	changed.emit()


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_commit()


func set_window_size(value: Vector2i) -> void:
	window_size = value
	_commit()


func set_crt_effect(value: bool) -> void:
	crt_effect = value
	_commit()


func set_guidance(value: bool) -> void:
	guidance = value
	_commit()


func set_field_3d(value: bool) -> void:
	field_3d = value
	_commit()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_commit()


func set_ui_scale(value: float) -> void:
	ui_scale = value
	_commit()


## Change la langue (Localization l'applique à TranslationServer).
func set_language(code: String) -> void:
	language = code
	Localization.set_locale(code)
	_commit()


## Le plein écran n'a de sens que sur ordinateur (pas en mobile, pas en headless).
func supports_fullscreen_toggle() -> bool:
	return not OS.has_feature("mobile") and DisplayServer.get_name() != "headless"


func _commit() -> void:
	apply()
	save_settings()
