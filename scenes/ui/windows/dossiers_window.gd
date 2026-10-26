class_name DossiersWindow
extends MinistryWindow
## Fenêtre « Dossiers » : le classeur. Liste des dossiers, pièces du dossier
## (lues ou à lire), lecture d'une pièce (ou ouverture dans sa propre fenêtre),
## carnet d'enquête (noter et confronter des éléments), avancement de l'enquête
## et formulaire de conclusion.
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
## Tant que le joueur n'a pas conclu ce nombre de dossiers, on considère qu'il
## est en apprentissage : le haut du dossier est allégé (objet + pièces
## seulement), car le bandeau « À FAIRE » du bureau guide déjà pas à pas.
## Même seuil que desk.gd (TUTORIAL_BUBBLE_UNTIL_CONCLUDED).
const TUTORIAL_UNTIL_CONCLUDED := 2

## Le joueur part sur le terrain (interrogatoire ou perquisition) : le bureau
## ouvre l'écran de scène.
signal field_requested(case_id: String)
## Le joueur ouvre le mini-jeu « comparer deux pièces » (facultatif).
signal comparison_requested(case_id: String)
## Le joueur veut poser une pièce à côté, dans sa propre fenêtre.
signal document_window_requested(case_id: String, document_id: String)
## Le formulaire de conclusion demande l'avis de VERITAS.
signal veritas_requested(case_id: String)

var current_case_id := ""
var current_document_id := ""
## Vrai si la dernière confrontation de ce dossier n'a rien donné (la bulle
## d'aide donne alors un conseil plus précis).
var last_confront_failed := false
## Éléments du carnet sélectionnés pour une confrontation (au plus 2).
var selected_facts: Array[String] = []
var _tab_group := ButtonGroup.new()
var _open_aside_button: Button
## Pièce pour laquelle la bulle d'aide a déjà fait défiler jusqu'aux éléments.
var _guide_scrolled_document := ""
var _photo := IdPhoto.new()

@onready var _case_list: VBoxContainer = %CaseList
@onready var _notebook: Control = %Notebook
@onready var _notebook_list: VBoxContainer = %NotebookList
@onready var _confront_button: Button = %ConfrontButton
@onready var _confront_result: Label = %ConfrontResult
@onready var _case_header: Label = %CaseHeader
@onready var _objective_label: Label = %ObjectiveLabel
@onready var _case_summary: Label = %CaseSummary
@onready var _actions_help: Label = %ActionsHelp
## Pièces du dossier, en liste verticale sous les dossiers (défile si besoin).
@onready var _document_tabs: VBoxContainer = %DocumentTabs
@onready var _document_tabs_scroll: ScrollContainer = %DocumentTabsScroll
@onready var _document_panel: PanelContainer = %DocumentPanel
@onready var _doc_scroll: ScrollContainer = %DocScroll
@onready var _doc_title: Label = %DocTitle
var _doc_icon: TextureRect
@onready var _doc_meta: Label = %DocMeta
@onready var _doc_body: RichTextLabel = %DocBody
@onready var _facts_list: VBoxContainer = %FactsList
@onready var _facts_panel: Control = %FactsPanel
@onready var _veritas_strip: Control = %VeritasStrip
@onready var _veritas_remark: Label = %VeritasRemark
@onready var _empty_hint: Label = %EmptyHint
@onready var _footer: Control = %Footer
@onready var _progress_label: Label = %ProgressLabel
@onready var _conclusion_button: Button = %ConclusionButton
@onready var _request_button: Button = %RequestButton
@onready var _consult_button: Button = %ConsultButton
@onready var _field_button: Button = %FieldButton
@onready var _compare_button: Button = %CompareButton
@onready var _conclusion_panel: PanelContainer = %ConclusionPanel


