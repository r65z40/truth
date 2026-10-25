class_name FieldScreen
extends ColorRect
## Scène de terrain : interrogatoire ou perquisition, vue à la première personne.
##
## À gauche, le décor : en 3D (FieldStage3D) si le réglage est actif et que le
## décor existe, sinon dessiné (FieldArt). Les endroits à fouiller y sont
## cliquables, et rappelés en boutons à droite. À droite, le compte rendu et les questions.
## Toute la logique passe par GameState (voir FieldRules).

signal finished

var scene: Dictionary = {}
var _presenting := false
var _log: PackedStringArray = []
var _stage: FieldStage3D

@onready var _title_label: Label = %TitleLabel
@onready var _turns_label: Label = %TurnsLabel
@onready var _art: FieldArt = %Art
@onready var _log_label: Label = %LogLabel
@onready var _log_scroll: ScrollContainer = %LogScroll
@onready var _options_box: VBoxContainer = %OptionsBox
@onready var _hint_label: Label = %HintLabel
@onready var _leave_button: Button = %LeaveButton


func _ready() -> void:
	_leave_button.pressed.connect(_on_leave)
	_art.resized.connect(_place_spots)
	_stage = FieldStage3D.new()
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage.hide()
	_art.get_parent().add_child(_stage)
	_stage.spot_pressed.connect(_on_stage_spot)


## Commence la scène de terrain du dossier. Renvoie false si elle est impossible.
func open(case_id: String) -> bool:
	scene = GameState.start_field(case_id)
	if scene.is_empty():
		return false
	_presenting = false
	_title_label.text = scene.get("title", "")
	_art.subject = scene.get("subject", {}).get("photo", {})
	_art.scene = "interrogation" if scene.type == "interrogation" else scene.get("art", "")
	var use_3d := Settings.field_3d and _stage.load_stage(_art.scene, scene.get("subject", {}))
	_stage.visible = use_3d
	_art.visible = not use_3d
	_log = [scene.get("intro", "")]
	_hint_label.text = scene.get("hint", "Les éléments obtenus vont dans votre carnet et au dossier." if scene.type == "interrogation" \
			else "Cliquez sur un endroit du dessin pour le fouiller. Ce que vous trouvez est versé au dossier.")
	show()
	_refresh()
	return true


func is_3d() -> bool:
	return _stage.visible


func get_stage() -> FieldStage3D:
	return _stage


func is_interrogation() -> bool:
	return scene.get("type", "") == "interrogation"


## Pose une question ou fouille un endroit (aussi utilisé par les tests).
func choose(option_id: String) -> void:
	var option := FieldRules.get_option(scene, option_id)
	var result := GameState.field_choose(scene.id, option_id)
	if result.is_empty():
		return
	_append(scene.get("verb", "> " if is_interrogation() else "Vous fouillez : ") + option.get("label", ""), result)


## Présente un élément du carnet (interrogatoire).
func present(fact_id: String) -> void:
	var fact := CaseLibrary.get_fact(CaseLibrary.get_case(scene.case_id), fact_id)
	var result := GameState.field_present(scene.id, fact_id)
	if result.is_empty():
		return
	_presenting = false
	_append("Vous posez sur la table : %s" % fact.get("label", fact_id), result)


func show_presentation_list(show_list: bool) -> void:
	_presenting = show_list
	_refresh()


func _append(action: String, result: Dictionary) -> void:
	_log.append(action)
	_log.append(result.text)
	for label in result.noted:
		_log.append("NOTÉ DANS LE CARNET : %s" % label)
	if result.finished:
		_log.append(scene.get("outro", ""))
	_refresh()


func _refresh() -> void:
	var scene_state := GameState.get_field_state(scene.get("id", ""))
	var done: bool = scene_state.get("finished", true)
	var left := FieldRules.turns_left(scene, scene_state)
	_turns_label.text = "TERMINÉ" if done else \
			scene.get("turns_label", "%d question(s) restante(s)" if is_interrogation() else "%d fouille(s) restante(s)") % left
	_log_label.text = "\n\n".join(_log)
	_scroll_log_to_end.call_deferred()
	for child in _options_box.get_children():
		_options_box.remove_child(child)
		child.queue_free()
	for child in _art.get_children():
		_art.remove_child(child)
		child.queue_free()
	_leave_button.text = "RETOUR AU BUREAU" if done else "PARTIR"
	var options := [] if done else GameState.get_field_options(scene.id)
	var stage_spots: Array = options.map(func(o: Dictionary) -> String: return o.id)
	if is_interrogation() and not done and not _presenting:
		stage_spots.append("present")
	_stage.set_active_spots(stage_spots)
	if done:
		return
	if not is_interrogation():
		# Les endroits sont cliquables sur le dessin et rappelés en liste.
		for option: Dictionary in options:
			var spot := Button.new()
			spot.theme_type_variation = &"FieldSpot"
			spot.tooltip_text = option.label
			spot.set_meta("option_id", option.id)
			spot.set_meta("area", option.get("spot", [0, 0, 60, 44]))
			spot.pressed.connect(choose.bind(option.id))
			if _art.visible:
				_art.add_child(spot)
			else:
				spot.queue_free()
			_add_option_button(option.label, choose.bind(option.id), option.id)
		_place_spots()
		return
	if _presenting:
		for fact_id in GameState.get_case_state(scene.case_id).noted_facts:
			var fact := CaseLibrary.get_fact(GameState.get_case_view(scene.case_id), fact_id)
			if not fact.is_empty():
				_add_option_button(fact.label, present.bind(fact_id), fact_id)
		_add_option_button("RETOUR AUX QUESTIONS", show_presentation_list.bind(false))
		return
	for option: Dictionary in options:
		_add_option_button(option.label, choose.bind(option.id), option.id)
	_add_option_button("PRÉSENTER UN ÉLÉMENT DU CARNET", show_presentation_list.bind(true), "present")


func _add_option_button(text: String, callback: Callable, id := "") -> void:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size = Vector2(0, 44)
	button.add_theme_font_size_override("font_size", 15)
	button.set_meta("option_id", id)
	button.pressed.connect(callback)
	_options_box.add_child(button)


## Identifiants des choix affichés (questions, éléments ou endroits).
func get_choice_ids() -> Array:
	var ids := []
	for parent in [_options_box]:
		for child in parent.get_children():
			if child is Button and not child.is_queued_for_deletion():
				ids.append(child.get_meta("option_id", ""))
	return ids


func _place_spots() -> void:
	for spot in _art.get_children():
		if spot is Button:
			var rect := _art.to_local_rect(spot.get_meta("area"))
			spot.position = rect.position
			spot.size = Vector2(rect.size.x, maxf(rect.size.y, 44.0))


func _on_stage_spot(option_id: String) -> void:
	if option_id == "present":
		show_presentation_list(true)
	else:
		choose(option_id)


func _scroll_log_to_end() -> void:
	# Attendre que le texte ait été mis en page pour connaître la hauteur réelle.
	await get_tree().process_frame
	if not is_inside_tree():
		return
	_log_scroll.scroll_vertical = int(_log_scroll.get_v_scroll_bar().max_value)


func _on_leave() -> void:
	var scene_state := GameState.get_field_state(scene.get("id", ""))
	if not scene_state.get("finished", true):
		_log.append(GameState.field_leave(scene.id))
		_refresh()
		return
	hide()
	finished.emit()
