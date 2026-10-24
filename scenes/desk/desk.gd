extends Control
## Bureau de l'inspecteur : poste de travail principal.
##
## Orchestre l'en-tête (date, identité, grade), le terminal, les raccourcis
## latéraux et les fenêtres (Dossiers, Messages, Archives). Ne contient aucune
## règle de jeu : il lit GameState et délègue la sauvegarde à SaveManager.

const MAIN_MENU_SCENE := "res://scenes/main_menu/main_menu.tscn"

@onready var terminal: Terminal = %Terminal
@onready var windows: Dictionary = {
	"dossiers": %DossiersWindow,
	"messages": %MessagesWindow,
	"archives": %ArchivesWindow,
	"personnel": %PersonnelWindow,
}

@onready var _date_label: Label = %DateLabel
@onready var _agent_label: Label = %AgentLabel
@onready var _rank_label: Label = %RankLabel
@onready var _messages_button: Button = %MessagesButton
@onready var _status_label: Label = %StatusLabel
@onready var _scrim: ColorRect = %Scrim
@onready var _day_transition: ColorRect = %DayTransition
@onready var _day_transition_label: Label = %DayTransitionLabel

## Vrai après un premier « FIN » alors qu'un dossier attend : le second confirme.
var _end_day_armed := false


func _ready() -> void:
	GameState.state_changed.connect(_refresh_header)
	GameState.decision_applied.connect(_on_decision_applied)
	terminal.app_requested.connect(open_app)
	terminal.save_requested.connect(save_game)
	terminal.menu_requested.connect(return_to_menu)
	terminal.end_day_requested.connect(request_end_day)
	%DossiersButton.pressed.connect(terminal.submit_command.bind("DOSSIERS"))
	_messages_button.pressed.connect(terminal.submit_command.bind("MESSAGES"))
	%ArchivesButton.pressed.connect(terminal.submit_command.bind("ARCHIVES"))
	%PersonnelButton.pressed.connect(terminal.submit_command.bind("PROFIL"))
	%SaveButton.pressed.connect(terminal.submit_command.bind("SAUVER"))
	%MenuButton.pressed.connect(terminal.submit_command.bind("MENU"))
	%EndDayButton.pressed.connect(terminal.submit_command.bind("FIN"))
	for window: MinistryWindow in windows.values():
		window.hide()
		window.closed.connect(_on_window_closed)
	_scrim.hide()
	_scrim.gui_input.connect(_on_scrim_input)
	_day_transition.hide()
	_refresh_header()
	_boot_terminal()


## Ouvre une fenêtre par son nom ("dossiers", "messages", "archives").
func open_app(app_name: String) -> void:
	if not windows.has(app_name):
		push_warning("Desk: application inconnue : %s" % app_name)
		return
	for other_name in windows:
		if other_name != app_name:
			windows[other_name].hide()
	_scrim.show()
	windows[app_name].open()


func get_open_app() -> String:
	for app_name in windows:
		if windows[app_name].visible:
			return app_name
	return ""


func save_game() -> void:
	if SaveManager.save_game() == OK:
		terminal.print_line("Session enregistrée le %s." % GameState.get_date_short())
		_flash_status("SESSION ENREGISTRÉE")
	else:
		terminal.print_line("ÉCHEC DE L'ENREGISTREMENT.", Terminal.COLOR_ALERT)


## Termine la journée. Si un dossier attend une conclusion, demande une confirmation
## (une seconde commande FIN), car la hiérarchie remarquera le retard.
func request_end_day() -> void:
	var pending := _undecided_case_ids()
	if not pending.is_empty() and not _end_day_armed:
		_end_day_armed = true
		terminal.print_line("ATTENTION : dossier(s) sans conclusion : %s." % ", ".join(pending), Terminal.COLOR_ALERT)
		terminal.print_line("Répétez FIN pour quitter votre poste malgré tout.", Terminal.COLOR_ALERT)
		return
	end_day()


## Passe au jour suivant, sauvegarde automatiquement et affiche la transition.
func end_day() -> void:
	_end_day_armed = false
	for window: MinistryWindow in windows.values():
		window.hide()
	_scrim.hide()
	_day_transition_label.text = "FIN DE SERVICE\n\n%s" % FictionalCalendar.format_long(GameState.day_index + 1)
	_day_transition.modulate.a = 0.0
	_day_transition.show()
	GameState.end_day()
	SaveManager.save_game()
	_boot_terminal()
	terminal.print_line("Session enregistrée automatiquement.", Terminal.COLOR_DIM)
	var tween := create_tween()
	tween.tween_property(_day_transition, "modulate:a", 1.0, 0.4)
	tween.tween_interval(1.4)
	tween.tween_property(_day_transition, "modulate:a", 0.0, 0.6)
	tween.tween_callback(_day_transition.hide)


func return_to_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _boot_terminal() -> void:
	terminal.boot("%s (%s)" % [GameState.player.name, GameState.player.badge],
			GameState.get_date_long(), GameState.get_unread_count())


func _undecided_case_ids() -> PackedStringArray:
	var ids: PackedStringArray = []
	for case_id in GameState.cases:
		if GameState.can_decide(case_id):
			ids.append(case_id)
	return ids


func _refresh_header() -> void:
	_date_label.text = GameState.get_date_long()
	_agent_label.text = "%s  //  %s" % [GameState.player.name, GameState.player.badge]
	_rank_label.text = GameState.get_rank_title().to_upper()
	var unread := GameState.get_unread_count()
	_messages_button.text = "MESSAGES" + ("   (%d)" % unread if unread > 0 else "")


## Après la signature d'un rapport : la réponse du supérieur s'affiche aussitôt.
func _on_decision_applied(case_id: String, _decision_id: String, message_id: String) -> void:
	_end_day_armed = false
	terminal.print_line("Rapport n° %s transmis à la hiérarchie." % case_id)
	terminal.print_line("Nouveau message reçu.", Terminal.COLOR_ALERT)
	open_app("messages")
	windows.messages.select_message(message_id)


func _on_window_closed() -> void:
	if get_open_app() == "":
		_scrim.hide()
		terminal.focus_input()


func _on_scrim_input(event: InputEvent) -> void:
	# Toucher ou cliquer à côté d'une fenêtre la ferme.
	if event is InputEventMouseButton and event.pressed:
		var open_name := get_open_app()
		if open_name != "":
			windows[open_name].close()


func _flash_status(text: String) -> void:
	_status_label.text = text
	var tween := create_tween()
	_status_label.modulate = Color(0.235, 0.878, 0.478)
	tween.tween_property(_status_label, "modulate", Color.WHITE, 1.5)
	tween.tween_callback(func() -> void: _status_label.text = "LIAISON SÉCURISÉE  //  TOUTE ACTIVITÉ EST ENREGISTRÉE")