func _ready() -> void:
	super()
	_confront_button.pressed.connect(confront_selected)
	_conclusion_button.pressed.connect(open_conclusion)
	_request_button.pressed.connect(request_next_document)
	_consult_button.pressed.connect(consult_superior)
	_field_button.pressed.connect(func() -> void: field_requested.emit(current_case_id))
	_compare_button.pressed.connect(func() -> void: comparison_requested.emit(current_case_id))
	# Actions secondaires en plus petit, pour que le pied de pièce tienne sur une ligne.
	for button: Button in [_request_button, _consult_button, _field_button, _compare_button]:
		button.add_theme_font_size_override("font_size", 14)
	_conclusion_panel.submitted.connect(_on_conclusion_submitted)
	_conclusion_panel.cancelled.connect(close_conclusion)
	_conclusion_panel.veritas_requested.connect(veritas_requested.emit)
	_conclusion_panel.hide()
	# La photo d'identité s'affiche dans l'en-tête de la pièce, à droite du titre.
	_doc_title.add_sibling(_photo)
	_doc_title.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_photo.hide()
	# Icône du type de pièce (fiche, rapport, registre...) à gauche du titre.
	_doc_icon = TextureRect.new()
	_doc_icon.name = "DocIcon"
	_doc_icon.custom_minimum_size = Vector2(64, 64)
	_doc_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_doc_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_doc_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_doc_icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_doc_title.get_parent().add_child(_doc_icon)
	_doc_title.get_parent().move_child(_doc_icon, 0)
	# Poser la pièce à côté, dans sa propre fenêtre, pour la comparer à une autre.
	_open_aside_button = Button.new()
	_open_aside_button.name = "OpenAsideButton"
	_open_aside_button.text = "OUVRIR LA PIÈCE À CÔTÉ"
	_open_aside_button.tooltip_text = "Ouvrir cette pièce dans sa propre fenêtre, pour la comparer à une autre."
	_open_aside_button.custom_minimum_size = Vector2(0, 44)
	_open_aside_button.focus_mode = Control.FOCUS_NONE
	_open_aside_button.add_theme_font_size_override("font_size", 14)
	_open_aside_button.pressed.connect(open_current_aside)
	_document_tabs_scroll.add_sibling(_open_aside_button)
	_show_case_view(false)
	_doc_body.meta_clicked.connect(func(meta: Variant) -> void: DocumentWindow.on_passage_clicked(str(meta), note_fact))
	# Un élément noté depuis une pièce ouverte à part apparaît aussitôt au carnet.
	GameState.state_changed.connect(func() -> void:
		if is_open():
			_refresh_all())


func _on_opened() -> void:
	_refresh_case_list()
	if current_case_id != "":
		select_case(current_case_id)


## Ouvre un dossier et affiche sa première pièce non consultée (ou la première).
func select_case(case_id: String) -> void:
	var case_data := GameState.get_case_view(case_id)
	if case_data.is_empty():
		return
	if case_id != current_case_id:
		selected_facts.clear()
		_set_confront_result("")
		last_confront_failed = false
	current_case_id = case_id
	_apply_briefing(case_data)
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


## Briefing en tête du dossier : ce qu'on cherche (OBJET) et pourquoi ce dossier
## arrive (CONTEXTE). À défaut de bloc "briefing", on retombe sur le résumé.
func _apply_briefing(case_data: Dictionary) -> void:
	var briefing: Dictionary = case_data.get("briefing", {})
	var objective: String = briefing.get("objective", "")
	var context: String = briefing.get("context", case_data.get("summary", ""))
	_objective_label.text = "OBJET DE L'ENQUÊTE :  " + objective
	_objective_label.visible = objective != ""
	_case_summary.text = ("POURQUOI CE DOSSIER :  " + context) if context != "" else ""
	_case_summary.visible = context != ""


## Vrai tant que le joueur apprend (aide activée et peu de dossiers conclus) :
## on allège alors l'en-tête du dossier, le bandeau « À FAIRE » prenant le relais.
func _in_tutorial() -> bool:
	return Settings.guidance and GameState.concluded_case_count() < TUTORIAL_UNTIL_CONCLUDED


## Vrai si au moins deux éléments notés portent sur le même point (même clé) :
## ils parlent de la même personne ou du même fait et méritent d'être confrontés.
## Ne dit pas s'ils se contredisent : c'est au joueur de trancher.
func _notes_share_point(case_data: Dictionary, noted_facts: Array) -> bool:
	var keys := {}
	for fact_id in noted_facts:
		var key: String = CaseLibrary.get_fact(case_data, fact_id).get("key", "")
		if key == "":
			continue
		if keys.has(key):
			return true
		keys[key] = true
	return false


