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


func _ready() -> void:
	_left_holder.add_child(_left_photo)
	_right_holder.add_child(_right_photo)
	_validate_button.pressed.connect(_on_validate)
	_close_button.pressed.connect(_on_close)
	hide()


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
	# Les photos sont facultatives : une comparaison de registres ou de rapports
	# n'en a pas, et l'écran se passe alors des portraits.
	_left_photo.photo = ComparisonRules.photo_of(case_data, left.get("photo_document", ""))
	_right_photo.photo = ComparisonRules.photo_of(case_data, right.get("photo_document", ""))
	_left_photo.visible = not _left_photo.photo.is_empty()
	_right_photo.visible = not _right_photo.photo.is_empty()
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
