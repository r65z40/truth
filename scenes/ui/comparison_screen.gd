class_name ComparisonScreen
extends ColorRect
## Mini-jeu « comparer deux pièces » : deux pièces du dossier posées côte à côte.
## Pour chaque trait, le joueur juge lui-même si les deux mentions concordent. Le
## jeu ne tranche pas à sa place : il faut lire, comparer, et ne pas inventer de
## différence. Une comparaison juste établit la contradiction — l'avantage. Rien
## n'est inventé : tout est déjà dans les pièces (voir ComparisonRules).
## Facultatif : le joueur peut fermer à tout moment et conclure par la voie normale.

signal closed

## Largeurs fixes de la grille des traits : nom du trait, puis les deux boutons.
const TRAIT_WIDTH := 170.0
const JUDGE_WIDTH := 220.0

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
	button.text = tr("AGRANDIR ⌕")
	button.custom_minimum_size = Vector2(0, 44)
	button.add_theme_font_size_override("font_size", 13)
	button.tooltip_text = tr("Examiner la pièce de près")
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
	hint.text = tr("Touchez l'écran pour fermer.")
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
	_close_button.text = tr("FERMER")
	show()
	return true


## Une ligne par trait : le trait, la mention de chaque pièce, puis deux boutons
## de jugement. Les noms des pièces sont en tête de colonne : tout tient sans
## faire défiler.
func _build_points() -> void:
	for child in _points_box.get_children():
		child.queue_free()
	var header := _points_box.get_parent().get_node_or_null("PointsHeader") as HBoxContainer
	if header == null:
		header = HBoxContainer.new()
		header.name = "PointsHeader"
		_points_box.add_sibling(header)
		_points_box.get_parent().move_child(header, _points_box.get_index())
	for child in header.get_children():
		child.queue_free()
	for text in ["", _left_label.text, _right_label.text, ""]:
		header.add_child(_cell(text, &"MutedLabel"))
	header.get_child(0).custom_minimum_size.x = TRAIT_WIDTH
	header.get_child(3).custom_minimum_size.x = JUDGE_WIDTH
	header.get_child(3).size_flags_horizontal = Control.SIZE_FILL
	header.get_child(0).size_flags_horizontal = Control.SIZE_FILL
	for point in _comparison.get("points", []):
		var point_id: String = point.get("id", "")
		var compared := ComparisonRules.compare_point(point, _left_photo.photo, _right_photo.photo)
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		var pad := MarginContainer.new()
		pad.add_theme_constant_override("margin_top", 2)
		pad.add_theme_constant_override("margin_bottom", 2)
		card.add_child(pad)
		var box := HBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		pad.add_child(box)
		var trait_label := _cell(point.get("label", ""), &"HeaderLabel")
		trait_label.custom_minimum_size.x = TRAIT_WIDTH
		trait_label.size_flags_horizontal = Control.SIZE_FILL
		box.add_child(trait_label)
		box.add_child(_cell(compared.left, &"DocumentLabel"))
		box.add_child(_cell(compared.right, &"DocumentLabel"))
		var judge := _judgement_row(point_id)
		judge.custom_minimum_size.x = JUDGE_WIDTH
		box.add_child(judge)
		_points_box.add_child(card)


## Case de la grille : texte qui passe à la ligne, colonne extensible.
func _cell(text: String, variation: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.add_theme_font_size_override("font_size", 15)
	return label


## Deux boutons exclusifs : CONCORDE / DIFFÈRE.
func _judgement_row(point_id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var group := ButtonGroup.new()
	for is_diff in [false, true]:
		var button := Button.new()
		button.text = tr("DIFFÈRE") if is_diff else tr("CONCORDE")
		button.toggle_mode = true
		button.button_group = group
		button.custom_minimum_size = Vector2(0, 44)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 14)
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
		_feedback.text = tr("%d trait(s) mal jugé(s). Reprenez : une fiche mal lue condamne un innocent — ou épargne un coupable.") % report.wrong
		_feedback.visible = true


func _resolve() -> void:
	_resolved = true
	var advantage := GameState.apply_comparison(_case_id)
	_feedback.visible = false
	_validate_button.visible = false
	_result.text = advantage.get("text", "") if not advantage.is_empty() else tr("La contradiction était déjà établie.")
	_result.visible = true
	_close_button.text = tr("VERSER AU CARNET")
	_close_button.grab_focus()


func _on_close() -> void:
	hide()
	closed.emit()