## Rappel des actions possibles, utile une fois le tutoriel passé (acte 1).
## Pendant le tutoriel il fait doublon avec le bandeau « À FAIRE » : on le masque.
func _refresh_actions_help() -> void:
	if current_case_id == "" or GameState.day_index >= 5 or _in_tutorial():
		_actions_help.visible = false
		return
	var parts: PackedStringArray = [
		"lire les pièces",
		"cliquer les passages soulignés pour les noter",
		"confronter deux éléments du carnet",
	]
	if GameState.is_feature_unlocked("request_document") and not GameState.get_requestable_documents(current_case_id).is_empty():
		parts.append("DEMANDER une pièce complémentaire")
	if GameState.is_feature_unlocked("consult_superior") and not CaseLibrary.get_case(current_case_id).get("consultation", {}).is_empty():
		parts.append("CONSULTER votre supérieur")
	var scene := GameState.get_field_scene(current_case_id)
	if not scene.is_empty() and GameState.is_feature_unlocked("field_work"):
		parts.append("vous rendre sur le terrain (%s)" % scene.get("button", "TERRAIN"))
	_actions_help.text = "Vous pouvez : " + " · ".join(parts) + "."
	_actions_help.visible = true


func select_document(document_id: String) -> void:
	var case_data := GameState.get_case_view(current_case_id)
	var document := CaseLibrary.get_document(case_data, document_id)
	if document.is_empty():
		return
	current_document_id = document_id
	for tab: Button in _document_tabs.get_children():
		tab.set_pressed_no_signal(tab.get_meta("document_id") == document_id)
		if tab.get_meta("document_id") == document_id:
			_scroll_to_tab.call_deferred(tab)
	_doc_title.text = document.title.to_upper()
	_doc_icon.texture = PixelIcons.document_icon(document.get("type", ""), 4)
	_doc_meta.text = DocumentWindow.describe_source(document)
	_photo.photo = document.get("photo", {})
	_photo.visible = document.has("photo")
	var remark := Veritas.document_remark(document)
	_veritas_strip.visible = remark != ""
	_veritas_remark.text = "%s > %s" % [Veritas.NAME, remark]
	_doc_scroll.scroll_vertical = 0
	GameState.mark_document_viewed(current_case_id, document_id)
	_refresh_all()


## Ouvre la pièce affichée dans sa propre fenêtre (le bureau la crée).
func open_current_aside() -> void:
	if current_case_id != "" and current_document_id != "":
		document_window_requested.emit(current_case_id, current_document_id)


# --- Carnet d'enquête ----------------------------------------------------------

func note_fact(fact_id: String) -> void:
	if fact_id in GameState.get_case_state(current_case_id).noted_facts:
		notify.emit("Déjà dans votre carnet.")
		return
	GameState.note_fact(current_case_id, fact_id)
	notify.emit("Élément noté dans votre carnet.")
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
	last_confront_failed = key == ""
	if key == "":
		_set_confront_result("PAS DE CONTRADICTION. Ces deux éléments peuvent être vrais en même temps. "
				+ "Cherchez deux éléments qui parlent du même fait (même jour, même personne) sans dire la même chose.", true)
		notify.emit("Pas de contradiction entre ces deux éléments.")
	elif key in already_found:
		_set_confront_result("Contradiction déjà établie.")
	else:
		_set_confront_result("CONTRADICTION ÉTABLIE. Elle figurera dans votre rapport.")
		notify.emit("CONTRADICTION ÉTABLIE")
	selected_facts.clear()
	_refresh_all()


## Confronte directement deux éléments du carnet (fiche glissée sur une autre).
func confront_pair(fact_a: String, fact_b: String) -> void:
	if fact_a == fact_b:
		return
	selected_facts.assign([fact_a, fact_b])
	confront_selected()


func _get_note_drag(_at: Vector2, fact_id: String, button: Button) -> Variant:
	var card := PanelContainer.new()
	card.theme_type_variation = &"DocumentPanel"
	card.custom_minimum_size = Vector2(minf(button.size.x, 280.0), 0)
	var label := Label.new()
	label.theme_type_variation = &"DocumentLabel"
	label.text = button.text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(label)
	button.set_drag_preview(card)
	return {"note": fact_id}


func _can_drop_note(_at: Vector2, data: Variant, fact_id: String) -> bool:
	return data is Dictionary and data.get("note", fact_id) != fact_id


func _drop_note(_at: Vector2, data: Variant, fact_id: String) -> void:
	confront_pair(data.note, fact_id)


