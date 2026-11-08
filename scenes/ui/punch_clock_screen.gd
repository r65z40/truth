class_name PunchClockScreen
extends ColorRect
## La pointeuse : le ruban d'octobre, jour par jour, à côté des certificats.
## L'agent touche les jours où le ruban dément un certificat puis vérifie.
## Aucune règle ici : GameState.apply_punch_clock décide.

signal closed

var case_id := ""
var selected: Array = []

var _title: Label
var _intro: Label
var _rows: VBoxContainer
var _feedback: Label
var _check_button: Button


func _init() -> void:
	name = "PunchClockScreen"
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Même voile que les autres écrans posés sur le bureau (frise, comparaison).
	color = Color(0.02, 0.025, 0.022, 0.88)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var card := PanelContainer.new()
	card.theme_type_variation = &"DocumentPanel"
	card.custom_minimum_size = Vector2(820, 0)
	center.add_child(card)
	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 22)
	card.add_child(pad)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	pad.add_child(column)
	var kicker := Label.new()
	kicker.theme_type_variation = &"MutedLabel"
	kicker.text = "POINTEUSE"
	column.add_child(kicker)
	_title = _label(column, &"HeaderLabel")
	_intro = _label(column, &"MutedLabel")
	_rows = VBoxContainer.new()
	_rows.name = "Rows"
	_rows.add_theme_constant_override("separation", 6)
	column.add_child(_rows)
	_feedback = _label(column, &"DocumentLabel")
	_feedback.name = "FeedbackLabel"
	var buttons := HFlowContainer.new()
	buttons.add_theme_constant_override("h_separation", 10)
	column.add_child(buttons)
	_check_button = Button.new()
	_check_button.name = "CheckButton"
	_check_button.text = "VÉRIFIER"
	_check_button.theme_type_variation = &"AlertButton"
	_check_button.custom_minimum_size = Vector2(0, 48)
	_check_button.pressed.connect(check)
	buttons.add_child(_check_button)
	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "FERMER"
	close_button.custom_minimum_size = Vector2(0, 48)
	close_button.pressed.connect(close)
	buttons.add_child(close_button)


func _label(parent: Control, variation: StringName) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label


## Ouvre le ruban du dossier ; faux s'il n'y en a pas (ou pas encore).
func open_case(id: String) -> bool:
	var block := PunchClockRules.get_punch_clock(CaseLibrary.get_case(id))
	if block.is_empty() or not EventRules.are_conditions_met(block.get("conditions", {}), GameState.get_condition_state()):
		return false
	case_id = id
	selected = []
	_title.text = block.get("title", "")
	_intro.text = block.get("intro", "")
	_feedback.text = ""
	_check_button.disabled = block.get("establishes", "") in GameState.get_case_state(id).contradictions_found
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	for row: Dictionary in block.get("rows", []):
		var button := Button.new()
		button.name = "Row_" + str(row.id)
		button.toggle_mode = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 44)
		button.text = tr("%s  //  ruban : %s\ncertificat : %s") % [row.get("label", ""), row.get("punches", ""), row.get("certificate", "")]
		button.toggled.connect(func(on: bool) -> void: toggle(str(row.id), on))
		_rows.add_child(button)
	show()
	return true


func toggle(row_id: String, on: bool) -> void:
	if on and not row_id in selected:
		selected.append(row_id)
	elif not on:
		selected.erase(row_id)


func check() -> void:
	var result := GameState.apply_punch_clock(case_id, selected)
	if result.is_empty():
		return
	if result.correct:
		Sound.play("stamp")
		_feedback.text = result.text if result.text != "" else tr("Le ruban et les certificats ne disent pas la même chose.")
		_check_button.disabled = true
	else:
		_feedback.text = tr("Le ruban ne le confirme pas : %d jour(s) manquant(s), %d en trop.") % [result.missing, result.wrong]


func close() -> void:
	hide()
	closed.emit()
