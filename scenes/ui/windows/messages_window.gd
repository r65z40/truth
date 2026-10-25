extends MinistryWindow
## Fenêtre « Messages » : courrier interne reçu par l'inspecteur.

var current_message_id := ""

@onready var _message_list: VBoxContainer = %MessageList
@onready var _message_header: Label = %MessageHeader
@onready var _message_body: RichTextLabel = %MessageBody


func _on_opened() -> void:
	_refresh_list()
	if current_message_id == "" and not GameState.messages.is_empty():
		select_message(GameState.messages[0].id)


func select_message(message_id: String) -> void:
	for message in GameState.messages:
		if message.id != message_id:
			continue
		current_message_id = message_id
		_message_header.text = "DE : %s\nDATE : %s\nOBJET : %s" % [message.from, message.date_label, message.subject]
		_message_body.text = message.body.replace("[", "[lb]")
		GameState.mark_message_read(message_id)
		_refresh_list()
		return


## Bulle d'aide : le premier message non lu de la liste.
func get_guide_target(_part: String, _case_id := "") -> Control:
	for button in _message_list.get_children():
		if button is Button and not button.is_queued_for_deletion() and button.text.begins_with("[NOUVEAU]"):
			return button
	return null


func _refresh_list() -> void:
	for child in _message_list.get_children():
		child.queue_free()
	# Le plus récent en haut.
	for i in range(GameState.messages.size() - 1, -1, -1):
		var message: Dictionary = GameState.messages[i]
		var button := Button.new()
		button.text = "%s%s\n%s" % ["" if message.read else "[NOUVEAU] ", message.subject, message.from]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.toggle_mode = true
		button.button_pressed = message.id == current_message_id
		button.custom_minimum_size = Vector2(0, 72)
		button.pressed.connect(select_message.bind(message.id))
		_message_list.add_child(button)