## Verdict sous le carnet ; un échec s'affiche en rouge pour ne pas passer inaperçu.
func _set_confront_result(text: String, failed := false) -> void:
	_confront_result.text = text
	_confront_result.theme_type_variation = &"StampLabel" if failed else &"HeaderLabel"


## Conseil de la bulle d'aide propre à la fenêtre ("" : celui de l'étape).
func get_guide_text(part: String, case_id := "") -> String:
	if part != "notebook" or not last_confront_failed or case_id != current_case_id:
		return ""
	return CaseLibrary.get_case(case_id).get("guide", {}).get("notebook_retry",
			"Ces deux éléments ne se contredisent pas. Cherchez deux pièces qui parlent du même jour ou de la même personne, et notez ce qu'elles affirment.")


# --- Conclusion ----------------------------------------------------------------

func open_conclusion() -> void:
	if not GameState.can_decide(current_case_id):
		return
	_conclusion_panel.setup(current_case_id)
	_document_tabs_scroll.hide()
	_open_aside_button.hide()
	_document_panel.hide()
	_facts_panel.hide()
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
##
## Avec passages (voir passage_style()), chaque élément qui a une citation
## (« quote ») devient un lien souligné dans le texte (« fact:<id> ») ; un
## élément déjà noté est surligné.
## Couleur sépia des libellés de champs (colonne de gauche des fiches et en-têtes
## de registre), pour les distinguer des valeurs en encre pleine : la pièce se lit
## comme un vrai formulaire. Correspond à DocumentMeta du thème.
const LABEL_COLOR := "5c4f3d"
## Taille (px) des pictogrammes en ligne devant les libellés de champs.
const FIELD_ICON_SIZE := 22
## Mots-clés du libellé d'un champ -> pictogramme (res://ui/icons/<nom>.png).
const FIELD_ICONS := [
	["f_person", ["nom", "prénom", "prenom", "identité", "sujet", "citoyen :"]],
	["f_date", ["né", "date", "naissance", "délivr", "émis"]],
	["f_id", ["carte", "matricule", "numéro", "n°", "dossier", "permis"]],
	["f_work", ["profession", "travail", "emploi", "poste", "fonction", "grade"]],
	["f_family", ["situation", "famille", "conjoint", "enfant", "marié", "proche", "époux", "épouse"]],
	["f_home", ["adresse", "domicile", "district", "résidence", "logement"]],
	["f_warn", ["antécédent", "avertissement", "risque", "sanction", "mention", "alerte"]],
]

## Balise [img] du pictogramme correspondant au libellé, ou "" si aucun ne colle.
static func _field_icon_tag(label: String) -> String:
	var low := label.to_lower()
	for entry in FIELD_ICONS:
		for keyword in entry[1]:
			if low.contains(keyword):
				return "[img=%d]res://ui/icons/%s.png[/img]  " % [FIELD_ICON_SIZE, entry[0]]
	return ""


static func render_document_bbcode(document: Dictionary, passages := {}) -> String:
	var marker := PassageMarker.new(document.get("facts", []) if not passages.is_empty() else [], passages)
	var parts: PackedStringArray = []
	if document.has("fields"):
		var table := "[table=2]"
		for field in document.fields:
			table += "[cell padding=0,4,24,4]%s[color=%s][b]%s[/b][/color][/cell][cell padding=0,4,0,4]%s[/cell]" % [
				_field_icon_tag(field[0]), LABEL_COLOR, _escape(field[0]).to_upper(), marker.mark(field[1])]
		parts.append(table + "[/table]")
	if document.has("author"):
		parts.append("[color=%s][b]Rédacteur :[/b][/color] %s" % [LABEL_COLOR, marker.mark(document.author)])
	if document.has("rows"):
		var columns: Array = document.get("columns", [])
		var table := "[table=%d]" % maxi(columns.size(), 1)
		for column in columns:
			table += "[cell padding=0,4,20,6][color=%s][b]%s[/b][/color][/cell]" % [LABEL_COLOR, _escape(column).to_upper()]
		for row in document.rows:
			for value in row:
				table += "[cell padding=0,4,20,4]%s[/cell]" % marker.mark(str(value))
		parts.append(table + "[/table]")
	if document.has("body"):
		parts.append(marker.mark(document.body))
	return "\n\n".join(parts)


