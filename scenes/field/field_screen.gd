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
## Pièce courante dans une perquisition à plusieurs pièces ("" si la scène n'en a pas).
var _room_id := ""

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
	var new_scene := GameState.start_field(case_id)
	if new_scene.is_empty():
		return false
	_show_scene(new_scene)
	return true


## Aperçu d'une scène de terrain sans conditions ni coût en heures (outil de
## visite des scènes). Prépare un état de scène neuf pour que l'affichage et les
## choix fonctionnent dans une partie bac à sable.
func preview(case_id: String) -> bool:
	var new_scene := GameState.get_field_scene(case_id)
	if new_scene.is_empty():
		return false
	if not GameState.field_scenes.has(new_scene.id):
		GameState.field_scenes[new_scene.id] = {"turns_used": 0, "chosen": [], "finished": false}
	_show_scene(new_scene)
	return true


## Affiche une scène (décor, sujet, intro, indice) et rafraîchit les choix.
func _show_scene(new_scene: Dictionary) -> void:
	scene = new_scene
	_presenting = false
	_title_label.text = scene.get("title", "")
	_room_id = FieldRules.start_room(scene).get("id", "") if FieldRules.has_rooms(scene) else ""
	_apply_room_art()
	_log = [scene.get("intro", "")]
	_hint_label.text = scene.get("hint", "Les éléments obtenus vont dans votre carnet et au dossier." if scene.type == "interrogation" \
			else "Cliquez sur un endroit du dessin pour le fouiller. Ce que vous trouvez est versé au dossier.")
	show()
	_refresh()


## La pièce courante (perquisition à pièces), ou la scène elle-même sinon.
func _current_view() -> Dictionary:
	return FieldRules.get_room(scene, _room_id) if _room_id != "" else scene


## Règle le décor (image, dessin ou 3D) sur la pièce courante.
## L'image livrée prime ; sinon la 3D si le réglage optionnel est actif ; sinon
## le décor dessiné.
func _apply_room_art() -> void:
	var view := _current_view()
	_art.subject = scene.get("subject", {}).get("photo", {})
	_art.scene = "interrogation" if scene.type == "interrogation" else view.get("art", scene.get("art", ""))
	_art.image_path = view.get("image", scene.get("image", ""))
	var has_image: bool = _art.has_image()
	var use_3d := not has_image and Settings.field_3d and _stage.load_stage(_art.scene, scene.get("subject", {}))
	_stage.visible = use_3d
	_art.visible = not use_3d


## Passe dans une autre pièce (gratuit, ne consomme pas de tour).
func _go_to_room(room_id: String) -> void:
	if room_id == _room_id or FieldRules.get_room(scene, room_id).is_empty():
		return
	_room_id = room_id
	_apply_room_art()
	_refresh()


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
	# Dans une perquisition à pièces, on ne montre que les endroits de la pièce courante.
	if _room_id != "":
		options = options.filter(func(o: Dictionary) -> bool:
			return FieldRules.room_of_option(scene, o.id) == _room_id)
	var stage_spots: Array = options.map(func(o: Dictionary) -> String: return o.id)
	if is_interrogation() and not done and not _presenting:
		stage_spots.append("present")
	_stage.set_active_spots(stage_spots)
	if done:
		return
	if not is_interrogation():
		# Les endroits sont cliquables sur le dessin et rappelés en liste.
		for option: Dictionary in options:
			_add_spot(option.get("spot", [0, 0, 60, 44]), option.label, choose.bind(option.id), "option_id", option.id)
			_add_option_button(option.label, choose.bind(option.id), option.id)
		# Les portes mènent aux autres pièces (gratuit).
		for door: Dictionary in _current_view().get("doors", []):
			var to: String = door.get("to", "")
			var label: String = door.get("label", "Changer de pièce")
			_add_spot(door.get("spot", [0, 0, 60, 44]), label, _go_to_room.bind(to), "door_to", to)
			_add_option_button("↪ " + label, _go_to_room.bind(to)).set_meta("door_to", to)
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


## Zone cliquable posée sur le dessin/l'image (endroit à fouiller ou porte).
func _add_spot(area: Variant, tooltip: String, callback: Callable, meta_key: String, meta_value: String) -> void:
	var spot := Button.new()
	spot.theme_type_variation = &"FieldSpot"
	spot.tooltip_text = tooltip
	spot.set_meta(meta_key, meta_value)
	spot.set_meta("area", area)
	spot.pressed.connect(callback)
	if _art.visible:
		_art.add_child(spot)
	else:
		spot.queue_free()


func _add_option_button(text: String, callback: Callable, id := "") -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size = Vector2(0, 44)
	button.add_theme_font_size_override("font_size", 15)
	button.set_meta("option_id", id)
	button.pressed.connect(callback)
	_options_box.add_child(button)
	return button


## Identifiants des choix affichés (questions, éléments ou endroits).
func get_choice_ids() -> Array:
	var ids := []
	for parent in [_options_box]:
		for child in parent.get_children():
			if child is Button and not child.is_queued_for_deletion() and not child.has_meta("door_to"):
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
