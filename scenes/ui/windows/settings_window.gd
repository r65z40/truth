extends MinistryWindow
## Fenêtre « Paramètres » : réglages simples, enregistrés par l'autoload Settings.
## Les interrupteurs sont de grands boutons, utilisables à la souris comme au doigt.

@onready var _fullscreen_row: Control = %FullscreenRow
@onready var _fullscreen_toggle: Button = %FullscreenToggle
@onready var _crt_toggle: Button = %CrtToggle
@onready var _guidance_toggle: Button = %GuidanceToggle
@onready var _scale_option: OptionButton = %ScaleOption


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
	_scale_option.item_selected.connect(func(index: int) -> void: Settings.set_ui_scale(Settings.UI_SCALES[index]))
	%DoneButton.pressed.connect(close)


func _on_opened() -> void:
	_fullscreen_row.visible = Settings.supports_fullscreen_toggle()
	_fullscreen_toggle.set_pressed_no_signal(Settings.fullscreen)
	_crt_toggle.set_pressed_no_signal(Settings.crt_effect)
	_guidance_toggle.set_pressed_no_signal(Settings.guidance)
	_scale_option.select(maxi(Settings.UI_SCALES.find(Settings.ui_scale), 0))
	_refresh_toggle_labels()


func _refresh_toggle_labels() -> void:
	for toggle: Button in [_fullscreen_toggle, _crt_toggle, _guidance_toggle]:
		toggle.text = "ACTIVÉ" if toggle.button_pressed else "DÉSACTIVÉ"
