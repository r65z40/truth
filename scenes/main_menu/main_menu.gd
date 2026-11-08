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
## Départ rapide : acte où commence la nouvelle partie (1 : début normal).
var start_act := 1
var _start_act_option: OptionButton


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
	%BeginnerButton.pressed.connect(choose_difficulty.bind(Settings.DIFFICULTY_BEGINNER))
	%ExpertButton.pressed.connect(choose_difficulty.bind(Settings.DIFFICULTY_EXPERT))
	%DifficultyCancelButton.pressed.connect(%DifficultyPanel.hide)
	# Les plateformes mobiles et le web ne permettent pas de quitter l'application soi-même.
	_quit_button.visible = not (OS.has_feature("mobile") or OS.has_feature("web"))
	_settings_window.hide()
	_settings_layer.hide()
	_confirm_panel.hide()
	%DifficultyPanel.hide()
	_build_start_act_row()
	_error_label.text = ""
	refresh()


## Départ rapide, proposé une fois une fin découverte : commencer à l'acte 2, 3 ou 4.
func _build_start_act_row() -> void:
	var row := HBoxContainer.new()
	row.name = "StartActRow"
	row.add_theme_constant_override("separation", 12)
	var label := Label.new()
	label.text = tr("COMMENCER À")
	label.theme_type_variation = &"MutedLabel"
	row.add_child(label)
	_start_act_option = OptionButton.new()
	_start_act_option.name = "StartActOption"
	_start_act_option.custom_minimum_size = Vector2(0, 44)
	_start_act_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for act in FictionalCalendar._data().get("acts", []):
		_start_act_option.add_item(tr("ACTE %d — %s") % [int(act.number), act.title], int(act.number))
	_start_act_option.tooltip_text = tr("Les jours précédents passent seuls : vos dossiers sont conclus selon l'avis de VERITAS.")
	_start_act_option.item_selected.connect(func(index: int) -> void: start_act = _start_act_option.get_item_id(index))
	row.add_child(_start_act_option)
	%DifficultyCancelButton.add_sibling(row)
	%DifficultyCancelButton.get_parent().move_child(row, %DifficultyCancelButton.get_index())


func refresh() -> void:
	_continue_button.disabled = not SaveManager.has_save()
	var summary := SaveManager.read_summary()
	_continue_button.text = tr("CONTINUER") + ("\n" + summary.date if summary.has("date") else "")
	_continue_button.tooltip_text = tr("Reprendre la dernière partie sauvegardée.")
	%NewGameButton.tooltip_text = tr("Commencer votre carrière d'inspecteur, le lundi 3 novembre 1986.")
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
		%EndingsLabel.text = tr("FINS DÉCOUVERTES : 0 / %d") % total
	else:
		%EndingsLabel.text = tr("FINS DÉCOUVERTES : %d / %d
%s") % [titles.size(), total, "  ·  ".join(titles)]


func open_settings() -> void:
	_settings_layer.show()
	_settings_window.open()


func start_new_game() -> void:
	if start_act > 1:
		GameState.new_game_at_act(start_act)
		get_tree().change_scene_to_file(DESK_SCENE)
		return
	GameState.new_game()
	get_tree().change_scene_to_file(INTRO_SCENE)


func continue_game() -> void:
	var error := SaveManager.load_game()
	if error != OK:
		_error_label.text = tr("Sauvegarde illisible (%s). Lancez une nouvelle partie.") % error_string(error)
		return
	get_tree().change_scene_to_file(DESK_SCENE)


## NOUVELLE PARTIE : on choisit d'abord le niveau de difficulté.
func _on_new_game_pressed() -> void:
	start_act = 1
	_start_act_option.select(0)
	_start_act_option.get_parent().visible = not Settings.endings_discovered.is_empty()
	%DifficultyPanel.show()


## Niveau choisi : il est enregistré dans les paramètres (modifiable ensuite),
## puis la partie commence.
func choose_difficulty(level: String) -> void:
	Settings.set_difficulty(level)
	%DifficultyPanel.hide()
	# Une nouvelle partie n'efface la sauvegarde qu'au prochain enregistrement,
	# mais on prévient quand même le joueur.
	if SaveManager.has_save():
		_confirm_panel.show()
	else:
		start_new_game()