## Réglages de rendu des passages : éléments notés et couleurs du thème.
static func passage_style(control: Control, noted: Array) -> Dictionary:
	return {
		"noted": noted,
		"link": control.get_theme_color(&"passage", &"DocumentText").to_html(false),
		"highlight": control.get_theme_color(&"highlight", &"DocumentText").to_html(false),
	}


## Éléments de la pièce qui se notent en cliquant sur leur passage.
static func quoted_facts(document: Dictionary) -> Array:
	return document.get("facts", []).filter(func(fact: Dictionary) -> bool: return fact.get("quote", "") != "")


static func _escape(text: String) -> String:
	return text.replace("[", "[lb]")


## Repère les citations des éléments dans les morceaux de texte d'une pièce :
## chaque citation est balisée une seule fois (à sa première apparition).
class PassageMarker:
	var _facts: Array
	var _style: Dictionary
	var _used := {}

	func _init(facts: Array, style: Dictionary) -> void:
		_facts = facts
		_style = style

	func mark(text: String) -> String:
		var spans := []
		for fact in _facts:
			var quote: String = fact.get("quote", "")
			if quote == "" or _used.has(fact.id):
				continue
			var at := text.find(quote)
			if at == -1:
				continue
			var overlaps := false
			for span in spans:
				overlaps = overlaps or (at < span[1] and at + quote.length() > span[0])
			if overlaps:
				continue
			_used[fact.id] = true
			spans.append([at, at + quote.length(), fact.id])
		spans.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
		var out := ""
		var cursor := 0
		for span in spans:
			out += DossiersWindow._escape(text.substr(cursor, span[0] - cursor))
			var inner := DossiersWindow._escape(text.substr(span[0], span[1] - span[0]))
			if span[2] in _style.get("noted", []):
				out += "[url=fact:%s][bgcolor=#%s]%s[/bgcolor][/url]" % [span[2], _style.highlight, inner]
			else:
				out += "[url=fact:%s][color=#%s][u]%s[/u][/color][/url]" % [span[2], _style.link, inner]
			cursor = span[1]
		return out + DossiersWindow._escape(text.substr(cursor))


static func format_iso_date(iso: String) -> String:
	var bits := iso.split("-")
	if bits.size() != 3:
		return iso
	return "%s.%s.%s" % [bits[2], bits[1], bits[0]]


func _refresh_all() -> void:
	if current_case_id == "":
		return
	var case_data := GameState.get_case_view(current_case_id)
	var case_state := GameState.get_case_state(current_case_id)
	var status_text: String = STATUS_LABELS.get(case_state.status, "?")
	if case_state.decision != "":
		status_text += "  //  " + CaseLibrary.get_decision(case_data, case_state.decision).get("label", "").to_upper()
	_case_header.text = "DOSSIER N° %s  |  %s  |  %s" % [current_case_id, case_data.subject_name, status_text]
	_progress_label.text = progress_text(case_data, case_state)
	# Pendant l'apprentissage, on masque le compteur d'avancement : le bandeau
	# « À FAIRE » dit déjà quoi faire, et l'en-tête reste épuré.
	_progress_label.visible = not _in_tutorial()
	var can_decide := GameState.can_decide(current_case_id)
	_refresh_actions(can_decide)
	_refresh_actions_help()
	_conclusion_button.disabled = not can_decide
	_conclusion_button.text = "RÉDIGER LA CONCLUSION" if can_decide else "RAPPORT TRANSMIS"
	# « Ouvrir à côté » ne sert qu'à comparer deux pièces : inutile si le dossier
	# n'en a qu'une.
	_open_aside_button.visible = not _conclusion_panel.visible and case_data.get("documents", []).size() >= 2
	_refresh_facts(case_data)
	_refresh_tab_states()
	_refresh_notebook()
	_refresh_case_list()


## Avancement de l'enquête, en une ligne lisible : lecture, carnet, contradictions.
static func progress_text(case_data: Dictionary, case_state: Dictionary) -> String:
	if case_state.decision != "":
		return "Avancement : rapport transmis."
	var read: int = case_state.viewed_documents.size()
	var total: int = case_data.documents.size()
	var noted: int = case_state.noted_facts.size()
	var found: int = case_state.contradictions_found.size()
	var parts: PackedStringArray = [
		"%d/%d pièces lues" % [read, total],
		"%d élément%s noté%s" % [noted, "s" if noted > 1 else "", "s" if noted > 1 else ""],
		"%d contradiction%s établie%s" % [found, "s" if found > 1 else "", "s" if found > 1 else ""],
	]
	return "Avancement : " + "  ·  ".join(parts) + "."


