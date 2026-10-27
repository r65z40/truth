extends MinistryWindow
## Fenêtre « Paramètres » : réglages simples, enregistrés par l'autoload Settings.
## Les interrupteurs sont de grands boutons, utilisables à la souris comme au doigt.

@onready var _fullscreen_row: Control = %FullscreenRow
@onready var _fullscreen_toggle: Button = %FullscreenToggle
@onready var _crt_toggle: Button = %CrtToggle
@onready var _guidance_toggle: Button = %GuidanceToggle
@onready var _field_3d_toggle: Button = %Field3dToggle
@onready var _scale_option: OptionButton = %ScaleOption
@onready var _resolution_row: Control = %ResolutionRow
@onready var _resolution_option: OptionButton = %ResolutionOption
@onready var _music_option: OptionButton = %MusicOption
@onready var _ambience_option: OptionButton = %AmbienceOption
@onready var _sfx_option: OptionButton = %SfxOption
@onready var _language_option: OptionButton = %LanguageOption


func _ready() -> void:
	super()
	for scale in Settings.UI_SCALES:
		_scale_option.add_item("%d %%" % roundi(scale * 100))
	_fullscreen_toggle.toggled.connect(func(on: bool) -> void:
		Settings.set_fullscreen(on)
		_refresh_toggle_labels())
	_crt_toggle.toggled.connect(func(on: bool) -> void:
		Settings.set_crt_effect(on)
		_refresh_toggle_labels())
	_guidance_toggle.toggled.connect(func(on: bool) -> void:
		Settings.set_guidance(on)
		_refresh_toggle_labels())
	_field_3d_toggle.toggled.connect(func(on: bool) -> void:
		Settings.set_field_3d(on)
		_refresh_toggle_labels())
	for option: OptionButton in [_music_option, _ambience_option, _sfx_option]:
		for level in Settings.MUSIC_LEVELS:
			option.add_item("Coupé" if level == 0.0 else "%d %%" % roundi(level * 100))
	_music_option.item_selected.connect(func(index: int) -> void: Settings.set_music_volume(Settings.MUSIC_LEVELS[index]))
	_ambience_option.item_selected.connect(func(index: int) -> void: Settings.set_ambience_volume(Settings.MUSIC_LEVELS[index]))
	_sfx_option.item_selected.connect(func(index: int) -> void:
		Settings.set_sfx_volume(Settings.MUSIC_LEVELS[index])
		Sound.play("stamp"))
	_scale_option.item_selected.connect(func(index: int) -> void: Settings.set_ui_scale(Settings.UI_SCALES[index]))
	for size in Settings.WINDOW_SIZES:
		_resolution_option.add_item("%d × %d" % [size.x, size.y])
	_resolution_option.item_selected.connect(func(index: int) -> void: Settings.set_window_size(Settings.WINDOW_SIZES[index]))
	for code in Localization.LOCALES:
		_language_option.add_item(Localization.LOCALE_LABELS.get(code, code))
	_language_option.item_selected.connect(func(index: int) -> void: Settings.set_language(Localization.LOCALES[index]))
	%DoneButton.pressed.connect(close)


func _on_opened() -> void:
	_fullscreen_row.visible = Settings.supports_fullscreen_toggle()
	_resolution_row.visible = Settings.supports_fullscreen_toggle()
	_resolution_option.select(maxi(Settings.WINDOW_SIZES.find(Settings.window_size), 0))
	_fullscreen_toggle.set_pressed_no_signal(Settings.fullscreen)
	_crt_toggle.set_pressed_no_signal(Settings.crt_effect)
	_guidance_toggle.set_pressed_no_signal(Settings.guidance)
	_field_3d_toggle.set_pressed_no_signal(Settings.field_3d)
	_scale_option.select(maxi(Settings.UI_SCALES.find(Settings.ui_scale), 0))
	_music_option.select(_closest_level(Settings.music_volume))
	_ambience_option.select(_closest_level(Settings.ambience_volume))
	_sfx_option.select(_closest_level(Settings.sfx_volume))
	_language_option.select(maxi(Localization.LOCALES.find(Settings.language), 0))
	_refresh_toggle_labels()


func _refresh_toggle_labels() -> void:
	for toggle: Button in [_fullscreen_toggle, _crt_toggle, _guidance_toggle, _field_3d_toggle]:
		toggle.text = "ACTIVÉ" if toggle.button_pressed else "DÉSACTIVÉ"


## Cran de volume le plus proche du réglage enregistré.
func _closest_level(volume: float) -> int:
	var best := 0
	for i in Settings.MUSIC_LEVELS.size():
		if absf(Settings.MUSIC_LEVELS[i] - volume) < absf(Settings.MUSIC_LEVELS[best] - volume):
			best = i
	return best
