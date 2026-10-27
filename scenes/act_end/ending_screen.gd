class_name EndingScreen
extends ColorRect
## Écran de fin de partie : la fin atteinte (titre + texte), puis la dernière
## page d'archive — le destin de chaque sujet rencontré. Lit les données que lui
## passe le bureau (GameState.get_ending()) ; n'applique aucune règle lui-même.

signal finished

@onready var _title_label: Label = %TitleLabel
@onready var _lines_label: Label = %LinesLabel
@onready var _true_line_header: Label = %TrueLineHeader
@onready var _true_line_label: Label = %TrueLineLabel
@onready var _subjects_box: VBoxContainer = %SubjectsBox
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
	_continue_button.pressed.connect(_on_continue)


## Affiche la fin et l'archive. result : {ending, subjects} (GameState.get_ending()).
func open(result: Dictionary) -> void:
	var ending: Dictionary = result.get("ending", {})
	_title_label.text = ending.get("title", tr("FIN DE SERVICE"))
	_lines_label.text = "\n\n".join(PackedStringArray(ending.get("lines", [])))
	# Pour LA CORRECTION : « la seule ligne vraie qui survit » (le dossier du père).
	var true_line: String = ending.get("true_line", "")
	_true_line_header.visible = true_line != ""
	_true_line_label.visible = true_line != ""
	_true_line_label.text = true_line
	for child in _subjects_box.get_children():
		_subjects_box.remove_child(child)
		child.queue_free()
	for subject: Dictionary in result.get("subjects", []):
		var heading := Label.new()
		heading.text = tr("%s  //  dossier %s  //  %s") % [subject.name, subject.case_id, subject.stamp]
		heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_subjects_box.add_child(heading)
		if subject.get("line", "") != "":
			var fate := Label.new()
			fate.text = subject.line
			fate.theme_type_variation = &"MutedLabel"
			fate.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_subjects_box.add_child(fate)
	show()
	_continue_button.grab_focus()


func _on_continue() -> void:
	hide()
	finished.emit()
