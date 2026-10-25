extends Control
## Bureau de l'inspecteur : l'ordinateur du ministère.
##
## Un fond, une colonne d'icônes, des fenêtres qu'on ouvre, déplace et réduit
## (WindowManager) et une barre des tâches (menu MINISTÈRE, fenêtres ouvertes,
## fin de service, heures restantes, date). Ne contient aucune règle de jeu :
## il lit GameState et délègue la sauvegarde à SaveManager.

const MAIN_MENU_SCENE := "res://scenes/main_menu/main_menu.tscn"
const DOCUMENT_WINDOW_SCENE := preload("res://scenes/ui/windows/document_window.tscn")
## Décalage entre deux pièces ouvertes à part, pour qu'elles ne se cachent pas.
const DOCUMENT_CASCADE := Vector2(32, 32)

@onready var terminal: Terminal = %TerminalWindow.get_node("%Terminal")
@onready var windows: Dictionary = {
	"dossiers": %DossiersWindow,
	"messages": %MessagesWindow,
	"archives": %ArchivesWindow,
	"personnel": %PersonnelWindow,
	"veritas": %VeritasWindow,
	"news": %NewsWindow,
	"terminal": %TerminalWindow,
	"settings": %SettingsWindow,
}
@onready var window_manager: WindowManager = %WindowLayer

@onready var _date_label: Label = %DateLabel
@onready var _hours_label: Label = %HoursLabel
@onready var _time_gauge: ProgressBar = %TimeGauge
@onready var _agent_label: Label = %AgentLabel
@onready var _rank_label: Label = %RankLabel
@onready var _messages_button: DesktopIcon = %MessagesButton
@onready var _start_button: Button = %StartButton
@onready var _start_menu: Control = %StartMenu
@onready var _task_buttons: HBoxContainer = %TaskButtons
@onready var _day_transition: ColorRect = %DayTransition
@onready var _day_transition_label: Label = %DayTransitionLabel
@onready var evening_screen: EveningScreen = %EveningScreen
@onready var act_review_screen: ActReviewScreen = %ActReviewScreen
@onready var coach: CoachOverlay = %CoachOverlay
@onready var field_screen: FieldScreen = %FieldScreen
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
## Jour de la dernière édition du journal ouverte (pastille « nouvelle édition »).
## Non sauvegardé : après un chargement, la pastille revient, c'est sans conséquence.
var news_read_day := -1
## Des changements ont eu lieu depuis la dernière sauvegarde.
var has_unsaved_changes := false
## Objectif conseillé actuellement affiché (voir Guidance).
var current_step: Dictionary = {}
var _pulse_tween: Tween
var _toast_tween: Tween

