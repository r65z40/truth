extends ColorRect
## Introduction d'une nouvelle partie : pages illustrées (data/intro.json),
## puis le bureau. Passable à tout moment.

const DATA_PATH := "res://data/intro.json"
const DESK_SCENE := "res://scenes/desk/desk.tscn"

var pages: Array = []
var page_index := 0

@onready var _art: IntroArt = %Art
@onready var _title_label: Label = %TitleLabel
@onready var _text_label: Label = %TextLabel
@onready var _page_label: Label = %PageLabel
@onready var _next_button: Button = %NextButton


func _ready() -> void:
	Music.play_context("intro")
	pages = DataLoader.load_json(DATA_PATH).get("pages", [])
	%SkipButton.pressed.connect(finish)
	_next_button.pressed.connect(next_page)
	_show_page(0)


func next_page() -> void:
	if page_index + 1 >= pages.size():
		finish()
	else:
		_show_page(page_index + 1)


func finish() -> void:
	get_tree().change_scene_to_file(DESK_SCENE)


func _show_page(index: int) -> void:
	page_index = index
	var page: Dictionary = pages[index]
	_art.scene = page.get("art", "city")
	# Une image fournie (data/images.json, « intro_<art> ») remplace le dessin.
	_art.image = ImageSlots.texture("intro_" + _art.scene)
	_title_label.text = page.get("title", "")
	_text_label.text = page.get("text", "")
	_page_label.text = "%d / %d" % [index + 1, pages.size()]
	_next_button.text = tr("PRENDRE SON POSTE") if index == pages.size() - 1 else tr("SUIVANT")
	_next_button.grab_focus()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)
