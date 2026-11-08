class_name CoachOverlay
extends Control
## Bulle d'aide : un mot de MAZUR posé près de l'endroit où cliquer, et un cadre
## qui entoure cet endroit. Ne bloque jamais les clics (mouse_filter ignoré).
##
## target_provider renvoie le contrôle à signaler (ou null) ; il est appelé à
## chaque image, pour suivre les fenêtres et les sélections de l'interface.
## Couleurs : types de thème "CoachBubble" et "CoachHighlight".
##
## Bulle « amarrée » (dock) : le bureau range la bulle dans le bandeau « À FAIRE »,
## en haut de l'écran. Elle ne recouvre alors plus jamais le contenu : seul le
## cadre clignotant signale l'endroit où cliquer.

## Émis quand le joueur ferme la bulle avec la croix : le bureau masque l'astuce
## de l'étape en cours (elle réapparaît à l'étape suivante).
signal dismissed

const BUBBLE_WIDTH := 380.0
const GAP := 14.0
const MARGIN := 12.0

var target_provider: Callable
var text := "":
	set(value):
		text = value
		if is_node_ready():
			_refresh_text()

## Conteneur où ranger la bulle (bandeau d'aide), ou null : bulle flottante.
var dock: Container:
	set(value):
		dock = value
		if is_node_ready():
			_apply_dock()

var _target_rect := Rect2()
var _has_target := false
var _time := 0.0

@onready var _bubble: PanelContainer = %Bubble
@onready var _text_label: Label = %CoachText
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_refresh_text()
	_close_button.pressed.connect(func() -> void: dismissed.emit())
	_apply_dock()


func _apply_dock() -> void:
	if dock == null or _bubble.get_parent() == dock:
		return
	_bubble.get_parent().remove_child(_bubble)
	dock.add_child(_bubble)
	_bubble.position = Vector2.ZERO
	_bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Une seule ligne, sur le fond du bandeau : « R. MAZUR : conseil   ✕ ».
	_bubble.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var row := _close_button.get_parent()
	_text_label.get_parent().remove_child(_text_label)
	row.add_child(_text_label)
	row.move_child(_text_label, 0)
	_text_label.custom_minimum_size = Vector2.ZERO
	_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text_label.theme_type_variation = &"MutedLabel"
	_text_label.add_theme_font_size_override("font_size", 15)
	row.get_child(1).visible = false # « R. MAZUR, votre supérieur : »
	_refresh_text()


func _refresh_text() -> void:
	_text_label.text = (tr("R. MAZUR : ") + text) if is_docked() else text


## Bouton de fermeture de la bulle (elle peut vivre hors de ce nœud, dans le bandeau).
func close_button() -> Button:
	return _close_button


func is_docked() -> bool:
	return dock != null and _bubble.get_parent() == dock


## La bulle est-elle affichée (dans le bandeau ou près de la cible) ?
func is_bubble_shown() -> bool:
	return _bubble.visible


## Contrôle actuellement signalé, ou null.
func current_target() -> Control:
	if not target_provider.is_valid():
		return null
	var target = target_provider.call()
	if target is Control and is_instance_valid(target) and target.is_visible_in_tree():
		return target
	return null


func _process(delta: float) -> void:
	_time += delta
	var target := current_target()
	_has_target = target != null and visible and text != ""
	if is_docked():
		_bubble.visible = visible and text != ""
	else:
		_bubble.visible = _has_target
	if _has_target:
		_target_rect = Rect2(target.global_position - global_position, target.size * target.get_global_transform().get_scale())
		if not is_docked():
			_place_bubble()
	queue_redraw()


func _place_bubble() -> void:
	_bubble.size = Vector2(BUBBLE_WIDTH, 0)
	_bubble.reset_size()
	var bubble_size := _bubble.get_combined_minimum_size()
	bubble_size.x = BUBBLE_WIDTH
	var x := 0.0
	var y := 0.0
	# Une cible collée à un bord vertical (barre latérale, icônes) : la bulle se
	# pose à côté, centrée sur la cible, pour ne pas recouvrir le contenu central
	# (p. ex. la liste des pièces d'un dossier ouvert).
	var room_right := size.x - _target_rect.end.x - GAP - MARGIN
	var room_left := _target_rect.position.x - GAP - MARGIN
	if _target_rect.get_center().x < size.x * 0.25 and room_right >= bubble_size.x:
		x = _target_rect.end.x + GAP
		y = _target_rect.get_center().y - bubble_size.y / 2.0
	elif _target_rect.get_center().x > size.x * 0.75 and room_left >= bubble_size.x:
		x = _target_rect.position.x - GAP - bubble_size.x
		y = _target_rect.get_center().y - bubble_size.y / 2.0
	else:
		# Sinon : sous la cible, ou au-dessus si le bas manque de place.
		y = _target_rect.end.y + GAP
		if y + bubble_size.y > size.y - MARGIN:
			y = _target_rect.position.y - GAP - bubble_size.y
		x = _target_rect.get_center().x - bubble_size.x / 2.0
		# Cible trop haute et trop basse : bulle sur le côté.
		if y < MARGIN:
			y = _target_rect.get_center().y - bubble_size.y / 2.0
			x = _target_rect.position.x - GAP - bubble_size.x
			if x < MARGIN:
				x = _target_rect.end.x + GAP
	x = clampf(x, MARGIN, size.x - bubble_size.x - MARGIN)
	y = clampf(y, MARGIN, size.y - bubble_size.y - MARGIN)
	_bubble.position = Vector2(x, y)
	_bubble.size = bubble_size


func _draw() -> void:
	if not _has_target:
		return
	var pulse := 0.5 + 0.5 * sin(_time * 4.0)
	var frame := _target_rect.grow(4.0 + 3.0 * pulse)
	draw_rect(frame.grow(4.0), get_theme_color("glow", "CoachHighlight"))
	draw_rect(frame, get_theme_color("frame", "CoachHighlight"), false, 3.0)
	if is_docked():
		return
	# Trait de la bulle vers la cible.
	var bubble_rect := Rect2(_bubble.position, _bubble.size)
	var from := bubble_rect.get_center()
	from.y = bubble_rect.position.y if bubble_rect.position.y > frame.end.y else bubble_rect.end.y
	if bubble_rect.position.y <= frame.end.y and bubble_rect.end.y >= frame.position.y:
		from = Vector2(bubble_rect.end.x if bubble_rect.end.x < frame.position.x else bubble_rect.position.x,
				bubble_rect.get_center().y)
	var to := Vector2(clampf(from.x, frame.position.x, frame.end.x), clampf(from.y, frame.position.y, frame.end.y))
	draw_line(from, to, get_theme_color("frame", "CoachHighlight"), 2.0)
	draw_circle(to, 4.0, get_theme_color("frame", "CoachHighlight"))