# --- Actions qui coûtent du temps --------------------------------------------

func _refresh_actions(can_decide: bool) -> void:
	# Première journée : seulement lire, confronter, conclure.
	_request_button.visible = GameState.is_feature_unlocked("request_document")
	_consult_button.visible = GameState.is_feature_unlocked("consult_superior")
	var requestable := GameState.get_requestable_documents(current_case_id)
	var pending := _pending_requests()
	_request_button.disabled = not can_decide or requestable.is_empty() \
			or not WorkTime.check(GameState.hours_used, "request_document").ok
	if not pending.is_empty():
		_request_button.text = "DEMANDE EN COURS"
		_request_button.tooltip_text = "Réponse attendue demain : %s." % pending[0]
	else:
		_request_button.text = "DEMANDER (%d h)" % WorkTime.cost("request_document")
		_request_button.tooltip_text = ("Demander une pièce complémentaire, livrée demain : %s." % requestable[0].request.label) \
				if not requestable.is_empty() else "Aucune pièce complémentaire à demander pour ce dossier."
	var consultation: Dictionary = CaseLibrary.get_case(current_case_id).get("consultation", {})
	var consulted: bool = GameState.get_case_state(current_case_id).consulted
	_consult_button.disabled = not can_decide or consultation.is_empty() or consulted \
			or not WorkTime.check(GameState.hours_used, "consult_superior").ok
	_consult_button.text = "CONSULTÉ" if consulted else "CONSULTER (%d h)" % WorkTime.cost("consult_superior")
	_consult_button.tooltip_text = "Demander conseil à votre supérieur sur ce dossier (une fois)."
	# Terrain : interrogatoire ou perquisition, une fois par dossier.
	var scene := GameState.get_field_scene(current_case_id)
	_field_button.visible = not scene.is_empty() and GameState.is_feature_unlocked("field_work")
	if _field_button.visible:
		var cost := WorkTime.cost(scene.get("time_action", "interrogate"))
		var started := not GameState.get_field_state(scene.id).is_empty()
		_field_button.text = ("%s : FAIT" if started else "%s (%d h)") % ([scene.button] if started else [scene.button, cost])
		_field_button.disabled = not GameState.can_start_field(current_case_id) \
				or not WorkTime.check(GameState.hours_used, scene.get("time_action", "interrogate")).ok
		_field_button.tooltip_text = scene.get("title", "")
	# Comparer deux pièces : mini-jeu facultatif, sans coût d'heures, dès qu'un
	# dossier propose une confrontation de clichés ou de registres. Une pièce
	# n'est confrontable qu'une fois trouvée (ex. après la perquisition).
	var comparison := ComparisonRules.get_comparison(CaseLibrary.get_case(current_case_id))
	_compare_button.visible = not comparison.is_empty() \
			and EventRules.are_conditions_met(comparison.get("conditions", {}), GameState.get_condition_state())
	if _compare_button.visible:
		var done: bool = comparison.get("establishes", "") in GameState.get_case_state(current_case_id).contradictions_found
		_compare_button.text = "COMPARER : FAIT" if done else "COMPARER"
		_compare_button.tooltip_text = comparison.get("title", "")


## Libellés des pièces demandées aujourd'hui, pas encore arrivées.
func _pending_requests() -> Array:
	var labels := []
	var requested: Dictionary = GameState.get_case_state(current_case_id).requested_documents
	for document in CaseLibrary.get_case(current_case_id).get("documents", []):
		if requested.has(document.id) and int(requested[document.id]) >= GameState.day_index:
			labels.append(document.request.label)
	return labels


## Demande la prochaine pièce complémentaire disponible pour le dossier affiché.
func request_next_document() -> void:
	var requestable := GameState.get_requestable_documents(current_case_id)
	if requestable.is_empty():
		return
	if GameState.request_document(current_case_id, requestable[0].id):
		notify.emit("Demande transmise : %s. Réponse demain." % requestable[0].request.label)
	else:
		notify.emit("Plus assez de temps aujourd'hui pour cette demande.")
	_refresh_all()


func consult_superior() -> void:
	if GameState.consult_superior(current_case_id):
		notify.emit("Votre supérieur vous a répondu : voir MESSAGES.")
	else:
		notify.emit("Consultation impossible.")
	_refresh_all()


