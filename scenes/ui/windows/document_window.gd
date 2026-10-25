class_name DocumentWindow
extends MinistryWindow
## Une pièce de dossier ouverte dans sa propre fenêtre, pour la poser à côté
## d'une autre et les comparer. On y note les éléments comme dans le dossier.
##
## Lit CaseLibrary et GameState ; noter un élément passe par GameState.

var case_id := ""
var document_id := ""

var _photo := IdPhoto.new()

@onready var _doc_icon: TextureRect = %DocIcon
@onready var _doc_title: Label = %DocTitle
@onready var _doc_meta: Label = %DocMeta
@onready var _doc_body: RichTextLabel = %DocBody
@onready var _facts_title: Label = %FactsTitle
@onready var _facts_list: VBoxContainer = %FactsList


func _ready() -> void:
	super()
	_doc_title.add_sibling(_photo)
	_photo.hide()
	GameState.state_changed.connect(_refresh_facts)


## Affiche la pièce ; à appeler avant open().
func setup(new_case_id: String, new_document_id: String) -> void:
	case_id = new_case_id
	document_id = new_document_id
	var document := _document()
	window_title = "N° %s  //  %s" % [case_id, document.get("title", "")]
	task_title = document.get("title", "")
	app_icon = PixelIcons.DOCUMENT_ICONS.get(document.get("type", ""), "document")
	refresh_title()
	_doc_icon.texture = PixelIcons.document_icon(document.get("type", ""), 3)
	_doc_title.text = document.get("title", "").to_upper()
	_doc_meta.text = describe_source(document)
	_doc_body.text = DossiersWindow.render_document_bbcode(document)
	_photo.photo = document.get("photo", {})
	_photo.visible = document.has("photo")
	_refresh_facts()


## Ligne d'origine d'une pièce : source, fiabilité, date.
static func describe_source(document: Dictionary) -> String:
	return "Source : %s\nFiabilité : %s     Date : %s" % [
		document.get("source", "?"),
		DossiersWindow.RELIABILITY_LABELS.get(document.get("reliability", ""), document.get("reliability", "?")),
		DossiersWindow.format_iso_date(document.get("date", "")),
	]


## Bouton « + élément » (ou « NOTÉ : élément ») commun au dossier et aux pièces.
static func make_fact_button(fact: Dictionary, is_noted: bool, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.name = "Fact_" + fact.id
	button.text = ("NOTÉ : " if is_noted else "+ NOTER : ") + fact.label
	button.disabled = is_noted
	button.tooltip_text = "Déjà dans votre carnet." if is_noted else "Ajouter cet élément à votre carnet d'enquête."
	button.custom_minimum_size = Vector2(0, 44)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 15)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(on_pressed.bind(fact.id))
	return button


func note_fact(fact_id: String) -> void:
	GameState.note_fact(case_id, fact_id)
	notify.emit("Élément noté dans votre carnet.")


func _document() -> Dictionary:
	return CaseLibrary.get_document(GameState.get_case_view(case_id), document_id)


func _refresh_facts() -> void:
	if case_id == "" or not is_inside_tree():
		return
	for child in _facts_list.get_children():
		_facts_list.remove_child(child)
		child.queue_free()
	var facts: Array = _document().get("facts", [])
	var noted: Array = GameState.get_case_state(case_id).noted_facts
	for fact in facts:
		_facts_list.add_child(make_fact_button(fact, fact.id in noted, note_fact))
	_facts_title.visible = not facts.is_empty()
	_facts_list.visible = not facts.is_empty()
