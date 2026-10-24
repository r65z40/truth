extends MinistryWindow
## Fenêtre « Dossiers » : liste des dossiers, lecture des pièces, carnet d'enquête
## (noter et confronter des éléments) et formulaire de conclusion.
##
## Lit CaseLibrary et GameState ; toutes les modifications passent par GameState.

const RELIABILITY_LABELS := {
	"A": "A, source sûre",
	"B": "B, généralement fiable",
	"C": "C, peu fiable",
	"D": "D, non vérifiée",
}
## Clés : valeurs de GameState.CASE_*.
const STATUS_LABELS := {
	"open": "EN COURS",
	"closed": "CLOS",
	"under_investigation": "ENQUÊTE COMPLÉMENTAIRE",
}
const MAX_SELECTED_FACTS := 2

var current_case_id := ""
var current_document_id := ""
## Éléments du carnet sélectionnés pour une confrontation (au plus 2).
var selected_facts: Array[String] = []
var _tab_group := ButtonGroup.new()

@onready var _case_list: VBoxContainer = %CaseList
@onready var _notebook: Control = %Notebook
@onready var _notebook_list: VBoxContainer = %NotebookList
@onready var _confront_button: Button = %ConfrontButton
@onready var _confront_result: Label = %ConfrontResult
@onready var _case_header: Label = %CaseHeader
@onready var _case_summary: Label = %CaseSummary
@onready var _document_tabs: HFlowContainer = %DocumentTabs
@onready var _document_panel: PanelContainer = %DocumentPanel
@onready var _doc_scroll: ScrollContainer = %DocScroll
@onready var _doc_title: Label = %DocTitle
@onready var _doc_meta: Label = %DocMeta
@onready var _doc_body: RichTextLabel = %DocBody
@onready var _facts_list: VBoxContainer = %FactsList
@onready var _veritas_strip: Control = %VeritasStrip
@onready var _veritas_remark: Label = %VeritasRemark
@onready var _empty_hint: Label = %EmptyHint
@onready var _footer: Control = %Footer
@onready var _progress_label: Label = %ProgressLabel
@onready var _conclusion_button: Button = %ConclusionButton
@onready var _conclusion_panel: PanelContainer = %ConclusionPanel


func _ready() -> void:
	super()
	_confront_button.pressed.connect(confront_selected)
	_conclusion_button.pressed.connect(open_conclusion)
	_conclusion_panel.submitted.connect(_on_conclusion_submitted)
	_conclusion_panel.cancelled.connect(close_conclusion)
	_conclusion_panel.hide()
	_show_case_view(false)


func _on_opened() -> void:
	_refresh_case_list()
	if current_case_id != "":
		select_case(current_case_id)


## Ouvre un dossier et affiche sa première pièce non consultée (ou la première).
func select_case(case_id: String) -> void:
	var case_data := CaseLibrary.get_case(case_id)
	if case_data.is_empty():
		return
	if case_id != current_case_id:
		selected_facts.clear()
		_confront_result.text = ""
	current_case_id = case_id
	_case_summary.text = case_data.get("summary", "")
	_build_document_tabs(case_data)
	_conclusion_panel.hide()
	_show_case_view(true)
	var documents: Array = case_data.documents
	var first_document: String = documents[0].id
	for document in documents:
		if not GameState.is_document_viewed(case_id, document.id):
			first_document = document.id
			break
	select_document(first_document)


func select_document(document_id: String) -> void:
	var case_data := CaseLibrary.get_case(current_case_id)
	var document := CaseLibrary.get_document(case_data, document_id)
	if document.is_empty():
		return
	current_document_id = document_id
	for tab: Button in _document_tabs.get_children():
		tab.set_pressed_no_signal(tab.get_meta("document_id") == document_id)
	_doc_title.text = document.title.to_upper()
	_doc_meta.text = "Source : %s\nFiabilité : %s     Date : %s" % [
		document.source,
		RELIABILITY_LABELS.get(document.reliability, document.reliability),
		_format_iso_date(document.get("date", "")),
	]
	_doc_body.text = render_document_bbcode(document)
	var remark := Veritas.document_remark(document)
	_veritas_strip.visible = remark != ""
	_veritas_remark.text = "%s > %s" % [Veritas.NAME, remark]
	_doc_scroll.scroll_vertical = 0
	GameState.mark_document_viewed(current_case_id, document_id)
	_refresh_all()


