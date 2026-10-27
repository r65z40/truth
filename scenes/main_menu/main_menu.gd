extends Control
## Menu principal : nouvelle partie, continuer, paramètres, quitter.

const DESK_SCENE := "res://scenes/desk/desk.tscn"
const INTRO_SCENE := "res://scenes/intro/intro.tscn"
const GALLERY_SCENE := "res://scenes/debug/scene_gallery.tscn"

@onready var _continue_button: Button = %ContinueButton
@onready var _quit_button: Button = %QuitButton
@onready var _settings_window: MinistryWindow = %SettingsWindow
@onready var _settings_layer: Control = %SettingsLayer
@onready var _confirm_panel: Control = %ConfirmPanel
@onready var _error_label: Label = %ErrorLabel


func _ready() -> void:
	Music.play_context("menu")
	%MenuBackground.texture = ImageSlots.texture("menu_background")
	%NewGameButton.pressed.connect(_on_new_game_pressed)
	_continue_button.pressed.connect(continue_game)
	%SettingsButton.pressed.connect(open_settings)
	%GalleryButton.pressed.connect(func() -> void: get_tree().change_scene_to_file(GALLERY_SCENE))
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
	var summary := SaveManager.read_summary()
	_continue_button.text = "CONTINUER" + ("\n" + summary.date if summary.has("date") else "")
	_continue_button.tooltip_text = "Reprendre la dernière partie sauvegardée."
	%NewGameButton.tooltip_text = "Commencer votre carrière d'inspecteur, le lundi 3 novembre 1986."
	_refresh_endings()


## Compteur « fins découvertes X/7 » : les fins déjà atteintes (persistées dans
## les paramètres), les autres restent cachées. Rien tant qu'aucune n'est connue.
func _refresh_endings() -> void:
	var total := EndingRules.get_endings().size()
	var discovered: Array = Settings.endings_discovered
	var titles: PackedStringArray = []
	for ending in EndingRules.get_endings():
		if ending.get("id", "") in discovered:
			titles.append(ending.get("title", ""))
	if titles.is_empty():
		%EndingsLabel.text = "FINS DÉCOUVERTES : 0 / %d" % total
	else:
		%EndingsLabel.text = "FINS DÉCOUVERTES : %d / %d\n%s" % [titles.size(), total, "  ·  ".join(titles)]


func open_settings() -> void:
	_settings_layer.show()
	_settings_window.open()


func start_new_game() -> void:
	GameState.new_game()
	get_tree().change_scene_to_file(INTRO_SCENE)


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