const TOOLTIPS := {
	"DossiersButton": "Consulter les dossiers qui vous sont assignés.",
	"MessagesButton": "Lire le courrier interne et les réponses de la hiérarchie.",
	"NewsButton": "Le journal du matin, La Voix de Velmira. Le lire ne coûte pas d'heures.",
	"VeritasButton": "VERITAS, le système d'analyse : il recommande une conclusion pour un dossier.",
	"ArchivesButton": "Voir les rapports que vous avez transmis.",
	"PersonnelButton": "Votre évaluation par la Direction du personnel.",
	"TerminalButton": "Le terminal du ministère, pour les commandes tapées au clavier.",
	"StartButton": "Menu du ministère : identité, terminal, paramètres, sauvegarde.",
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
	%TerminalButton.pressed.connect(open_app.bind("terminal"))
	%VeritasButton.pressed.connect(open_app.bind("veritas"))
	%NewsButton.pressed.connect(open_news)
	%SaveButton.pressed.connect(terminal.submit_command.bind("SAUVER"))
	%MenuButton.pressed.connect(terminal.submit_command.bind("MENU"))
	%EndDayButton.pressed.connect(terminal.submit_command.bind("FIN"))
	_start_button.toggled.connect(_start_menu.set_visible)
	%StartPersonnel.pressed.connect(terminal.submit_command.bind("PROFIL"))
	%StartTerminal.pressed.connect(open_app.bind("terminal"))
	%StartSettings.pressed.connect(open_app.bind("settings"))
	for item: Button in _start_menu.find_children("*", "Button", true, false):
		item.pressed.connect(close_start_menu)
	for window: MinistryWindow in windows.values():
		window.hide()
		window.closed.connect(_on_window_closed)
		window.notify.connect(show_toast)
	window_manager.windows_changed.connect(_refresh_taskbar)
	_task_buttons.get_parent().resized.connect(func() -> void:
		for button: Button in _task_buttons.get_children():
			button.custom_minimum_size.x = _task_button_width())
	for button_name in TOOLTIPS:
		(get_node("%" + button_name) as Control).tooltip_text = TOOLTIPS[button_name]
	_toast.hide()
	_day_transition.hide()
	coach.target_provider = coach_target
	windows.dossiers.field_requested.connect(open_field)
	windows.dossiers.document_window_requested.connect(open_document_window)
	windows.dossiers.veritas_requested.connect(open_veritas)
	windows.archives.case_requested.connect(open_case)
	field_screen.finished.connect(_on_field_finished)
	_refresh_header()
	_boot_terminal()
	Music.play_context("desk")
	has_unsaved_changes = false


## Ouvre une fenêtre par son nom ("dossiers", "messages", "archives"...) et la
## passe au premier plan ; les autres fenêtres restent ouvertes derrière.
func open_app(app_name: String) -> void:
	if not windows.has(app_name):
		push_warning("Desk: application inconnue : %s" % app_name)
		return
	close_start_menu()
	windows[app_name].open()


## Application de la fenêtre au premier plan ("" si aucune n'est à l'écran).
func get_open_app() -> String:
	var focused := window_manager.get_focused()
	for app_name in windows:
		if windows[app_name] == focused:
			return app_name
	return ""


func is_app_open(app_name: String) -> bool:
	return windows.has(app_name) and windows[app_name].is_open()


func close_start_menu() -> void:
	_start_button.set_pressed_no_signal(false)
	_start_menu.hide()


func save_game() -> void:
	if SaveManager.save_game() == OK:
		has_unsaved_changes = false
		terminal.print_line("Session enregistrée le %s." % GameState.get_date_short())
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
		show_toast("Dossier(s) sans conclusion : %s.\nCliquez encore sur FIN DE SERVICE pour partir malgré tout." % ", ".join(pending), 4.0)
		return
	end_day()


## Quitte le poste : soirée s'il y en a une, revue de fin d'acte, puis jour suivant.
func end_day() -> void:
	_end_day_armed = false
	close_start_menu()
	window_manager.close_all()
	if evening_screen.open():
		Music.play_context("evening")
		await evening_screen.finished
	if act_review_screen.open():
		Music.play_context("act_review")
		await act_review_screen.finished
	_start_next_day()
	Music.play_context("desk")


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
		show_toast("Modifications non sauvegardées.\nSauvegardez, ou choisissez encore Déconnexion pour quitter.", 4.0)
		return
	terminal.print_line("Fermeture de session...", Terminal.COLOR_DIM)
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


## Affiche brièvement une notification en bas de l'écran.
func show_toast(text: String, duration := 1.8) -> void:
	_toast_label.text = text
	_toast.show()
	_toast.modulate.a = 1.0
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(duration)
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


## Ligne d'horloge : heure de service et temps restant (terminal, fin de journée).
func clock_line() -> String:
	return "%s  //  %s" % [GameState.get_clock_text(), hours_text()]


## Temps de service restant, pour la barre des tâches.
func hours_text() -> String:
	var hours := GameState.hours_used
	if WorkTime.is_overtime(hours):
		return "HEURES SUPPLÉMENTAIRES"
	var left := WorkTime.day_hours() - hours
	if left <= 0:
		return "FIN DE SERVICE"
	return "%d h restantes" % left


func _refresh_header() -> void:
	_date_label.text = "%s  %s" % [FictionalCalendar.format_compact(GameState.day_index), GameState.get_clock_text()]
	_hours_label.text = hours_text()
	_time_gauge.max_value = WorkTime.day_hours()
	_time_gauge.value = WorkTime.day_hours() - mini(GameState.hours_used, WorkTime.day_hours())
	_agent_label.text = "%s  //  %s" % [GameState.player.name, GameState.player.badge]
	_rank_label.text = GameState.get_rank_title().to_upper()
	var unread := GameState.get_unread_count()
	var pending := _undecided_case_ids().size()
	_messages_button.badge = unread
	_messages_button.tooltip_text = "%s\n%s" % [TOOLTIPS.MessagesButton,
			"%d message(s) non lu(s)." % unread if unread > 0 else "Aucun nouveau message."]
	%DossiersButton.badge = pending
	%DossiersButton.tooltip_text = "%s\n%s" % [TOOLTIPS.DossiersButton,
			"%d dossier(s) à traiter." % pending if pending > 0 else "Aucun dossier en attente."]
	%NewsButton.badge = 0 if news_read_day == GameState.day_index else 1
	%ArchivesButton.visible = GameState.is_feature_unlocked("archives")
	%PersonnelButton.visible = GameState.is_feature_unlocked("personnel")
	%StartPersonnel.visible = %PersonnelButton.visible
	terminal.set_advanced_visible(GameState.is_feature_unlocked("terminal_advanced"))
	_refresh_objective()


## Met à jour l'aide : la bulle et l'icône signalée clignotent doucement.
func _refresh_objective() -> void:
	current_step = Guidance.next_step(GameState.get_condition_state(), GameState.messages)
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


## Un bouton par fenêtre ouverte dans la barre des tâches ; enfoncé pour celle
## au premier plan. Un clic la ressort, la passe devant ou la réduit.
func _refresh_taskbar() -> void:
	for child in _task_buttons.get_children():
		child.queue_free()
	var focused := window_manager.get_focused()
	for window in window_manager.get_open_windows():
		var button := Button.new()
		button.name = "Task_" + window.name
		button.text = window.short_title()
		button.icon = PixelIcons.get_icon(window.app_icon, 2) if window.app_icon != "" else null
		button.theme_type_variation = &"TaskButton"
		button.toggle_mode = true
		button.button_pressed = window == focused
		button.custom_minimum_size = Vector2(_task_button_width(), 44)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(window_manager.toggle_from_taskbar.bind(window))
		_task_buttons.add_child(button)


## Largeur des boutons de la barre des tâches : ils se partagent la place libre.
func _task_button_width() -> float:
	var row := _task_buttons.get_parent() as HBoxContainer
	var free := row.size.x
	for child: Control in row.get_children():
		if child != _task_buttons:
			free -= child.size.x + row.get_theme_constant("separation")
	var count := maxi(window_manager.get_open_windows().size(), 1)
	return clampf(free / count - 4.0, 56.0, 190.0)


func _input(event: InputEvent) -> void:
	# Le menu MINISTÈRE se referme quand on clique ailleurs.
	if _start_menu.visible and event is InputEventMouseButton and event.pressed:
		if not _start_menu.get_global_rect().has_point(event.global_position) \
				and not _start_button.get_global_rect().has_point(event.global_position):
			close_start_menu()


## Ouvre une pièce dans sa propre fenêtre, à droite de la zone de travail,
## ou ramène devant celle qui est déjà ouverte.
func open_document_window(case_id: String, document_id: String) -> DocumentWindow:
	for window in window_manager.get_windows():
		if window is DocumentWindow and window.case_id == case_id and window.document_id == document_id:
			window.open()
			return window
	var window: DocumentWindow = DOCUMENT_WINDOW_SCENE.instantiate()
	window.notify.connect(show_toast)
	window_manager.add_window(window)
	window.setup(case_id, document_id)
	window.open()
	var others := window_manager.get_windows().filter(func(w: MinistryWindow) -> bool: return w is DocumentWindow).size() - 1
	window.size = Vector2(minf(620.0, window_manager.size.x * 0.55), window_manager.size.y * 0.85)
	window.position = Vector2(window_manager.size.x - window.size.x - 16.0, 16.0) + DOCUMENT_CASCADE * (others % 5) * Vector2(-1, 1)
	window.clamp_to_parent()
	return window


## Ouvre le journal du jour ; la pastille disparaît jusqu'au lendemain.
func open_news() -> void:
	news_read_day = GameState.day_index
	open_app("news")
	_refresh_header()


## Lance VERITAS sur un dossier (depuis le formulaire de conclusion).
func open_veritas(case_id: String) -> void:
	open_app("veritas")
	windows.veritas.run_analysis(case_id)


## Ouvre le classeur des dossiers sur un dossier précis (depuis les archives).
func open_case(case_id: String) -> void:
	open_app("dossiers")
	windows.dossiers.select_case(case_id)


## Part sur le terrain pour ce dossier (interrogatoire ou perquisition).
func open_field(case_id: String) -> void:
	if field_screen.open(case_id):
		Music.play_context("field_" + field_screen.scene.get("type", "search"))
		terminal.print_line("Départ sur le terrain : %s." % field_screen.scene.get("title", ""))


## Retour du terrain : le dossier se rouvre sur le procès-verbal.
func _on_field_finished() -> void:
	Music.play_context("desk")
	open_app("dossiers")
	windows.dossiers.select_case(field_screen.scene.case_id)
	for document in GameState.get_case_view(field_screen.scene.case_id).documents:
		if document.get("conditions", {}).get("requires_flags", []).has(FieldRules.flag_for(field_screen.scene, "started")):
			windows.dossiers.select_document(document.id)


## Contrôle que la bulle d'aide signale pour l'étape en cours : l'endroit précis
## dans la fenêtre de l'application si elle est au premier plan, sinon son icône.
func coach_target() -> Control:
	if evening_screen.visible or act_review_screen.visible or field_screen.visible or _day_transition.visible:
		return null
	var app: String = current_step.get("target", "")
	if windows.has(app) and windows[app].visible:
		var window: MinistryWindow = windows[app]
		if window != window_manager.get_focused():
			# Fenêtre cachée derrière une autre : son icône la ramène devant.
			coach.text = current_step.get("coach", "")
			return _target_buttons.get(app)
		var window_text: String = window.get_guide_text(current_step.get("part", ""), current_step.get("case_id", ""))
		coach.text = window_text if window_text != "" else current_step.get("coach", "")
		return window.get_guide_target(current_step.get("part", ""), current_step.get("case_id", ""))
	coach.text = current_step.get("coach", "")
	return _target_buttons.get(app)


## Après la signature d'un rapport : la réponse du supérieur s'affiche aussitôt.
func _on_decision_applied(case_id: String, _decision_id: String, message_id: String) -> void:
	_end_day_armed = false
	terminal.print_line("Rapport n° %s transmis à la hiérarchie." % case_id)
	terminal.print_line("Nouveau message reçu.", Terminal.COLOR_ALERT)
	open_app("messages")
	windows.messages.select_message(message_id)


func _on_window_closed() -> void:
	if get_open_app() == "terminal":
		terminal.focus_input()