# --- Carnet d'enquête ----------------------------------------------------------

func note_fact(fact_id: String) -> void:
	GameState.note_fact(current_case_id, fact_id)
	_refresh_all()


## Sélectionne ou désélectionne un élément du carnet pour la confrontation.
func toggle_fact_selection(fact_id: String) -> void:
	if fact_id in selected_facts:
		selected_facts.erase(fact_id)
	else:
		if selected_facts.size() >= MAX_SELECTED_FACTS:
			selected_facts.pop_front()
		selected_facts.append(fact_id)
	_refresh_notebook()


## Confronte les deux éléments sélectionnés et affiche le verdict.
func confront_selected() -> void:
	if selected_facts.size() != MAX_SELECTED_FACTS:
		return
	var already_found: Array = GameState.get_case_state(current_case_id).contradictions_found.duplicate()
	var key := GameState.confront_facts(current_case_id, selected_facts[0], selected_facts[1])
	if key == "":
		_confront_result.text = "Aucune incohérence entre ces deux éléments."
	elif key in already_found:
		_confront_result.text = "Contradiction déjà établie."
	else:
		_confront_result.text = "CONTRADICTION ÉTABLIE. Elle figurera dans votre rapport."
	selected_facts.clear()
	_refresh_all()


# --- Conclusion ----------------------------------------------------------------

func open_conclusion() -> void:
	if not GameState.can_decide(current_case_id):
		return
	_conclusion_panel.setup(current_case_id)
	_document_tabs.hide()
	_document_panel.hide()
	_footer.hide()
	_conclusion_panel.show()


func close_conclusion() -> void:
	_conclusion_panel.hide()
	_show_case_view(current_case_id != "")


func _on_conclusion_submitted(decision_id: String) -> void:
	var case_id := current_case_id
	close_conclusion()
	# Le bureau réagit au signal GameState.decision_applied (message du supérieur).
	GameState.apply_decision(case_id, decision_id)
	_refresh_all()


# --- Rendu -----------------------------------------------------------------------

## Convertit une pièce en BBCode pour RichTextLabel. Statique pour pouvoir être testée.
## Un document peut combiner : fields (fiche), columns/rows (registre), author, body (texte).
static func render_document_bbcode(document: Dictionary) -> String:
	var parts: PackedStringArray = []
	if document.has("fields"):
		var table := "[table=2]"
		for field in document.fields:
			table += "[cell padding=0,4,24,4][b]%s[/b][/cell][cell padding=0,4,0,4]%s[/cell]" % [
				_escape(field[0]).to_upper(), _escape(field[1])]
		parts.append(table + "[/table]")
	if document.has("author"):
		parts.append("[b]Rédacteur :[/b] %s" % _escape(document.author))
	if document.has("rows"):
		var columns: Array = document.get("columns", [])
		var table := "[table=%d]" % maxi(columns.size(), 1)
		for column in columns:
			table += "[cell padding=0,4,20,6][b]%s[/b][/cell]" % _escape(column).to_upper()
		for row in document.rows:
			for value in row:
				table += "[cell padding=0,4,20,4]%s[/cell]" % _escape(value)
		parts.append(table + "[/table]")
	if document.has("body"):
		parts.append(_escape(document.body))
	return "\n\n".join(parts)


static func _escape(text: String) -> String:
	return text.replace("[", "[lb]")


static func _format_iso_date(iso: String) -> String:
	var bits := iso.split("-")
	if bits.size() != 3:
		return iso
	return "%s.%s.%s" % [bits[2], bits[1], bits[0]]


