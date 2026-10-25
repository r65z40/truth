class_name VeritasWindow
extends MinistryWindow
## Programme VERITAS : l'agent choisit un dossier en attente et lance l'analyse.
## Après un court calcul (pur décor, sans coût en heures), VERITAS donne sa
## recommandation, son indice de conformité et ses facteurs principaux.
##
## Tout vient de Veritas (scripts/core) : la fenêtre n'invente rien.

## Durée du calcul affiché, en secondes (0 : résultat immédiat, pour les tests).
@export var analysis_time := 1.8

var current_case_id := ""
var is_running := false

var _tween: Tween

@onready var _case_list: VBoxContainer = %VeritasCaseList
@onready var _case_title: Label = %VeritasCaseTitle
@onready var _run_button: Button = %RunButton
@onready var _progress: ProgressBar = %AnalysisProgress
@onready var _log: RichTextLabel = %AnalysisLog


func _ready() -> void:
	super()
	_run_button.pressed.connect(func() -> void: run_analysis(current_case_id))
	GameState.state_changed.connect(func() -> void:
		if is_open():
			_refresh_cases())


func _on_opened() -> void:
	_refresh_cases()


## Dossiers sur lesquels VERITAS peut se prononcer : ceux qui attendent une conclusion.
static func pending_case_ids() -> PackedStringArray:
	var ids: PackedStringArray = []
	for case_id in GameState.cases:
		if GameState.cases[case_id].decision == "":
			ids.append(case_id)
	return ids


func select_case(case_id: String) -> void:
	if is_running:
		return
	current_case_id = case_id
	var case_data := CaseLibrary.get_case(case_id)
	_case_title.text = "DOSSIER N° %s  //  %s" % [case_id, case_data.get("subject_name", "?")]
	_progress.value = 0
	_log.text = "Dossier chargé. Lancez l'analyse quand vous le souhaitez."
	_refresh_cases()


## Lance le calcul sur un dossier, puis affiche le rapport.
func run_analysis(case_id: String) -> void:
	if case_id == "" or is_running:
		return
	if case_id != current_case_id:
		select_case(case_id)
	is_running = true
	_run_button.disabled = true
	_log.text = ""
	var steps := Veritas.analysis_steps()
	if analysis_time <= 0.0:
		_finish()
		return
	if _tween:
		_tween.kill()
	_tween = create_tween()
	var step_time := analysis_time / maxf(steps.size(), 1)
	for i in steps.size():
		_tween.tween_callback(_log.append_text.bind("> %s...\n" % steps[i]))
		_tween.tween_property(_progress, "value", 100.0 * (i + 1) / steps.size(), step_time)
	_tween.tween_callback(_finish)


## Texte du rapport de VERITAS sur un dossier, en BBCode. Statique pour être testé.
## alert_color : couleur hexadécimale de l'avertissement (tirée du thème).
static func report_bbcode(report: Dictionary, alert_color := "") -> String:
	var lines: PackedStringArray = []
	if report.unread > 0:
		var warning := "ANALYSE INCOMPLÈTE : %d pièce(s) non consultée(s). Je recommande une lecture complète avant toute conclusion." % report.unread
		lines.append("[color=#%s]%s[/color]" % [alert_color, warning] if alert_color != "" else warning)
		lines.append("")
	var advice: Dictionary = report.advice
	if advice.is_empty():
		lines.append("Aucun facteur exploitable dans ce dossier. VERITAS ne formule pas de recommandation.")
		return "\n".join(lines)
	lines.append("[b]RECOMMANDATION :[/b] %s" % advice.label.to_upper())
	lines.append("[b]INDICE DE CONFORMITÉ :[/b] %d / 99" % advice.confidence)
	lines.append("")
	lines.append(str(advice.rationale).replace("[", "[lb]"))
	lines.append("")
	lines.append("[b]FACTEURS PRINCIPAUX :[/b]")
	for factor in report.factors:
		lines.append("- " + factor.replace("[", "[lb]"))
	lines.append("")
	lines.append("La responsabilité de la conclusion incombe à l'agent signataire.")
	return "\n".join(lines)


func _finish() -> void:
	is_running = false
	_run_button.disabled = false
	_progress.value = 100
	var show_multipliers: bool = GameState.flags.get(Veritas.PARAMS_FLAG, false) == true
	var report := Veritas.case_report(GameState.get_case_view(current_case_id),
			GameState.get_case_state(current_case_id), show_multipliers, GameState.flags)
	_log.text = report_bbcode(report, get_theme_color(&"font_color", &"StampLabel").to_html(false))
	notify.emit("VERITAS : analyse du dossier %s terminée." % current_case_id)


func _refresh_cases() -> void:
	for child in _case_list.get_children():
		_case_list.remove_child(child)
		child.queue_free()
	var ids := pending_case_ids()
	if current_case_id != "" and not current_case_id in ids and not is_running:
		current_case_id = ""
	for case_id in ids:
		var button := Button.new()
		button.name = "Case_" + case_id
		button.text = "N° %s\n%s" % [case_id, CaseLibrary.get_case(case_id).get("subject_name", "?")]
		button.icon = PixelIcons.get_icon("dossiers", 2)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_pressed = case_id == current_case_id
		button.custom_minimum_size = Vector2(0, 56)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(select_case.bind(case_id))
		_case_list.add_child(button)
	if ids.is_empty():
		var empty := Label.new()
		empty.theme_type_variation = &"MutedLabel"
		empty.text = "Aucun dossier en attente."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_case_list.add_child(empty)
	if current_case_id == "":
		_case_title.text = "AUCUN DOSSIER CHARGÉ"
		if not is_running:
			_log.text = "Choisissez un dossier à gauche, puis lancez l'analyse."
			_progress.value = 0
	_run_button.disabled = current_case_id == "" or is_running
