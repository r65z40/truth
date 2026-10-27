class_name NewsWindow
extends MinistryWindow
## Le journal du matin, « La Voix de Velmira » : la version officielle des faits,
## dont les décisions de l'agent racontées à la manière du régime.
## Lire ne coûte pas d'heures. Les articles viennent de NewsRules.

@onready var _masthead: Label = %Masthead
@onready var _tagline: Label = %Tagline
@onready var _articles: VBoxContainer = %Articles


func _ready() -> void:
	super()
	# Emblème du journal, centré au-dessus du bandeau-titre (sur papier).
	var emblem := TextureRect.new()
	emblem.name = "Emblem"
	emblem.texture = PixelIcons.get_icon("news", 4)
	emblem.custom_minimum_size = Vector2(64, 64)
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	emblem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_masthead.get_parent().add_child(emblem)
	_masthead.get_parent().move_child(emblem, 0)


func _on_opened() -> void:
	refresh()


## Remplit la page avec l'édition du jour.
func refresh() -> void:
	var edition := NewsRules.edition(current_state())
	_masthead.text = edition.masthead
	_tagline.text = tr("%s
N° %d  //  %s") % [edition.tagline, edition.number, FictionalCalendar.format_long(GameState.day_index)]
	for child in _articles.get_children():
		_articles.remove_child(child)
		child.queue_free()
	for i in edition.articles.size():
		_articles.add_child(_make_article(edition.articles[i], i == 0))


## État lu par les règles du journal (drapeaux, dossiers, décisions de la veille).
static func current_state() -> Dictionary:
	var state := GameState.get_condition_state()
	state["indicators"] = GameState.indicators
	state["decisions"] = GameState.decisions
	return state


func _make_article(article: Dictionary, is_lead: bool) -> Control:
	var box := VBoxContainer.new()
	box.name = "Article_" + article.id
	box.add_theme_constant_override("separation", 4)
	var section := Label.new()
	section.theme_type_variation = &"StampLabel"
	section.add_theme_font_size_override("font_size", 14)
	section.text = article.get("section", "")
	box.add_child(section)
	var headline := Label.new()
	headline.name = "Headline"
	headline.theme_type_variation = &"DocumentLabel"
	headline.add_theme_font_size_override("font_size", 26 if is_lead else 20)
	headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	headline.text = article.get("headline", "")
	box.add_child(headline)
	var body := Label.new()
	body.theme_type_variation = &"DocumentMeta"
	body.add_theme_font_size_override("font_size", 16)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.text = article.get("body", "")
	box.add_child(body)
	box.add_child(HSeparator.new())
	return box
