extends Control
## Outil de visite des scènes : ouvre n'importe quelle scène du jeu en aperçu,
## sans dérouler l'histoire. Accessible depuis le menu principal.
##
## Mode bac à sable : chaque entrée repart d'une nouvelle partie en mémoire ;
## rien n'est sauvegardé. Les scènes de terrain passent par FieldScreen.preview
## (sans conditions ni coût en heures).

const MENU_SCENE := "res://scenes/main_menu/main_menu.tscn"
const INTRO_SCENE := "res://scenes/intro/intro.tscn"
const DESK_SCENE := "res://scenes/desk/desk.tscn"

var _list: Control
var _stage: Control
var _back_button: Button
var _note_label: Label
var _current: Node


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Music.play_context("menu")
	_build_ui.call_deferred()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.043, 0.051, 0.047)
	add_child(bg)

	_list = _build_list()
	add_child(_list)

	_stage = Control.new()
	_stage.name = "Stage"
	_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.hide()
	add_child(_stage)

	_back_button = Button.new()
	_back_button.text = "← GALERIE"
	_back_button.focus_mode = Control.FOCUS_NONE
	_back_button.custom_minimum_size = Vector2(140, 44)
	_back_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_back_button.offset_left = -156
	_back_button.offset_top = 12
	_back_button.offset_right = -12
	_back_button.offset_bottom = 56
	_back_button.z_index = 100
	_back_button.hide()
	_back_button.pressed.connect(_close)
	add_child(_back_button)


## Construit la liste des entrées, groupées par catégorie.
func _build_list() -> Control:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	scroll.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(column)

	var title := Label.new()
	title.text = "VISITE DES SCÈNES"
	title.theme_type_variation = &"HeaderLabel"
	title.add_theme_font_size_override("font_size", 28)
	column.add_child(title)
	_note_label = Label.new()
	_note_label.theme_type_variation = &"MutedLabel"
	_note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note_label.text = "Aperçu libre, sans jouer l'histoire. Rien n'est sauvegardé."
	column.add_child(_note_label)

	var back_menu := Button.new()
	back_menu.text = "← Retour au menu principal"
	back_menu.custom_minimum_size = Vector2(0, 44)
	back_menu.focus_mode = Control.FOCUS_NONE
	back_menu.pressed.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
	column.add_child(back_menu)

	_add_section(column, "OUTILS")
	_add_entry(column, "Médias : ce qui est fourni, ce qui manque (écouter, voir)",
			func() -> void: _mount(MediaCheck.new()))

	_add_section(column, "ÉCRANS")
	_add_entry(column, "Menu principal", func() -> void: _open_scene(MENU_SCENE))
	_add_entry(column, "Introduction", func() -> void: _open_scene(INTRO_SCENE))
	_add_entry(column, "Bureau (nouvelle partie)", func() -> void: _open_desk(func(_d: Node) -> void: pass))

	_add_section(column, "DOSSIERS")
	for case_id in CaseLibrary.get_case_ids():
		var case_data := CaseLibrary.get_case(case_id)
		var label := "N° %s — %s" % [case_id, case_data.get("title", case_id)]
		var id: String = case_id
		_add_entry(column, label, func() -> void: _open_desk(func(d: Node) -> void: d.open_case(id)))

	_add_section(column, "TERRAIN (interrogatoires / perquisitions)")
	for case_id in CaseLibrary.get_case_ids():
		var scene := FieldRules.scene_for_case(CaseLibrary.get_case(case_id))
		if scene.is_empty():
			continue
		var label := "%s — N° %s" % [scene.get("title", case_id), case_id]
		var id: String = case_id
		_add_entry(column, label, func() -> void: _open_field(id))

	return scroll


func _add_section(column: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.theme_type_variation = &"StampLabel"
	label.text = text
	label.add_theme_font_size_override("font_size", 15)
	column.add_child(HSeparator.new())
	column.add_child(label)


func _add_entry(column: VBoxContainer, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 44)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	column.add_child(button)


## Monte une scène déjà instanciée dans l'aire d'aperçu et masque la liste.
func _mount(node: Node) -> void:
	_close()
	_current = node
	_stage.add_child(node)
	_list.hide()
	_stage.show()
	_back_button.show()


## Ferme l'aperçu en cours et revient à la liste.
func _close() -> void:
	if _current and is_instance_valid(_current):
		_current.queue_free()
	_current = null
	_stage.hide()
	_back_button.hide()
	_list.show()


func _open_scene(path: String) -> void:
	_mount(load(path).instantiate())


## Ouvre le bureau dans une partie neuve, puis applique une action (ouvrir un
## dossier, lancer un aperçu de terrain…).
func _open_desk(after: Callable) -> void:
	GameState.new_game()
	var desk: Node = load(DESK_SCENE).instantiate()
	_mount(desk)
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(desk):
		after.call(desk)


## Aperçu d'une scène de terrain, via le bureau (FieldScreen.preview).
func _open_field(case_id: String) -> void:
	_open_desk(func(desk: Node) -> void:
		if not desk.field_screen.preview(case_id):
			_note_label.text = "La scène de terrain du dossier %s est indisponible." % case_id)
