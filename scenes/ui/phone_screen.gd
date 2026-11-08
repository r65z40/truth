class_name PhoneScreen
extends ColorRect
## Le téléphone du bureau : un appel court, deux ou trois réponses, aucun
## chronomètre. L'interface ne décide rien : elle affiche l'appel en attente
## (GameState.get_pending_call) et transmet la réponse (GameState.answer_call).

signal closed

var call_id := ""

var _caller: Label
var _text: Label
var _answers: VBoxContainer
var _reply: Label
var _hang_up: Button


func _init() -> void:
	name = "PhoneScreen"
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Même voile que les autres écrans posés sur le bureau (frise, comparaison).
	color = Color(0.02, 0.025, 0.022, 0.88)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var card := PanelContainer.new()
	card.theme_type_variation = &"DocumentPanel"
	card.custom_minimum_size = Vector2(620, 0)
	center.add_child(card)
	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 24)
	card.add_child(pad)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	pad.add_child(column)
	var kicker := Label.new()
	kicker.theme_type_variation = &"MutedLabel"
	kicker.text = "LE TÉLÉPHONE SONNE"
	column.add_child(kicker)
	_caller = _label(column, &"HeaderLabel")
	_caller.name = "CallerLabel"
	_text = _label(column, &"DocumentLabel")
	_text.name = "CallText"
	_answers = VBoxContainer.new()
	_answers.name = "Answers"
	_answers.add_theme_constant_override("separation", 8)
	column.add_child(_answers)
	_reply = _label(column, &"DocumentLabel")
	_reply.name = "ReplyLabel"
	_hang_up = Button.new()
	_hang_up.name = "HangUpButton"
	_hang_up.text = "RACCROCHER"
	_hang_up.custom_minimum_size = Vector2(0, 44)
	_hang_up.pressed.connect(close)
	column.add_child(_hang_up)


func _label(parent: Control, variation: StringName) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label


## Décroche l'appel en attente ; faux s'il n'y en a pas.
func open() -> bool:
	var call := GameState.get_pending_call()
	if call.is_empty():
		return false
	call_id = call.id
	_caller.text = call.get("caller", "")
	_text.text = call.get("text", "")
	for child in _answers.get_children():
		child.queue_free()
	for entry in call.get("answers", []):
		var button := Button.new()
		button.name = "Answer_" + str(entry.id)
		button.text = entry.get("label", "")
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0, 44)
		button.pressed.connect(choose.bind(str(entry.id)))
		_answers.add_child(button)
	_answers.show()
	_reply.hide()
	_hang_up.hide()
	show()
	return true


## Répond ; la réplique s'affiche, puis l'agent raccroche quand il veut.
func choose(answer_id: String) -> void:
	var reply := GameState.answer_call(call_id, answer_id)
	_answers.hide()
	_reply.text = reply
	_reply.show()
	_hang_up.show()
	Sound.play("phone_hangup")


func close() -> void:
	hide()
	closed.emit()
