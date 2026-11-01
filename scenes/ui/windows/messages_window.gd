extends MinistryWindow
## Fenêtre « Courrier » : courrier interne reçu par l'inspecteur.
## À gauche les plis (enveloppe fermée tant qu'ils ne sont pas lus), à droite
## la lettre ouverte sur papier à en-tête du ministère. Un pli lu peut aller à
## la corbeille (SUPPRIMER) ; la corbeille le garde, d'où on peut le restaurer.

var current_message_id := ""
## Vrai quand la liste montre la corbeille plutôt que les plis reçus.
var showing_trash := false

@onready var _message_list: VBoxContainer = %MessageList
@onready var _list_title: Label = %ListTitle
@onready var _message_header: Label = %MessageHeader
@onready var _message_subject: Label = %MessageSubject
@onready var _message_body: RichTextLabel = %MessageBody
@onready var _letter: Control = %Letter
@onready var _empty_hint: Label = %EmptyHint
@onready var _trash_button: Button = %TrashButton
@onready var _delete_button: Button = %DeleteButton
@onready var _letter_actions: Control = %LetterActions


func _ready() -> void:
	super()
	_trash_button.toggled.connect(show_trash)
	_delete_button.pressed.connect(_on_delete_pressed)


func _on_opened() -> void:
	_refresh_list()
	if current_message_id == "":
		_select_default()


## Ouvre le premier pli non lu, dans l'ordre d'arrivée ; à défaut le plus récent.
func _select_default() -> void:
	var shown := _shown_messages()
	if shown.is_empty():
		_refresh_list()
		return
	for message in GameState.messages:
		if not message.read and message in shown:
			select_message(message.id)
			return
	select_message(shown[0].id)


## Bascule entre les plis reçus et la corbeille.
func show_trash(on: bool) -> void:
	showing_trash = on
	_trash_button.set_pressed_no_signal(on)
	current_message_id = ""
	_select_default()


## Met le pli affiché à la corbeille, ou l'en ressort si on est dans la corbeille.
func delete_current() -> void:
	if current_message_id == "":
		return
	if not GameState.set_message_deleted(current_message_id, not showing_trash):
		return
	notify.emit(tr("Pli restauré.") if showing_trash else tr("Pli mis à la corbeille."))
	current_message_id = ""
	_select_default()


func _on_delete_pressed() -> void:
	delete_current()


## Plis de la vue courante (reçus ou corbeille), le plus récent en premier.
func _shown_messages() -> Array:
	var shown := []
	for i in range(GameState.messages.size() - 1, -1, -1):
		var message: Dictionary = GameState.messages[i]
		if message.get("deleted", false) == showing_trash:
			shown.append(message)
	return shown


func select_message(message_id: String) -> void:
	for message in GameState.messages:
		if message.id != message_id:
			continue
		# Un pli de la corbeille ouvert depuis ailleurs : on passe sur la corbeille.
		if message.get("deleted", false) != showing_trash:
			showing_trash = message.get("deleted", false)
			_trash_button.set_pressed_no_signal(showing_trash)
		current_message_id = message_id
		# Un pli reçu avant un changement de langue se traduit à l'affichage.
		_message_header.text = tr("DE : %s\nÀ : %s, Section 4\nDATE : %s") % [Localization.text(message.from),
				GameState.player.name, message.date_label]
		_message_subject.text = tr("OBJET : %s") % Localization.text(message.subject)
		_message_body.text = Localization.text(message.body).replace("[", "[lb]")
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
	var trashed := 0
	for message in GameState.messages:
		if message.get("deleted", false):
			trashed += 1
	# Le plus récent en haut.
	for message: Dictionary in _shown_messages():
		if not message.read:
			unread += 1
		var button := Button.new()
		button.name = "Message_" + message.id.validate_node_name()
		button.text = "%s\n%s  //  %s" % [Localization.text(message.subject), Localization.text(message.from), message.date_label]
		button.icon = PixelIcons.get_icon("messages" if not message.read else "mail_open", 2)
		button.set_meta("unread", not message.read)
		button.theme_type_variation = &"DocumentTabNew" if not message.read else &"DocumentTab"
		button.tooltip_text = tr("Pli non lu.") if not message.read else tr("Pli lu.")
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 15)
		button.toggle_mode = true
		button.button_pressed = message.id == current_message_id
		button.custom_minimum_size = Vector2(0, 64)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(select_message.bind(message.id))
		_message_list.add_child(button)
	if showing_trash:
		_list_title.text = tr("CORBEILLE")
	else:
		_list_title.text = (tr("PLIS REÇUS (%d non lus)" if unread > 1 else "PLIS REÇUS (%d non lu)") % unread) if unread > 0 else tr("PLIS REÇUS")
	_trash_button.text = tr("◂ RETOUR AUX PLIS REÇUS") if showing_trash else tr("CORBEILLE (%d)") % trashed
	_trash_button.tooltip_text = tr("Les plis supprimés restent ici ; vous pouvez les restaurer.")
	_letter.visible = current_message_id != ""
	_empty_hint.visible = not _letter.visible
	_empty_hint.text = tr("La corbeille est vide.") if showing_trash else tr("Aucun pli. Le courrier de la hiérarchie arrivera ici.")
	# SUPPRIMER : seulement un pli déjà lu ; dans la corbeille, RESTAURER.
	_letter_actions.visible = _letter.visible
	_delete_button.text = tr("RESTAURER") if showing_trash else tr("SUPPRIMER")
	_delete_button.disabled = not showing_trash and not GameState.can_delete_message(current_message_id)
	_delete_button.tooltip_text = tr("Remettre ce pli parmi les plis reçus.") if showing_trash \
			else tr("Mettre ce pli à la corbeille. Il reste consultable dans la corbeille.")
