extends MinistryWindow
## Fenêtre « Courrier » : courrier interne reçu par l'inspecteur.
## À gauche les plis (enveloppe fermée tant qu'ils ne sont pas lus), à droite
## la lettre ouverte sur papier à en-tête du ministère.

var current_message_id := ""

@onready var _message_list: VBoxContainer = %MessageList
@onready var _list_title: Label = %ListTitle
@onready var _message_header: Label = %MessageHeader
@onready var _message_subject: Label = %MessageSubject
@onready var _message_body: RichTextLabel = %MessageBody
@onready var _letter: Control = %Letter
@onready var _empty_hint: Label = %EmptyHint


func _on_opened() -> void:
	_refresh_list()
	if current_message_id == "" and not GameState.messages.is_empty():
		select_message(GameState.messages[0].id)


func select_message(message_id: String) -> void:
	for message in GameState.messages:
		if message.id != message_id:
			continue
		current_message_id = message_id
		_message_header.text = "DE : %s\nÀ : %s, Section 4\nDATE : %s" % [message.from, GameState.player.name, message.date_label]
		_message_subject.text = "OBJET : %s" % message.subject
		_message_body.text = message.body.replace("[", "[lb]")
		GameState.mark_message_read(message_id)
		_refresh_list()
		return


## Bulle d'aide : le premier pli non lu de la liste.
func get_guide_target(_part: String, _case_id := "") -> Control:
	for button in _message_list.get_children():
		if button is Button and not button.is_queued_for_deletion() and button.get_meta("unread", false):
			return button
	return null


func _refresh_list() -> void:
	for child in _message_list.get_children():
		_message_list.remove_child(child)
		child.queue_free()
	var unread := 0
	# Le plus récent en haut.
	for i in range(GameState.messages.size() - 1, -1, -1):
		var message: Dictionary = GameState.messages[i]
		if not message.read:
			unread += 1
		var button := Button.new()
		button.name = "Message_" + message.id.validate_node_name()
		button.text = "%s\n%s  //  %s" % [message.subject, message.from, message.date_label]
		button.icon = PixelIcons.get_icon("messages" if not message.read else "mail_open", 2)
		button.set_meta("unread", not message.read)
		button.theme_type_variation = &"DocumentTabNew" if not message.read else &"DocumentTab"
		button.tooltip_text = "Pli non lu." if not message.read else "Pli lu."
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 15)
		button.toggle_mode = true
		button.button_pressed = message.id == current_message_id
		button.custom_minimum_size = Vector2(0, 64)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(select_message.bind(message.id))
		_message_list.add_child(button)
	_list_title.text = "PLIS REÇUS (%d non lu%s)" % [unread, "s" if unread > 1 else ""] if unread > 0 else "PLIS REÇUS"
	_letter.visible = current_message_id != ""
	_empty_hint.visible = not _letter.visible
