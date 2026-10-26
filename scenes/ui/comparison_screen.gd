class_name ComparisonScreen
extends ColorRect
## Mini-jeu « comparer deux pièces » : deux pièces du dossier posées côte à côte.
## Pour chaque trait, le joueur juge lui-même si les deux mentions concordent. Le
## jeu ne tranche pas à sa place : il faut lire, comparer, et ne pas inventer de
## différence. Une comparaison juste établit la contradiction — l'avantage. Rien
## n'est inventé : tout est déjà dans les pièces (voir ComparisonRules).
## Facultatif : le joueur peut fermer à tout moment et conclure par la voie normale.

signal closed

var _case_id: String = ""
var _comparison: Dictionary = {}
var _left_photo := IdPhoto.new()
var _right_photo := IdPhoto.new()
## Cachets / signatures : l'élément officiel à authentifier (« traquer les faussaires »).
var _left_mark := OfficialMark.new()
var _right_mark := OfficialMark.new()
## point_id -> true si le joueur a jugé « différent ».
var _verdicts: Dictionary = {}
var _resolved: bool = false

@onready var _title: Label = %TitleLabel
@onready var _intro: Label = %IntroLabel
@onready var _left_label: Label = %LeftLabel
@onready var _right_label: Label = %RightLabel
@onready var _left_holder: Control = %LeftPhoto
@onready var _right_holder: Control = %RightPhoto
@onready var _points_box: VBoxContainer = %PointsBox
@onready var _feedback: Label = %FeedbackLabel
@onready var _result: Label = %ResultLabel
@onready var _validate_button: Button = %ValidateButton
@onready var _close_button: Button = %CloseButton

## Loupe : examiner une pièce de près (branches d'une étoile, tremblé d'une
## signature, grain de beauté). Le joueur doit pouvoir inspecter, pas seulement lire.
var _left_zoom: Button
var _right_zoom: Button
var _loupe: ColorRect
var _loupe_caption: Label
var _loupe_stage: Control
var _loupe_photo := IdPhoto.new()
var _loupe_mark := OfficialMark.new()


func _ready() -> void:
	_left_holder.add_child(_left_photo)
	_right_holder.add_child(_right_photo)
	_left_holder.add_child(_left_mark)
	_right_holder.add_child(_right_mark)
	_left_zoom = _make_zoom_button(_left_holder)
	_left_zoom.pressed.connect(func() -> void:
		_show_loupe(_left_photo.photo, _left_mark.mark, _left_label.text))
	_right_zoom = _make_zoom_button(_right_holder)
	_right_zoom.pressed.connect(func() -> void:
		_show_loupe(_right_photo.photo, _right_mark.mark, _right_label.text))
	_build_loupe()
	_validate_button.pressed.connect(_on_validate)
	_close_button.pressed.connect(_on_close)
	hide()


## Bouton « AGRANDIR », posé sous une pièce, pour ouvrir la loupe.
func _make_zoom_button(holder: Control) -> Button:
	var button := Button.new()
	button.text = "AGRANDIR ⌕"
	button.custom_minimum_size = Vector2(0, 44)
	button.add_theme_font_size_override("font_size", 13)
	button.tooltip_text = "Examiner la pièce de près"
	button.visible = false
	holder.get_parent().add_child(button)
	return button


## Couche de loupe (construite en code) : une pièce agrandie, centrée, qu'on ferme
## d'une touche. Aucune logique de jeu — c'est un confort d'inspection.
func _build_loupe() -> void:
	_loupe = ColorRect.new()
	_loupe.color = Color(0.03, 0.03, 0.04, 0.82)
	_loupe.set_anchors_preset(Control.PRESET_FULL_RECT)
	_loupe.mouse_filter = Control.MOUSE_FILTER_STOP
	_loupe.visible = false
	add_child(_loupe)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loupe.add_child(center)
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"DocumentPanel"
	center.add_child(panel)
	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(pad)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	pad.add_child(box)
	_loupe_caption = Label.new()
	_loupe_caption.theme_type_variation = &"HeaderLabel"
	_loupe_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loupe_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_loupe_caption.custom_minimum_size = Vector2(480, 0)
	box.add_child(_loupe_caption)
	_loupe_stage = Control.new()
	_loupe_stage.custom_minimum_size = Vector2(480, 400)
	_loupe_stage.add_child(_loupe_photo)
	_loupe_stage.add_child(_loupe_mark)
	box.add_child(_loupe_stage)
	var hint := Label.new()
	hint.text = "Touchez l'écran pour fermer."
	hint.theme_type_variation = &"DocumentLabel"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	_loupe.gui_input.connect(func(event: InputEvent) -> void:
		if (event is InputEventMouseButton and event.pressed) \
				or (event is InputEventScreenTouch and event.pressed):
			_hide_loupe())


## Affiche la pièce agrandie (portrait OU cachet/signature), centrée dans la loupe.
func _show_loupe(photo: Dictionary, mark: Dictionary, caption: String) -> void:
	_loupe_photo.visible = false
	_loupe_mark.visible = false
	if not photo.is_empty():
		_loupe_photo.photo = photo
		_loupe_photo.visible = true
		_center_in_stage(_loupe_photo, 2.4)
	elif not mark.is_empty():
		_loupe_mark.mark = mark
		_loupe_mark.visible = true
		_center_in_stage(_loupe_mark, 2.0 if mark.get("kind", "stamp") == "signature" else 2.3)
	else:
		return
	_loupe_caption.text = caption
	_loupe.visible = true


