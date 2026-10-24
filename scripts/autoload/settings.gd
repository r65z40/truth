extends Node
## Paramètres utilisateur, stockés séparément de la partie (user://settings.cfg).

signal changed

const PATH := "user://settings.cfg"
const UI_SCALES := [1.0, 1.15, 1.3]

var fullscreen := false
var crt_effect := true
## Agrandit toute l'interface (lisibilité, petits écrans).
var ui_scale := 1.0


func _ready() -> void:
	load_settings()
	apply()


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		return
	fullscreen = config.get_value("display", "fullscreen", fullscreen)
	crt_effect = config.get_value("display", "crt_effect", crt_effect)
	ui_scale = config.get_value("display", "ui_scale", ui_scale)


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "crt_effect", crt_effect)
	config.set_value("display", "ui_scale", ui_scale)
	config.save(PATH)


## Applique les paramètres à la fenêtre, puis prévient les écouteurs.
func apply() -> void:
	if supports_fullscreen_toggle():
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)
	get_tree().root.content_scale_factor = ui_scale
	changed.emit()


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_commit()


func set_crt_effect(value: bool) -> void:
	crt_effect = value
	_commit()


func set_ui_scale(value: float) -> void:
	ui_scale = value
	_commit()


## Le plein écran n'a de sens que sur ordinateur (pas en mobile, pas en headless).
func supports_fullscreen_toggle() -> bool:
	return not OS.has_feature("mobile") and DisplayServer.get_name() != "headless"


func _commit() -> void:
	apply()
	save_settings()