func _refresh_facts(case_data: Dictionary) -> void:
	var document := CaseLibrary.get_document(case_data, current_document_id)
	var noted: Array = GameState.get_case_state(current_case_id).noted_facts
	_doc_body.text = render_document_bbcode(document, passage_style(_doc_body, noted))
	DocumentWindow.fill_facts(_facts_list, %FactsTitle, document, noted, note_fact)
	_facts_panel.visible = not document.get("facts", []).is_empty() and not _conclusion_panel.visible


func _refresh_notebook() -> void:
	for child in _notebook_list.get_children():
		_notebook_list.remove_child(child)
		child.queue_free()
	var case_data := GameState.get_case_view(current_case_id)
	var case_state := GameState.get_case_state(current_case_id)
	for fact_id in case_state.noted_facts:
		var fact := CaseLibrary.get_fact(case_data, fact_id)
		var source := _document_of_fact(case_data, fact_id)
		var button := Button.new()
		button.name = "Noted_" + fact_id
		button.text = fact.get("label", fact_id)
		button.tooltip_text = "Source : %s. Cliquez pour le sélectionner." % source.get("title", "?")
		button.toggle_mode = true
		button.set_pressed_no_signal(fact_id in selected_facts)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.icon = PixelIcons.document_icon(source.get("type", ""), 2)
		button.custom_minimum_size = Vector2(0, 44)
		button.add_theme_font_size_override("font_size", 15)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(toggle_fact_selection.bind(fact_id))
		# Glisser une fiche sur une autre les confronte (à la souris comme au doigt).
		button.set_drag_forwarding(_get_note_drag.bind(fact_id, button), _can_drop_note.bind(fact_id), _drop_note.bind(fact_id))
		_notebook_list.add_child(button)
	# Le carnet n'apparaît qu'une fois un premier élément noté : écran plus clair
	# au début, le carnet se révèle quand il sert.
	_notebook.visible = current_case_id != "" and not case_state.noted_facts.is_empty()
	_confront_button.disabled = selected_facts.size() != MAX_SELECTED_FACTS
	# Indice « où chercher » : tant qu'aucune contradiction n'est établie (et hors
	# échec de confrontation affiché), on oriente le joueur sans donner la réponse.
	if selected_facts.is_empty() and case_state.contradictions_found.is_empty() and not last_confront_failed:
		if case_state.noted_facts.is_empty():
			if _confront_result.text == "":
				_set_confront_result("Notez des éléments (passages soulignés), puis sélectionnez-en deux à confronter.")
		elif _in_tutorial() and _notes_share_point(case_data, case_state.noted_facts):
			# Deux notes portent sur le même point : repère discret, pendant l'apprentissage.
			_set_confront_result("Deux de vos notes portent sur le même point. Sélectionnez-les toutes les deux, puis CONFRONTER.")
	elif selected_facts.size() == 1:
		_set_confront_result("Sélectionnez un second élément à confronter.")


## Pièce dont provient un élément (pour rappeler sa source dans le carnet).
static func _document_of_fact(case_data: Dictionary, fact_id: String) -> Dictionary:
	for document in case_data.get("documents", []):
		for fact in document.get("facts", []):
			if fact.id == fact_id:
				return document
	return {}


func _refresh_case_list() -> void:
	for child in _case_list.get_children():
		_case_list.remove_child(child)
		child.queue_free()
	for case_id in GameState.cases:
		var case_data := GameState.get_case_view(case_id)
		if case_data.is_empty():
			continue
		var case_state := GameState.get_case_state(case_id)
		var button := Button.new()
		button.text = "N° %s  [%s]\n%s" % [case_id, STATUS_LABELS.get(case_state.status, "?"), case_data.subject_name]
		button.add_theme_font_size_override("font_size", 15)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.toggle_mode = true
		button.set_pressed_no_signal(case_id == current_case_id)
		button.custom_minimum_size = Vector2(0, 52)
		button.set_meta("case_id", case_id)
		button.pressed.connect(select_case.bind(case_id))
		_case_list.add_child(button)