func _refresh_all() -> void:
	if current_case_id == "":
		return
	var case_data := CaseLibrary.get_case(current_case_id)
	var case_state := GameState.get_case_state(current_case_id)
	var status_text: String = STATUS_LABELS.get(case_state.status, "?")
	if case_state.decision != "":
		status_text += "  //  " + CaseLibrary.get_decision(case_data, case_state.decision).get("label", "").to_upper()
	_case_header.text = "DOSSIER N° %s  |  %s  |  %s" % [current_case_id, case_data.subject_name, status_text]
	_progress_label.text = "Pièces : %d/%d   Contradictions : %d" % [case_state.viewed_documents.size(),
			case_data.documents.size(), case_state.contradictions_found.size()]
	var can_decide := GameState.can_decide(current_case_id)
	_conclusion_button.disabled = not can_decide
	_conclusion_button.text = "RÉDIGER LA CONCLUSION" if can_decide else "RAPPORT TRANSMIS"
	_refresh_facts(case_data)
	_refresh_notebook()
	_refresh_case_list()


func _refresh_facts(case_data: Dictionary) -> void:
	for child in _facts_list.get_children():
		_facts_list.remove_child(child)
		child.queue_free()
	var document := CaseLibrary.get_document(case_data, current_document_id)
	var noted: Array = GameState.get_case_state(current_case_id).noted_facts
	for fact in document.get("facts", []):
		var button := Button.new()
		button.name = "Fact_" + fact.id
		var is_noted: bool = fact.id in noted
		button.text = ("NOTÉ  " if is_noted else "+ NOTER  ") + fact.label
		button.disabled = is_noted
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0, 44)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(note_fact.bind(fact.id))
		_facts_list.add_child(button)


func _refresh_notebook() -> void:
	for child in _notebook_list.get_children():
		_notebook_list.remove_child(child)
		child.queue_free()
	var case_data := CaseLibrary.get_case(current_case_id)
	var case_state := GameState.get_case_state(current_case_id)
	for fact_id in case_state.noted_facts:
		var fact := CaseLibrary.get_fact(case_data, fact_id)
		var button := Button.new()
		button.name = "Noted_" + fact_id
		button.text = fact.get("label", fact_id)
		button.toggle_mode = true
		button.set_pressed_no_signal(fact_id in selected_facts)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0, 44)
		button.add_theme_font_size_override("font_size", 15)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(toggle_fact_selection.bind(fact_id))
		_notebook_list.add_child(button)
	_confront_button.disabled = selected_facts.size() != MAX_SELECTED_FACTS
	if case_state.noted_facts.is_empty() and _confront_result.text == "":
		_confront_result.text = "Notez des éléments (en bas de chaque pièce), puis sélectionnez-en deux pour les confronter."


func _refresh_case_list() -> void:
	for child in _case_list.get_children():
		_case_list.remove_child(child)
		child.queue_free()
	for case_id in GameState.cases:
		var case_data := CaseLibrary.get_case(case_id)
		if case_data.is_empty():
			continue
		var case_state := GameState.get_case_state(case_id)
		var button := Button.new()
		button.text = "N° %s  [%s]\n%s" % [case_id, STATUS_LABELS.get(case_state.status, "?"), case_data.subject_name]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.toggle_mode = true
		button.set_pressed_no_signal(case_id == current_case_id)
		button.custom_minimum_size = Vector2(0, 64)
		button.pressed.connect(select_case.bind(case_id))
		_case_list.add_child(button)


func _build_document_tabs(case_data: Dictionary) -> void:
	for child in _document_tabs.get_children():
		_document_tabs.remove_child(child)
		child.queue_free()
	for document in case_data.documents:
		var tab := Button.new()
		tab.text = document.title
		tab.theme_type_variation = &"DocumentTab"
		tab.toggle_mode = true
		tab.button_group = _tab_group
		tab.custom_minimum_size = Vector2(0, 44)
		tab.set_meta("document_id", document.id)
		tab.pressed.connect(select_document.bind(document.id))
		_document_tabs.add_child(tab)


func _show_case_view(has_case: bool) -> void:
	_case_header.visible = has_case
	_case_summary.visible = has_case
	_document_tabs.visible = has_case
	_document_panel.visible = has_case
	_footer.visible = has_case
	_notebook.visible = has_case
	_empty_hint.visible = not has_case
