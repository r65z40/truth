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
	_doc_body.meta_clicked.connect(func(meta: Variant) -> void: on_passage_clicked(str(meta), note_fact))


## Affiche la pièce ; à appeler avant open().
func setup(new_case_id: String, new_document_id: String) -> void:
	case_id = new_case_id
	document_id = new_document_id
	var document := _document()
	window_title = "N° %s  //  %s" % [case_id, document.get("title", "")]
	task_title = document.get("title", "")
	app_icon = PixelIcons.DOCUMENT_ICONS.get(document.get("type", ""), "document")
	refresh_title()
	_doc_icon.texture = PixelIcons.document_icon(document.get("type", ""), 4)
	_doc_title.text = document.get("title", "").to_upper()
	_doc_meta.text = describe_source(document)
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


## Éléments à noter sous la pièce : un bouton pour ceux qui n'ont pas de passage
## dans le texte, et une consigne pour les passages soulignés.
static func fill_facts(list: Container, title: Label, document: Dictionary, noted: Array, on_note: Callable) -> void:
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	var quoted := DossiersWindow.quoted_facts(document)
	var left := quoted.filter(func(fact: Dictionary) -> bool: return not fact.id in noted).size()
	for fact in document.get("facts", []):
		if fact.get("quote", "") == "":
			list.add_child(make_fact_button(fact, fact.id in noted, on_note))
	if quoted.is_empty():
		title.text = "À NOTER : cliquez sur un élément pour le copier dans votre carnet"
	elif left > 0:
		title.text = "PASSAGES SOULIGNÉS : cliquez dessus dans le texte pour les noter (%d à noter)" % left
	else:
		title.text = "Tous les passages soulignés de cette pièce sont dans votre carnet."
	list.visible = list.get_child_count() > 0


## Clic sur un passage souligné (lien « fact:<id> ») : l'élément est noté.
static func on_passage_clicked(meta: String, on_note: Callable) -> void:
	if meta.begins_with("fact:"):
		on_note.call(meta.substr(5))


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
	if fact_id in GameState.get_case_state(case_id).noted_facts:
		notify.emit("Déjà dans votre carnet.")
		return
	GameState.note_fact(case_id, fact_id)
	notify.emit("Élément noté dans votre carnet.")


func _document() -> Dictionary:
	return CaseLibrary.get_document(GameState.get_case_view(case_id), document_id)


func _refresh_facts() -> void:
	if case_id == "" or not is_inside_tree():
		return
	var document := _document()
	var noted: Array = GameState.get_case_state(case_id).noted_facts
	_doc_body.text = DossiersWindow.render_document_bbcode(document, DossiersWindow.passage_style(_doc_body, noted))
	fill_facts(_facts_list, _facts_title, document, noted, note_fact)
	_facts_title.visible = not document.get("facts", []).is_empty()
