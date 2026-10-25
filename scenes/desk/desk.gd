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
@onready var evening_screen: EveningScreen = %EveningScreen
@onready var act_review_screen: ActReviewScreen = %ActReviewScreen
@onready var coach: CoachOverlay = %CoachOverlay
@onready var field_screen: FieldScreen = %FieldScreen
@onready var _objective_bar: Control = %ObjectiveBar
@onready var _objective_text: Label = %ObjectiveText
@onready var _objective_hint: Label = %ObjectiveHint
@onready var _toast: Control = %Toast
@onready var _toast_label: Label = %ToastLabel
@onready var _target_buttons: Dictionary = {
	"dossiers": %DossiersButton,
	"messages": %MessagesButton,
	"end_day": %EndDayButton,
}

## Vrai après un premier « FIN » alors qu'un dossier attend : le second confirme.
var _end_day_armed := false
## Vrai après une première « DÉCONNEXION » sans sauvegarde : la seconde confirme.
var _logout_armed := false
## Des changements ont eu lieu depuis la dernière sauvegarde.
var has_unsaved_changes := false
## Objectif conseillé actuellement affiché (voir Guidance).
var current_step: Dictionary = {}
var _pulse_tween: Tween
var _toast_tween: Tween

const TOOLTIPS := {
	"DossiersButton": "Consulter les dossiers qui vous sont assignés.",
	"MessagesButton": "Lire le courrier interne et les réponses de la hiérarchie.",
	"ArchivesButton": "Voir les rapports que vous avez transmis.",
	"PersonnelButton": "Votre évaluation par la Direction du personnel.",
	"EndDayButton": "Terminer la journée : la suite de vos décisions arrive le lendemain.",
	"SaveButton": "Enregistrer la partie.",
	"MenuButton": "Revenir au menu principal.",
}


func _ready() -> void:
	GameState.state_changed.connect(_on_state_changed)
	Settings.changed.connect(_refresh_objective)
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
		window.notify.connect(show_toast)
	for button_name in TOOLTIPS:
		(get_node("%" + button_name) as Control).tooltip_text = TOOLTIPS[button_name]
	_toast.hide()
	_scrim.hide()
	_scrim.gui_input.connect(_on_scrim_input)
	_day_transition.hide()
	coach.target_provider = coach_target
	windows.dossiers.field_requested.connect(open_field)
	field_screen.finished.connect(_on_field_finished)
	_refresh_header()
	_boot_terminal()
	has_unsaved_changes = false


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
		has_unsaved_changes = false
		terminal.print_line("Session enregistrée le %s." % GameState.get_date_short())
		_flash_status("SESSION ENREGISTRÉE")
		show_toast("Partie sauvegardée.")
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


## Quitte le poste : soirée s'il y en a une, revue de fin d'acte, puis jour suivant.
func end_day() -> void:
	_end_day_armed = false
	for window: MinistryWindow in windows.values():
		window.hide()
	_scrim.hide()
	if evening_screen.open():
		await evening_screen.finished
	if act_review_screen.open():
		await act_review_screen.finished
	_start_next_day()


## Passe au jour suivant, sauvegarde automatiquement et affiche la transition.
func _start_next_day() -> void:
	var next_day := GameState.day_index + 1
	var gap := FictionalCalendar.days_since_previous(next_day)
	var ellipsis := "\n\n%d jours plus tard" % gap if gap > 2 else ""
	_day_transition_label.text = "FIN DE SERVICE%s\n\n%s" % [ellipsis, FictionalCalendar.format_long(next_day)]
	_day_transition.modulate.a = 0.0
	_day_transition.show()
	GameState.end_day()
	if SaveManager.save_game() == OK:
		has_unsaved_changes = false
	_boot_terminal()
	terminal.print_line("Session enregistrée automatiquement.", Terminal.COLOR_DIM)
	var tween := create_tween()
	tween.tween_property(_day_transition, "modulate:a", 1.0, 0.4)
	tween.tween_interval(1.4)
	tween.tween_property(_day_transition, "modulate:a", 0.0, 0.6)
	tween.tween_callback(_day_transition.hide)


## Retour au menu. Sans sauvegarde récente, demande une confirmation (seconde commande).
func return_to_menu() -> void:
	if has_unsaved_changes and not _logout_armed:
		_logout_armed = true
		terminal.print_line("ATTENTION : modifications non sauvegardées depuis votre dernier enregistrement.", Terminal.COLOR_ALERT)
		terminal.print_line("Cliquez sur SAUVEGARDER, ou répétez DÉCONNEXION pour quitter sans sauvegarder.", Terminal.COLOR_ALERT)
		return
	terminal.print_line("Fermeture de session...", Terminal.COLOR_DIM)
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


