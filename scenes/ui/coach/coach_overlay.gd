class_name CoachOverlay
extends Control
## Bulle d'aide : un mot de MAZUR posé près de l'endroit où cliquer, et un cadre
## qui entoure cet endroit. Ne bloque jamais les clics (mouse_filter ignoré).
##
## target_provider renvoie le contrôle à signaler (ou null) ; il est appelé à
## chaque image, pour suivre les fenêtres et les sélections de l'interface.
## Couleurs : types de thème "CoachBubble" et "CoachHighlight".

const BUBBLE_WIDTH := 380.0
const GAP := 14.0
const MARGIN := 12.0

var target_provider: Callable
var text := "":
	set(value):
		text = value
		if is_node_ready():
			_text_label.text = value

var _target_rect := Rect2()
var _has_target := false
var _time := 0.0

@onready var _bubble: PanelContainer = %Bubble
@onready var _text_label: Label = %CoachText


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text_label.text = text


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
	_bubble.visible = _has_target
	if _has_target:
		_target_rect = Rect2(target.global_position - global_position, target.size * target.get_global_transform().get_scale())
		_place_bubble()
	queue_redraw()


func _place_bubble() -> void:
	_bubble.size = Vector2(BUBBLE_WIDTH, 0)
	_bubble.reset_size()
	var bubble_size := _bubble.get_combined_minimum_size()
	bubble_size.x = BUBBLE_WIDTH
	var below := _target_rect.end.y + GAP
	var y := below
	if below + bubble_size.y > size.y - MARGIN:
		y = _target_rect.position.y - GAP - bubble_size.y
	# Cible trop haute et trop basse : bulle à gauche ou à droite.
	var x := _target_rect.get_center().x - bubble_size.x / 2.0
	if y < MARGIN:
		y = clampf(_target_rect.get_center().y - bubble_size.y / 2.0, MARGIN, size.y - bubble_size.y - MARGIN)
		x = _target_rect.position.x - GAP - bubble_size.x
		if x < MARGIN:
			x = _target_rect.end.x + GAP
	x = clampf(x, MARGIN, size.x - bubble_size.x - MARGIN)
	_bubble.position = Vector2(x, y)
	_bubble.size = bubble_size


func _draw() -> void:
	if not _has_target:
		return
	var pulse := 0.5 + 0.5 * sin(_time * 4.0)
	var frame := _target_rect.grow(4.0 + 3.0 * pulse)
	draw_rect(frame.grow(4.0), get_theme_color("glow", "CoachHighlight"))
	draw_rect(frame, get_theme_color("frame", "CoachHighlight"), false, 3.0)
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
