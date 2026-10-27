class_name TimelineScreen
extends ColorRect
## Mini-jeu « frise chronologique » (acte 2) : des repères datés, présentés dans le
## désordre, que le joueur touche du plus ancien au plus récent. Une frise juste
## met en évidence l'anomalie et l'établit au carnet (voir TimelineRules). Le jeu
## ne tranche rien : les dates sont déjà dans les pièces.
## Facultatif : on peut fermer à tout moment et conclure par la voie normale.

signal closed

var _case_id: String = ""
var _timeline: Dictionary = {}
## Identifiants des repères déjà placés, dans l'ordre choisi par le joueur.
var _order: Array[String] = []
## id du repère -> son bouton, pour l'état visuel.
var _buttons: Dictionary = {}
var _resolved: bool = false

@onready var _title: Label = %TitleLabel
@onready var _intro: Label = %IntroLabel
@onready var _markers_box: VBoxContainer = %MarkersBox
@onready var _chosen: Label = %ChosenLabel
@onready var _feedback: Label = %FeedbackLabel
@onready var _result: Label = %ResultLabel
@onready var _validate_button: Button = %ValidateButton
@onready var _reset_button: Button = %ResetButton
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	_validate_button.pressed.connect(_on_validate)
	_reset_button.pressed.connect(_reset)
	_close_button.pressed.connect(_on_close)
	hide()


## Ordre d'affichage des repères : volontairement NON chronologique (par
## identifiant) pour que remettre la frise en ordre demande de lire les dates.
func _display_entries() -> Array:
	var entries: Array = _timeline.get("entries", []).duplicate()
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("id", "")) < str(b.get("id", "")))
	return entries


## Ouvre le mini-jeu pour un dossier. Renvoie false s'il n'y a pas de frise.
func open_case(case_id: String) -> bool:
	_timeline = TimelineRules.get_timeline(CaseLibrary.get_case(case_id))
	if _timeline.is_empty():
		return false
	_case_id = case_id
	_resolved = false
	_title.text = _timeline.get("title", "")
	_intro.text = _timeline.get("intro", "")
	_build_markers()
	_reset()
	_result.text = ""
	_result.visible = false
	_validate_button.visible = true
	_close_button.text = "FERMER"
	show()
	return true


## Une pastille par repère, dans le désordre, toujours visibles ; on les touche
## dans l'ordre et chacune s'inscrit avec son rang.
func _build_markers() -> void:
	for child in _markers_box.get_children():
		child.queue_free()
	_buttons = {}
	for entry in _display_entries():
		var entry_id: String = entry.get("id", "")
		var button := Button.new()
		button.text = entry.get("label", entry_id)
		button.custom_minimum_size = Vector2(0, 44)
		button.add_theme_font_size_override("font_size", 15)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_marker.bind(entry_id))
		_markers_box.add_child(button)
		_buttons[entry_id] = button


func _on_marker(entry_id: String) -> void:
	if _resolved or entry_id in _order:
		return
	_order.append(entry_id)
	_refresh_markers()


## Remet tous les repères à disposition et vide la frise en construction.
func _reset() -> void:
	if _resolved:
		return
	_order.clear()
	_feedback.visible = false
	_refresh_markers()


## Reflète l'état : rang affiché sur les repères placés, bouton grisé, et la
## validation ne s'ouvre qu'une fois tous les repères posés.
func _refresh_markers() -> void:
	for entry in _display_entries():
		var entry_id: String = entry.get("id", "")
		var button: Button = _buttons[entry_id]
		var placed := _order.find(entry_id)
		button.disabled = placed != -1
		if placed != -1:
			button.text = "%d.  %s" % [placed + 1, entry.get("label", entry_id)]
		else:
			button.text = entry.get("label", entry_id)
	var chosen: PackedStringArray = []
	for i in _order.size():
		var entry := _entry(_order[i])
		chosen.append("%d. %s" % [i + 1, entry.get("label", _order[i])])
	_chosen.text = "\n".join(chosen)
	_validate_button.disabled = _order.size() != _timeline.get("entries", []).size()


func _entry(entry_id: String) -> Dictionary:
	for entry in _timeline.get("entries", []):
		if entry.get("id", "") == entry_id:
			return entry
	return {}


func _on_validate() -> void:
	if _resolved:
		return
	if TimelineRules.grade(_timeline, _order).correct:
		_resolve()
	else:
		_feedback.text = "L'ordre n'est pas bon. Reprenez en lisant les dates : une frise juste ne ment pas."
		_feedback.visible = true


func _resolve() -> void:
	_resolved = true
	var advantage := GameState.apply_timeline(_case_id, _order)
	_feedback.visible = false
	_validate_button.visible = false
	_reset_button.visible = false
	var decisive := ""
	for entry in _timeline.get("entries", []):
		if entry.get("decisive", false):
			decisive = entry.get("note", "")
	var text: String = advantage.get("text", "") if not advantage.is_empty() else "La frise était déjà établie."
	_result.text = (decisive + "\n\n" + text) if decisive != "" else text
	_result.visible = true
	_close_button.text = "VERSER AU CARNET"
	_close_button.grab_focus()


func _on_close() -> void:
	hide()
	closed.emit()
