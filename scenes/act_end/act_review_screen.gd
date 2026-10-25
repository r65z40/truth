class_name ActReviewScreen
extends ColorRect
## Écran de fin d'acte : ce que sont devenus les sujets, puis la commission
## d'avancement (accepter ou décliner une promotion). Lit GameState, n'applique
## aucune règle lui-même.

signal finished

@onready var _title_label: Label = %TitleLabel
@onready var _subjects_box: VBoxContainer = %SubjectsBox
@onready var _criteria_label: Label = %CriteriaLabel
@onready var _letter_label: Label = %LetterLabel
@onready var _result_label: Label = %ResultLabel
@onready var _accept_button: Button = %AcceptButton
@onready var _refuse_button: Button = %RefuseButton
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
	_accept_button.pressed.connect(decide.bind(true))
	_refuse_button.pressed.connect(decide.bind(false))
	_continue_button.pressed.connect(_on_continue)


## Ouvre la revue si ce soir termine un acte. Renvoie false sinon.
func open() -> bool:
	var review := GameState.get_act_review()
	if review.is_empty():
		return false
	_title_label.text = "FIN DE L'ACTE %d  //  %s" % [review.act, review.title]
	for child in _subjects_box.get_children():
		_subjects_box.remove_child(child)
		child.queue_free()
	for subject: Dictionary in review.subjects:
		var heading := Label.new()
		heading.text = "%s  //  dossier %s  //  %s" % [subject.name, subject.case_id, subject.decision]
		heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_subjects_box.add_child(heading)
		var fate := Label.new()
		fate.text = subject.text
		fate.theme_type_variation = &"MutedLabel"
		fate.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_subjects_box.add_child(fate)
	var lines: PackedStringArray = []
	for criterion: Dictionary in review.evaluation.criteria:
		lines.append("[%s]  %s" % ["OUI" if criterion.ok else "NON", criterion.label])
	_criteria_label.text = "\n".join(lines)
	var eligible: bool = review.evaluation.eligible
	_letter_label.text = review.letter
	if eligible and review.unlocks != "":
		_letter_label.text += "\n\n%s : %s" % [review.target_rank, review.unlocks]
	_result_label.hide()
	_accept_button.visible = eligible
	_refuse_button.visible = eligible
	_continue_button.visible = not eligible
	show()
	if eligible:
		_accept_button.grab_focus()
	else:
		_continue_button.grab_focus()
	return true


## Accepte ou décline la promotion (sans promotion proposée : simple clôture).
func decide(accept: bool) -> void:
	var text := GameState.complete_act_review(accept)
	_accept_button.hide()
	_refuse_button.hide()
	_result_label.text = text
	_result_label.visible = text != ""
	_continue_button.show()
	_continue_button.grab_focus()


func _on_continue() -> void:
	if GameState.has_act_review_pending():
		GameState.complete_act_review(false)
	hide()
	finished.emit()
