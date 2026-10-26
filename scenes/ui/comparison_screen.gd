class_name ComparisonScreen
extends ColorRect
## Mini-jeu « comparer deux pièces » : deux clichés du dossier posés côte à côte.
## Le joueur pointe chaque trait ; le jeu dit s'il concorde. Trouver le trait
## décisif qui diffère établit la contradiction — l'avantage. Rien n'est inventé :
## tout est déjà dans les pièces (voir ComparisonRules). Facultatif : le joueur
## peut fermer à tout moment et conclure par la voie normale.

signal closed

var _case_id: String = ""
var _comparison: Dictionary = {}
var _left_photo := IdPhoto.new()
var _right_photo := IdPhoto.new()
var _resolved: bool = false

@onready var _title: Label = %TitleLabel
@onready var _intro: Label = %IntroLabel
@onready var _left_label: Label = %LeftLabel
@onready var _right_label: Label = %RightLabel
@onready var _left_holder: Control = %LeftPhoto
@onready var _right_holder: Control = %RightPhoto
@onready var _points_box: VBoxContainer = %PointsBox
@onready var _log: Label = %LogLabel
@onready var _result: Label = %ResultLabel
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	_left_holder.add_child(_left_photo)
	_right_holder.add_child(_right_photo)
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
	_title.text = _comparison.get("title", "")
	_intro.text = _comparison.get("intro", "")
	var left: Dictionary = _comparison.get("left", {})
	var right: Dictionary = _comparison.get("right", {})
	_left_label.text = left.get("label", "")
	_right_label.text = right.get("label", "")
	_left_photo.photo = ComparisonRules.photo_of(case_data, left.get("photo_document", ""))
	_right_photo.photo = ComparisonRules.photo_of(case_data, right.get("photo_document", ""))
	_build_points()
	_log.text = ""
	_result.text = ""
	_result.visible = false
	_close_button.text = "FERMER"
	show()
	_points_box.get_child(0).grab_focus()
	return true


func _build_points() -> void:
	for child in _points_box.get_children():
		child.queue_free()
	for point in _comparison.get("points", []):
		var button := Button.new()
		button.text = point.get("label", "")
		button.custom_minimum_size = Vector2(0, 48)
		button.pressed.connect(_on_point.bind(point, button))
		_points_box.add_child(button)


func _on_point(point: Dictionary, button: Button) -> void:
	var result := ComparisonRules.compare_point(point, _left_photo.photo, _right_photo.photo)
	var verdict: String = "DIFFÉRENT" if result.differs else "concorde"
	button.disabled = true
	button.text = "%s — %s" % [point.get("label", ""), verdict]
	var line := "• %s : %s / %s" % [point.get("label", ""), result.left, result.right]
	_log.text = line if _log.text == "" else _log.text + "\n" + line
	if result.decisive and result.differs and not _resolved:
		_resolve()


func _resolve() -> void:
	_resolved = true
	var advantage := GameState.apply_comparison(_case_id)
	var text: String = advantage.get("text", "")
	_result.text = text if text != "" else "La contradiction était déjà établie."
	_result.visible = true
	_close_button.text = "VERSER AU CARNET"
	_close_button.grab_focus()


func _on_close() -> void:
	hide()
	closed.emit()
