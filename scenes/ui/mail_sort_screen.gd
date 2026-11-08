class_name MailSortScreen
extends ColorRect
## Tri du courrier : les lettres interceptées du jour, une à une. L'agent choisit
## TRANSMETTRE, RETENIR ou SIGNALER ; aucune règle ici (GameState.sort_letter).

signal closed

var letter_id := ""

var _counter: Label
var _header: Label
var _text: Label
var _verdicts: HFlowContainer
var _close_button: Button


func _init() -> void:
	name = "MailSortScreen"
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Même voile que les autres écrans posés sur le bureau (frise, comparaison).
	color = Color(0.02, 0.025, 0.022, 0.88)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var card := PanelContainer.new()
	card.theme_type_variation = &"DocumentPanel"
	card.custom_minimum_size = Vector2(680, 0)
	center.add_child(card)
	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 24)
	card.add_child(pad)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	pad.add_child(column)
	_counter = Label.new()
	_counter.name = "CounterLabel"
	_counter.theme_type_variation = &"MutedLabel"
	column.add_child(_counter)
	_header = Label.new()
	_header.name = "HeaderLabel"
	_header.theme_type_variation = &"HeaderLabel"
	_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_header)
	_text = Label.new()
	_text.name = "LetterText"
	_text.theme_type_variation = &"DocumentLabel"
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_text)
	_verdicts = HFlowContainer.new()
	_verdicts.name = "Verdicts"
	_verdicts.add_theme_constant_override("h_separation", 10)
	column.add_child(_verdicts)
	for verdict in MailSorting.VERDICTS:
		var button := Button.new()
		button.name = "Verdict_" + verdict
		button.custom_minimum_size = Vector2(170, 48)
		if verdict == "report":
			button.theme_type_variation = &"AlertButton"
		button.pressed.connect(choose.bind(verdict))
		_verdicts.add_child(button)
	_close_button = Button.new()
	_close_button.name = "CloseButton"
	_close_button.text = "FERMER"
	_close_button.custom_minimum_size = Vector2(0, 44)
	_close_button.pressed.connect(close)
	column.add_child(_close_button)


## Ouvre le paquet du jour ; faux s'il n'y a rien à trier.
func open() -> bool:
	if GameState.get_pending_letters().is_empty():
		return false
	_show_next()
	show()
	return true


func choose(verdict: String) -> void:
	if GameState.sort_letter(letter_id, verdict):
		Sound.play("stamp")
	_show_next()


func close() -> void:
	hide()
	closed.emit()


func _show_next() -> void:
	var pending := GameState.get_pending_letters()
	var total: int = MailSorting.batch_for_day(GameState.day_index).get("letters", []).size()
	for button: Button in _verdicts.get_children():
		button.text = tr(MailSorting.verdict_label(button.name.trim_prefix("Verdict_")))
	if pending.is_empty():
		letter_id = ""
		_counter.text = tr("CONTRÔLE DU COURRIER")
		_header.text = tr("Paquet trié.")
		_text.text = tr("Les lettres retenues ne seront jamais distribuées. Les autres sont déjà dans les sacs.")
		_verdicts.hide()
		_close_button.text = tr("FERMER")
		return
	var letter: Dictionary = pending[0]
	letter_id = letter.id
	_counter.text = tr("CONTRÔLE DU COURRIER  //  lettre %d sur %d") % [total - pending.size() + 1, total]
	_header.text = tr("De : %s\nÀ : %s") % [letter.get("from", ""), letter.get("to", "")]
	_text.text = letter.get("text", "")
	_verdicts.show()
	_close_button.text = tr("PLUS TARD (non trié, il partira tel quel ce soir)")