func _build_document_tabs(case_data: Dictionary) -> void:
	for child in _document_tabs.get_children():
		_document_tabs.remove_child(child)
		child.queue_free()
	for document in case_data.documents:
		var tab := Button.new()
		tab.text = document.title
		tab.icon = PixelIcons.document_icon(document.get("type", ""), 2)
		tab.theme_type_variation = &"DocumentTab"
		tab.name = "Tab_" + document.id
		tab.alignment = HORIZONTAL_ALIGNMENT_LEFT
		tab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tab.add_theme_font_size_override("font_size", 15)
		tab.toggle_mode = true
		tab.button_group = _tab_group
		tab.custom_minimum_size = Vector2(0, 44)
		tab.set_meta("document_id", document.id)
		tab.pressed.connect(select_document.bind(document.id))
		_document_tabs.add_child(tab)
	_refresh_tab_states()
	_fit_document_list.call_deferred()


## La liste des pièces prend la place de son contenu, jusqu'à quatre pièces
## environ ; au-delà elle défile, pour laisser de la place au carnet.
func _fit_document_list() -> void:
	var content := _document_tabs.get_combined_minimum_size().y
	_document_tabs_scroll.custom_minimum_size.y = minf(content, 4.5 * 46.0)


## Pièces pas encore lues : texte mis en avant et mention « à lire ».
func _refresh_tab_states() -> void:
	for tab: Button in _document_tabs.get_children():
		if tab.is_queued_for_deletion():
			continue
		var document_id: String = tab.get_meta("document_id")
		var unread := not GameState.is_document_viewed(current_case_id, document_id)
		var title: String = CaseLibrary.get_document(GameState.get_case_view(current_case_id), document_id).get("title", "")
		tab.text = title + ("  (à lire)" if unread else "")
		tab.theme_type_variation = &"DocumentTabNew" if unread else &"DocumentTab"
		tab.tooltip_text = "Pièce pas encore lue." if unread else "Pièce lue."


func _show_case_view(has_case: bool) -> void:
	_case_header.visible = has_case
	_objective_label.visible = has_case
	_case_summary.visible = has_case
	_actions_help.visible = has_case
	_document_tabs_scroll.visible = has_case
	_open_aside_button.visible = has_case
	%PiecesTitle.visible = has_case
	_document_panel.visible = has_case
	_facts_panel.visible = has_case
	_footer.visible = has_case
	_notebook.visible = has_case
	_empty_hint.visible = not has_case


## Bulle d'aide : l'onglet à lire, les éléments à noter, le carnet ou le bouton
## de conclusion (parties définies par Guidance).
func get_guide_target(part: String, case_id := "") -> Control:
	if case_id != "" and (case_id != current_case_id or part == "case"):
		for button in _case_list.get_children():
			if not button.is_queued_for_deletion() and button.get_meta("case_id", "") == case_id:
				return button
		return null
	if _conclusion_panel.visible:
		return _conclusion_panel
	if part.begins_with("tab:"):
		for tab in _document_tabs.get_children():
			if not tab.is_queued_for_deletion() and tab.get_meta("document_id") == part.substr(4):
				return tab
		return _document_tabs_scroll
	match part:
		"facts":
			for button in _facts_list.get_children():
				if button is Button and not button.disabled and not button.is_queued_for_deletion():
					# Les éléments sont en bas de la pièce : on y descend une fois par pièce.
					if _guide_scrolled_document != current_document_id:
						_guide_scrolled_document = current_document_id
						_doc_scroll.ensure_control_visible.call_deferred(button)
					return button
			# Passages soulignés encore à noter : le texte de la pièce.
			var document := CaseLibrary.get_document(GameState.get_case_view(current_case_id), current_document_id)
			var noted: Array = GameState.get_case_state(current_case_id).noted_facts
			for fact in quoted_facts(document):
				if not fact.id in noted:
					return _doc_body
			# Rien à noter sur cette pièce : les autres pièces.
			return _document_tabs_scroll
		"compare":
			return _compare_button
		"notebook":
			return _confront_button if selected_facts.size() == MAX_SELECTED_FACTS else _notebook_list
		"conclusion":
			return _conclusion_button
	return null


## Fait défiler la ligne d'onglets jusqu'à l'onglet, s'il existe encore
## (changer de dossier reconstruit les onglets avant l'appel différé).
func _scroll_to_tab(tab: Button) -> void:
	if is_instance_valid(tab) and _document_tabs_scroll.is_ancestor_of(tab):
		_document_tabs_scroll.ensure_control_visible(tab)