## Affiche brièvement une notification en bas de l'écran.
func show_toast(text: String) -> void:
	_toast_label.text = text
	_toast.show()
	_toast.modulate.a = 1.0
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.8)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.5)
	_toast_tween.tween_callback(_toast.hide)


func _boot_terminal() -> void:
	terminal.boot("%s (%s)" % [GameState.player.name, GameState.player.badge],
			GameState.get_date_long(), GameState.get_unread_count())


func _undecided_case_ids() -> PackedStringArray:
	var ids: PackedStringArray = []
	for case_id in GameState.cases:
		if GameState.can_decide(case_id):
			ids.append(case_id)
	return ids


func _on_state_changed() -> void:
	has_unsaved_changes = true
	_logout_armed = false
	_refresh_header()


## Ligne d'horloge sous la date : heure de service et temps restant.
func clock_line() -> String:
	var hours := GameState.hours_used
	if WorkTime.is_overtime(hours):
		return "%s  //  HEURES SUPPLÉMENTAIRES" % GameState.get_clock_text()
	var left := WorkTime.day_hours() - hours
	if left <= 0:
		return "%s  //  FIN DE SERVICE" % GameState.get_clock_text()
	return "%s  //  %d h de service restantes" % [GameState.get_clock_text(), left]


func _refresh_header() -> void:
	_date_label.text = "%s\n%s" % [GameState.get_date_long(), clock_line()]
	_agent_label.text = "%s  //  %s" % [GameState.player.name, GameState.player.badge]
	_rank_label.text = GameState.get_rank_title().to_upper()
	var unread := GameState.get_unread_count()
	var pending := _undecided_case_ids().size()
	_messages_button.text = "MESSAGES\n" + ("%d non lu(s)" % unread if unread > 0 else "aucun nouveau message")
	%DossiersButton.text = "DOSSIERS\n" + ("%d dossier(s) à traiter" % pending if pending > 0 else "aucun dossier en attente")
	%ArchivesButton.text = "ARCHIVES\n%d rapport(s) transmis" % GameState.decisions.size()
	%PersonnelButton.text = "DOSSIER PERSONNEL\nvotre évaluation"
	%ArchivesButton.visible = GameState.is_feature_unlocked("archives")
	%PersonnelButton.visible = GameState.is_feature_unlocked("personnel")
	terminal.set_advanced_visible(GameState.is_feature_unlocked("terminal_advanced"))
	_refresh_objective()


## Met à jour la barre d'objectif et signale le bouton correspondant.
func _refresh_objective() -> void:
	current_step = Guidance.next_step(GameState.get_condition_state(), GameState.messages)
	_objective_bar.visible = Settings.guidance
	_objective_text.text = current_step.text
	_objective_hint.text = current_step.hint
	coach.visible = Settings.guidance
	if _pulse_tween:
		_pulse_tween.kill()
	for button: Control in _target_buttons.values():
		button.modulate = Color.WHITE
	var target: Control = _target_buttons.get(current_step.target)
	if Settings.guidance and target:
		_pulse_tween = create_tween().set_loops()
		_pulse_tween.tween_property(target, "modulate", Color(0.6, 1.4, 0.8), 0.7)
		_pulse_tween.tween_property(target, "modulate", Color.WHITE, 0.7)


## Part sur le terrain pour ce dossier (interrogatoire ou perquisition).
func open_field(case_id: String) -> void:
	if field_screen.open(case_id):
		terminal.print_line("Départ sur le terrain : %s." % field_screen.scene.get("title", ""))


## Retour du terrain : le dossier se rouvre sur le procès-verbal.
func _on_field_finished() -> void:
	open_app("dossiers")
	windows.dossiers.select_case(field_screen.scene.case_id)
	for document in GameState.get_case_view(field_screen.scene.case_id).documents:
		if document.get("conditions", {}).get("requires_flags", []).has(FieldRules.flag_for(field_screen.scene, "started")):
			windows.dossiers.select_document(document.id)


## Contrôle que la bulle d'aide signale pour l'étape en cours : le bouton de
## l'application, l'endroit précis dans la fenêtre ouverte, ou le bouton FERMER
## d'une autre fenêtre restée ouverte.
func coach_target() -> Control:
	if evening_screen.visible or act_review_screen.visible or field_screen.visible or _day_transition.visible:
		return null
	var app: String = current_step.get("target", "")
	var open := get_open_app()
	if open == "":
		coach.text = current_step.get("coach", "")
		return _target_buttons.get(app)
	if open == app:
		coach.text = current_step.get("coach", "")
		return windows[open].get_guide_target(current_step.get("part", ""), current_step.get("case_id", ""))
	coach.text = "Fermez cette fenêtre pour passer à l'étape suivante."
	return windows[open].get_close_button()


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
