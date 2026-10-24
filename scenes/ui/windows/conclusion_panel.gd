extends PanelContainer
## Formulaire de conclusion d'un dossier : rappel des éléments établis,
## choix de la décision, signature. N'applique rien lui-même : émet submitted.

signal submitted(decision_id: String)
signal cancelled

var case_id := ""
var selected_decision := ""
var _choice_group := ButtonGroup.new()

@onready var _title: Label = %ConclusionTitle
@onready var _summary: RichTextLabel = %ConclusionSummary
@onready var _choices: VBoxContainer = %Choices
@onready var _sign_button: Button = %SignButton
@onready var _veritas_box: Control = %VeritasBox
@onready var _veritas_advice: Label = %VeritasAdvice


func _ready() -> void:
	_sign_button.pressed.connect(func() -> void: submitted.emit(selected_decision))
	%CancelButton.pressed.connect(func() -> void: cancelled.emit())


## Prépare le formulaire pour un dossier.
func setup(new_case_id: String) -> void:
	case_id = new_case_id
	selected_decision = ""
	var case_data := CaseLibrary.get_case(case_id)
	var case_state := GameState.get_case_state(case_id)
	_title.text = "RAPPORT DE CONCLUSION  //  DOSSIER N° %s" % case_id
	_summary.text = build_summary_bbcode(case_data, case_state)
	var advice := Veritas.recommendation(case_data)
	_veritas_box.visible = not advice.is_empty()
	if not advice.is_empty():
		_veritas_advice.text = "%s RECOMMANDE : %s  (indice de confiance %d %%)\n%s\nLa responsabilité de la conclusion incombe à l'agent signataire." % [
			Veritas.NAME, advice.label.to_upper(), advice.confidence, advice.rationale]
	for child in _choices.get_children():
		_choices.remove_child(child)
		child.queue_free()
	for decision in case_data.get("decisions", []):
		var button := Button.new()
		button.name = "Choice_" + decision.id
		button.text = "%s\n%s" % [decision.label.to_upper(), decision.get("description", "")]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.toggle_mode = true
		button.button_group = _choice_group
		button.custom_minimum_size = Vector2(0, 68)
		button.pressed.connect(select_decision.bind(decision.id))
		_choices.add_child(button)
	_sign_button.disabled = true


func select_decision(decision_id: String) -> void:
	selected_decision = decision_id
	_sign_button.disabled = false


## Résumé de l'instruction du dossier, en BBCode. Statique pour être testé.
static func build_summary_bbcode(case_data: Dictionary, case_state: Dictionary) -> String:
	var lines: PackedStringArray = []
	lines.append("[b]Sujet :[/b] %s" % case_data.get("subject_name", "?"))
	lines.append("[b]Pièces consultées :[/b] %d/%d" % [case_state.viewed_documents.size(),
			case_data.get("documents", []).size()])
	lines.append("[b]Éléments notés au carnet :[/b] %d" % case_state.noted_facts.size())
	if case_state.contradictions_found.is_empty():
		lines.append("[b]Contradictions établies :[/b] aucune")
	else:
		lines.append("[b]Contradictions établies :[/b]")
		for key in case_state.contradictions_found:
			lines.append("  - %s" % describe_contradiction(case_data, key))
	return "\n".join(lines)


## Formule lisible d'une contradiction, à partir des éléments qui portent sur la même clé.
static func describe_contradiction(case_data: Dictionary, key: String) -> String:
	var labels: PackedStringArray = []
	for document in case_data.get("documents", []):
		for fact in document.get("facts", []):
			if fact.key == key:
				labels.append("%s (%s)" % [fact.label, document.title])
	return "  /  ".join(labels).replace("[", "[lb]")