func _hide_loupe() -> void:
	_loupe.visible = false


## Centre un rendu agrandi (facteur k) dans l'aire de la loupe.
func _center_in_stage(node: Control, k: float) -> void:
	var base := node.custom_minimum_size
	node.scale = Vector2(k, k)
	node.position = (_loupe_stage.custom_minimum_size - base * k) / 2.0


## Ouvre le mini-jeu pour un dossier. Renvoie false si rien à comparer.
func open_case(case_id: String) -> bool:
	var case_data := CaseLibrary.get_case(case_id)
	_comparison = ComparisonRules.get_comparison(case_data)
	if _comparison.is_empty():
		return false
	_case_id = case_id
	_resolved = false
	_verdicts = {}
	_title.text = _comparison.get("title", "")
	_intro.text = _comparison.get("intro", "")
	var left: Dictionary = _comparison.get("left", {})
	var right: Dictionary = _comparison.get("right", {})
	_left_label.text = left.get("label", "")
	_right_label.text = right.get("label", "")
	# Visuels facultatifs : portrait d'identité (photo) OU élément officiel à
	# authentifier (cachet/signature, clé "mark"). Un registre n'a ni l'un ni l'autre.
	_left_photo.photo = ComparisonRules.photo_of(case_data, left.get("photo_document", ""))
	_right_photo.photo = ComparisonRules.photo_of(case_data, right.get("photo_document", ""))
	_left_photo.visible = not _left_photo.photo.is_empty()
	_right_photo.visible = not _right_photo.photo.is_empty()
	_left_mark.mark = left.get("mark", {})
	_right_mark.mark = right.get("mark", {})
	_left_mark.visible = not _left_mark.mark.is_empty()
	_right_mark.visible = not _right_mark.mark.is_empty()
	# La loupe n'est proposée que là où il y a quelque chose à examiner.
	_left_zoom.visible = _left_photo.visible or _left_mark.visible
	_right_zoom.visible = _right_photo.visible or _right_mark.visible
	_hide_loupe()
	_build_points()
	_feedback.text = ""
	_feedback.visible = false
	_result.text = ""
	_result.visible = false
	_validate_button.disabled = true
	_validate_button.visible = true
	_close_button.text = "FERMER"
	show()
	return true


## Une carte par trait : la mention de chaque pièce, puis deux boutons de jugement.
func _build_points() -> void:
	for child in _points_box.get_children():
		child.queue_free()
	for point in _comparison.get("points", []):
		var point_id: String = point.get("id", "")
		var compared := ComparisonRules.compare_point(point, _left_photo.photo, _right_photo.photo)
		var card := PanelContainer.new()
		card.theme_type_variation = &"DocumentPanel"
		var pad := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			pad.add_theme_constant_override("margin_" + side, 10)
		card.add_child(pad)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		pad.add_child(box)
		var trait_label := Label.new()
		trait_label.text = point.get("label", "")
		trait_label.theme_type_variation = &"HeaderLabel"
		box.add_child(trait_label)
		box.add_child(_detail_line(_left_label.text, compared.left))
		box.add_child(_detail_line(_right_label.text, compared.right))
		box.add_child(_judgement_row(point_id))
		_points_box.add_child(card)


## Ligne « <pièce> : <mention> ».
func _detail_line(piece: String, mention: String) -> Label:
	var label := Label.new()
	label.text = "%s : %s" % [piece, mention]
	label.theme_type_variation = &"DocumentLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


## Deux boutons exclusifs : CONCORDE / DIFFÈRE.
func _judgement_row(point_id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var group := ButtonGroup.new()
	for is_diff in [false, true]:
		var button := Button.new()
		button.text = "DIFFÈRE" if is_diff else "CONCORDE"
		button.toggle_mode = true
		button.button_group = group
		button.custom_minimum_size = Vector2(0, 44)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggled.connect(func(pressed: bool) -> void:
			if pressed:
				_verdicts[point_id] = is_diff
				_refresh_validate())
		row.add_child(button)
	return row


## La validation s'ouvre quand chaque trait a été jugé.
func _refresh_validate() -> void:
	if _resolved:
		return
	_validate_button.disabled = _verdicts.size() < _comparison.get("points", []).size()


func _on_validate() -> void:
	if _resolved:
		return
	var report := ComparisonRules.grade(_comparison, _left_photo.photo, _right_photo.photo, _verdicts)
	if report.all_ok:
		_resolve()
	else:
		_feedback.text = "%d trait(s) mal jugé(s). Reprenez : une fiche mal lue condamne un innocent — ou épargne un coupable." % report.wrong
		_feedback.visible = true


func _resolve() -> void:
	_resolved = true
	var advantage := GameState.apply_comparison(_case_id)
	_feedback.visible = false
	_validate_button.visible = false
	_result.text = advantage.get("text", "") if not advantage.is_empty() else "La contradiction était déjà établie."
	_result.visible = true
	_close_button.text = "VERSER AU CARNET"
	_close_button.grab_focus()


func _on_close() -> void:
	hide()
	closed.emit()
