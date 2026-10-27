class_name EveningScreen
extends ColorRect
## Écran de soirée, entre la fin de service et le jour suivant.
##
## Affiche la soirée du jour (EveningRules via GameState), propose ses actions
## et montre le résultat du choix. Aucune règle ici : tout passe par GameState.
## Après des heures supplémentaires, la soirée est perdue.

signal finished

@onready var _place_label: Label = %PlaceLabel
@onready var _intro_label: Label = %IntroLabel
@onready var _choice_label: Label = %ChoiceLabel
@onready var _actions_box: VBoxContainer = %ActionsBox
@onready var _result_label: Label = %ResultLabel
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
	Backdrop.add_to(self, "evening_background")
	_continue_button.pressed.connect(_on_continue)


## Ouvre la soirée du jour. Renvoie false s'il n'y a pas de soirée ce soir.
func open() -> bool:
	if not GameState.has_evening_pending():
		return false
	_place_label.text = "%s  //  %s" % [EveningRules.get_data().get("location", ""),
			GameState.get_date_long()]
	_clear_actions()
	_result_label.hide()
	_continue_button.hide()
	if GameState.is_overtime_today():
		_intro_label.text = GameState.lose_evening()
		_choice_label.hide()
		_show_continue()
	else:
		_intro_label.text = GameState.get_evening().get("intro", "")
		_choice_label.show()
		for action: Dictionary in GameState.get_evening_actions():
			_add_action(action)
	show()
	return true


## Choisit une action (aussi utilisé par les tests et la capture d'écran).
func choose(action_id: String) -> void:
	var result := GameState.choose_evening_action(action_id)
	if result.is_empty():
		return
	_clear_actions()
	_choice_label.hide()
	_result_label.text = result.text
	_result_label.show()
	_show_continue()


func get_action_ids() -> Array:
	return _actions_box.get_children().filter(func(node: Node) -> bool: return node is Button) \
			.map(func(button: Button) -> String: return button.get_meta("action_id"))


func _add_action(action: Dictionary) -> void:
	var button := Button.new()
	button.text = action.get("label", "")
	button.tooltip_text = action.get("description", "")
	button.custom_minimum_size = Vector2(0, 48)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.set_meta("action_id", action.id)
	button.pressed.connect(choose.bind(action.id))
	_actions_box.add_child(button)
	var description := Label.new()
	description.text = action.get("description", "")
	description.theme_type_variation = &"MutedLabel"
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_actions_box.add_child(description)


func _clear_actions() -> void:
	for child in _actions_box.get_children():
		_actions_box.remove_child(child)
		child.queue_free()


func _show_continue() -> void:
	_continue_button.show()
	_continue_button.grab_focus()


func _on_continue() -> void:
	hide()
	finished.emit()
