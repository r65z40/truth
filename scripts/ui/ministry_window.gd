class_name MinistryWindow
extends PanelContainer
## Cadre commun des fenêtres de l'ordinateur du ministère : cadre en relief,
## barre de titre (icône, titre, mention de classification) et boutons
## Réduire, Agrandir, Fermer (zones tactiles de 44 px).
##
## Une fenêtre concrète hérite de ce script et place son contenu dans un
## VBoxContainer enfant nommé « Layout » ; la barre de titre y est insérée en tête.
## Surcharger _on_opened() pour rafraîchir le contenu à l'ouverture.
##
## Posée dans un gestionnaire de fenêtres (WindowManager), la fenêtre devient
## mobile : on la déplace par sa barre de titre, on la réduit dans la barre des
## tâches, on l'agrandit (double-clic sur le titre ou bouton). Seule, elle garde
## sa place fixe et n'affiche que le bouton Fermer.

signal closed
## Demande au bureau d'afficher une courte notification.
signal notify(text: String)
## Émis à chaque ouverture (avant le rafraîchissement du contenu).
signal opened
## La fenêtre passe dans la barre des tâches, ou en revient.
signal minimized
signal restored

## Hauteur et largeur minimales des boutons de la barre de titre (tactile).
const TITLE_BUTTON_SIZE := 44
## Partie de la fenêtre qui doit rester visible quand on la déplace.
const KEEP_VISIBLE := Vector2(140, 44)

@export var window_title := "FENÊTRE"
@export var classification := "DIFFUSION RESTREINTE"
## Icône de la barre de titre et de la barre des tâches (voir PixelIcons).
@export var app_icon := ""
## Titre court pour la barre des tâches ; à défaut, le titre complet.
@export var task_title := ""

## Vrai quand un gestionnaire de fenêtres la rend déplaçable et réductible.
var movable := false:
	set(value):
		movable = value
		if _minimize_button:
			_minimize_button.visible = value
			_maximize_button.visible = value
var is_minimized := false
var is_maximized := false
var is_active := true

var _title_bar: PanelContainer
var _minimize_button: Button
var _maximize_button: Button
var _dragging := false
var _drag_offset := Vector2.ZERO
var _restore_rect := Rect2()


func _ready() -> void:
	theme_type_variation = &"DesktopWindow"
	var layout := get_node("Layout") as VBoxContainer
	_title_bar = _build_title_bar()
	layout.add_child(_title_bar)
	layout.move_child(_title_bar, 0)
	movable = movable


func open() -> void:
	show()
	is_minimized = false
	opened.emit()
	_on_opened()


func close() -> void:
	if not visible and not is_minimized:
		return
	hide()
	is_minimized = false
	closed.emit()


## Range la fenêtre dans la barre des tâches sans la fermer.
func minimize() -> void:
	if not visible:
		return
	hide()
	is_minimized = true
	minimized.emit()


## Ressort une fenêtre réduite, dans l'état où on l'avait laissée.
func restore() -> void:
	show()
	is_minimized = false
	restored.emit()


## La fenêtre est ouverte, à l'écran ou dans la barre des tâches.
func is_open() -> bool:
	return visible or is_minimized


func short_title() -> String:
	return task_title if task_title != "" else window_title


## Barre de titre colorée pour la fenêtre au premier plan, grise pour les autres.
func set_active(active: bool) -> void:
	is_active = active
	if _title_bar:
		_title_bar.theme_type_variation = &"TitleBarActive" if active else &"TitleBarInactive"


## Agrandit la fenêtre à toute la zone de travail, ou lui rend sa taille.
func toggle_maximize() -> void:
	if is_maximized:
		is_maximized = false
		position = _restore_rect.position
		size = _restore_rect.size
		clamp_to_parent()
	else:
		_restore_rect = Rect2(position, size)
		is_maximized = true
		fit_to_parent()


## Occupe toute la zone de travail (fenêtre agrandie, ou petit écran).
func fit_to_parent() -> void:
	position = Vector2.ZERO
	size = get_parent_area_size()


## Garde la fenêtre dans la zone de travail : entière en hauteur, et au moins
## un morceau de la barre de titre à portée de main sur les côtés.
func clamp_to_parent() -> void:
	var area := get_parent_area_size()
	size = size.min(area)
	position.x = clampf(position.x, KEEP_VISIBLE.x - size.x, maxf(area.x - KEEP_VISIBLE.x, 0.0))
	position.y = clampf(position.y, 0.0, maxf(area.y - size.y, 0.0))


## Contrôle à signaler par la bulle d'aide pour une partie de la fenêtre
## (voir Guidance) ; par défaut, aucun.
func get_guide_target(_part: String, _case_id := "") -> Control:
	return null


## Texte de la bulle d'aide propre à la fenêtre, s'il remplace celui de l'étape.
func get_guide_text(_part: String, _case_id := "") -> String:
	return ""


## Bouton de fermeture.
func get_close_button() -> Control:
	return find_child("CloseButton", true, false)


## À surcharger : appelé à chaque ouverture.
func _on_opened() -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if visible and is_active and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _on_title_bar_input(event: InputEvent) -> void:
	if not movable:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click:
			_dragging = false
			toggle_maximize()
		else:
			_dragging = event.pressed and not is_maximized
			_drag_offset = event.global_position - global_position
	elif event is InputEventMouseMotion and _dragging:
		global_position = event.global_position - _drag_offset
		clamp_to_parent()


func _build_title_bar() -> PanelContainer:
	var bar := PanelContainer.new()
	bar.name = "TitleBar"
	bar.theme_type_variation = &"TitleBarActive"
	bar.gui_input.connect(_on_title_bar_input)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(row)

	if app_icon != "":
		var icon := TextureRect.new()
		icon.texture = PixelIcons.get_icon(app_icon, 2)
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)

	var title := Label.new()
	title.name = "Title"
	title.text = window_title
	title.theme_type_variation = &"TitleLabel"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(title)

	if classification != "":
		var stamp := Label.new()
		stamp.text = classification
		stamp.theme_type_variation = &"TitleStamp"
		stamp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(stamp)

	_minimize_button = _title_button("MinimizeButton", "_", "Réduire dans la barre des tâches", minimize)
	row.add_child(_minimize_button)
	_maximize_button = _title_button("MaximizeButton", "[ ]", "Agrandir / rétablir", toggle_maximize)
	row.add_child(_maximize_button)
	row.add_child(_title_button("CloseButton", "X", "Fermer", close))
	return bar


func _title_button(button_name: String, text: String, tooltip: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = text
	button.tooltip_text = tooltip
	button.theme_type_variation = &"TitleButton"
	button.custom_minimum_size = Vector2(TITLE_BUTTON_SIZE, TITLE_BUTTON_SIZE)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	return button
