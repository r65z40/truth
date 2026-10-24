extends MinistryWindow
## Fenêtre « Dossiers » : liste des dossiers assignés et lecture des pièces.
##
## Affiche les données de CaseLibrary et enregistre la consultation des pièces
## dans GameState. Le formulaire de conclusion arrivera à l'itération suivante.

const RELIABILITY_LABELS := {
	"A": "A, source sûre",
	"B": "B, généralement fiable",
	"C": "C, peu fiable",
	"D": "D, non vérifiée",
}
## Clés : valeurs de GameState.CASE_OPEN / CASE_CLOSED.
const STATUS_LABELS := {
	"open": "EN COURS",
	"closed": "CLOS",
}

var current_case_id := ""
var current_document_id := ""
var _tab_group := ButtonGroup.new()

@onready var _case_list: VBoxContainer = %CaseList
@onready var _case_header: Label = %CaseHeader
@onready var _case_summary: Label = %CaseSummary
@onready var _document_tabs: HFlowContainer = %DocumentTabs
@onready var _document_panel: PanelContainer = %DocumentPanel
@onready var _doc_scroll: ScrollContainer = %DocScroll
@onready var _doc_title: Label = %DocTitle
@onready var _doc_meta: Label = %DocMeta
@onready var _doc_body: RichTextLabel = %DocBody
@onready var _empty_hint: Label = %EmptyHint
@onready var _progress_label: Label = %ProgressLabel


func _ready() -> void:
	super()
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
	current_case_id = case_id
	var case_state := GameState.get_case_state(case_id)
	_case_header.text = "DOSSIER N° %s  |  %s  |  %s" % [case_id, case_data.subject_name,
			STATUS_LABELS.get(case_state.status, "?")]
	_case_summary.text = case_data.get("summary", "")
	_build_document_tabs(case_data)
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
	_doc_scroll.scroll_vertical = 0
	GameState.mark_document_viewed(current_case_id, document_id)
	_refresh_progress(case_data)
	_refresh_case_list()


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


func _refresh_case_list() -> void:
	for child in _case_list.get_children():
		child.queue_free()
	for case_id in GameState.cases:
		var case_data := CaseLibrary.get_case(case_id)
		if case_data.is_empty():
			continue
		var case_state := GameState.get_case_state(case_id)
		var button := Button.new()
		button.text = "N° %s  [%s]\n%s\nPièces lues : %d/%d" % [
			case_id, STATUS_LABELS.get(case_state.status, "?"), case_data.subject_name,
			case_state.viewed_documents.size(), case_data.documents.size()]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_pressed = case_id == current_case_id
		button.custom_minimum_size = Vector2(0, 88)
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


func _refresh_progress(case_data: Dictionary) -> void:
	var case_state := GameState.get_case_state(current_case_id)
	_progress_label.text = "Pièces consultées : %d/%d" % [case_state.viewed_documents.size(),
			case_data.documents.size()]


func _show_case_view(has_case: bool) -> void:
	_case_header.visible = has_case
	_case_summary.visible = has_case
	_document_tabs.visible = has_case
	_document_panel.visible = has_case
	_progress_label.visible = has_case
	_empty_hint.visible = not has_case
