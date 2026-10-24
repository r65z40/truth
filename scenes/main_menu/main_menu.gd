extends Control
## Menu principal : nouvelle partie, continuer, paramètres, quitter.

const DESK_SCENE := "res://scenes/desk/desk.tscn"

@onready var _continue_button: Button = %ContinueButton
@onready var _quit_button: Button = %QuitButton
@onready var _settings_window: MinistryWindow = %SettingsWindow
@onready var _settings_layer: Control = %SettingsLayer
@onready var _confirm_panel: Control = %ConfirmPanel
@onready var _error_label: Label = %ErrorLabel


func _ready() -> void:
	%NewGameButton.pressed.connect(_on_new_game_pressed)
	_continue_button.pressed.connect(continue_game)
	%SettingsButton.pressed.connect(open_settings)
	_settings_window.closed.connect(_settings_layer.hide)
	_quit_button.pressed.connect(func() -> void: get_tree().quit())
	%ConfirmYesButton.pressed.connect(start_new_game)
	%ConfirmNoButton.pressed.connect(_confirm_panel.hide)
	# Les plateformes mobiles et le web ne permettent pas de quitter l'application soi-même.
	_quit_button.visible = not (OS.has_feature("mobile") or OS.has_feature("web"))
	_settings_window.hide()
	_settings_layer.hide()
	_confirm_panel.hide()
	_error_label.text = ""
	refresh()


func refresh() -> void:
	_continue_button.disabled = not SaveManager.has_save()


func open_settings() -> void:
	_settings_layer.show()
	_settings_window.open()


func start_new_game() -> void:
	GameState.new_game()
	get_tree().change_scene_to_file(DESK_SCENE)


func continue_game() -> void:
	var error := SaveManager.load_game()
	if error != OK:
		_error_label.text = "Sauvegarde illisible (%s). Lancez une nouvelle partie." % error_string(error)
		return
	get_tree().change_scene_to_file(DESK_SCENE)


func _on_new_game_pressed() -> void:
	# Une nouvelle partie n'efface la sauvegarde qu'au prochain enregistrement,
	# mais on prévient quand même le joueur.
	if SaveManager.has_save():
		_confirm_panel.show()
	else:
		start_new_game()
