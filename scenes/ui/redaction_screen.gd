class_name RedactionScreen
extends ColorRect
## Caviarder (acte 4, MIROIR) : le projet de VERITAS, ligne par ligne. Toucher une
## ligne la noircit ; la toucher encore la rend lisible. « Signer le caviardage »
## conclut le dossier par la décision « Caviarder », avec ce qui reste lisible.
## Aucune règle ici : GameState.toggle_redaction et apply_decision décident.

signal closed
signal signed(case_id: String)

const DECISION_ID := "redact"

var case_id := ""

var _title: Label
var _lines_box: VBoxContainer
var _count: Label
var _sign_button: Button


func _init() -> void:
	name = "RedactionScreen"
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
	card.custom_minimum_size = Vector2(760, 0)
	center.add_child(card)
	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 24)
	card.add_child(pad)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	pad.add_child(column)
	var kicker := Label.new()
	kicker.theme_type_variation = &"MutedLabel"
	kicker.text = "MIROIR : CAVIARDAGE"
	column.add_child(kicker)
	_title = Label.new()
	_title.theme_type_variation = &"HeaderLabel"
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_title)
	var hint := Label.new()
	hint.theme_type_variation = &"MutedLabel"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.text = "Touchez une ligne pour la noircir, encore une fois pour la rendre lisible. Ce qui reste lisible sera signé de votre nom."
	column.add_child(hint)
	_lines_box = VBoxContainer.new()
	_lines_box.name = "Lines"
	_lines_box.add_theme_constant_override("separation", 6)
	column.add_child(_lines_box)
	_count = Label.new()
	_count.name = "CountLabel"
	_count.theme_type_variation = &"MutedLabel"
	column.add_child(_count)
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 10)
	column.add_child(row)
	_sign_button = Button.new()
	_sign_button.name = "SignButton"
	_sign_button.theme_type_variation = &"AlertButton"
	_sign_button.text = "SIGNER LE CAVIARDAGE"
	_sign_button.custom_minimum_size = Vector2(0, 48)
	_sign_button.pressed.connect(sign)
	row.add_child(_sign_button)
	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "FERMER (garder le brouillon)"
	close_button.custom_minimum_size = Vector2(0, 48)
	close_button.pressed.connect(close)
	row.add_child(close_button)


## Ouvre le projet du dossier ; faux s'il n'y a rien à caviarder.
func open_case(id: String) -> bool:
	var case_data := GameState.get_case_view(id)
	if RedactionRules.get_redaction(case_data).is_empty() or not GameState.can_decide(id):
		return false
	case_id = id
	var document := CaseLibrary.get_document(case_data, RedactionRules.get_redaction(case_data).get("document", ""))
	_title.text = document.get("title", "").to_upper()
	_refresh()
	show()
	return true


func toggle(line_id: String) -> void:
	GameState.toggle_redaction(case_id, line_id)
	Sound.play("stamp")
	_refresh()


func sign() -> void:
	if GameState.apply_decision(case_id, DECISION_ID).is_empty():
		return
	hide()
	signed.emit(case_id)


func close() -> void:
	hide()
	closed.emit()


func _refresh() -> void:
	for child in _lines_box.get_children():
		_lines_box.remove_child(child)
		child.queue_free()
	var redacted: Array = GameState.get_case_state(case_id).get("redacted_lines", [])
	var lines: Array = RedactionRules.get_redaction(GameState.get_case_view(case_id)).get("lines", [])
	for line: Dictionary in lines:
		var button := Button.new()
		button.name = "Line_" + str(line.id)
		var blacked: bool = line.id in redacted
		button.text = RedactionRules.bar(line.text) if blacked else line.text
		button.tooltip_text = line.text
		# Ligne noircie : bloc noir du thème (variation RedactedLine), comme un coup
		# de feutre ; la barre ne transparaît qu'au survol.
		button.theme_type_variation = &"RedactedLine" if blacked else &""
		button.set_meta("redacted", blacked)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0, 44)
		button.pressed.connect(toggle.bind(str(line.id)))
		_lines_box.add_child(button)
	_count.text = tr("%d ligne(s) noircie(s) sur %d.") % [redacted.size(), lines.size()]
