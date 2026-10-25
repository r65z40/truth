class_name DesktopWallpaper
extends Control
## Fond du bureau : trame discrète et emblème du ministère (un œil dans un
## double cercle) avec la devise, dessinés aux couleurs du thème (type Desktop).

const MINISTRY_NAME := "MINISTÈRE DE LA SÉCURITÉ NATIONALE"
const MOTTO := "LA VIGILANCE EST UN DEVOIR CIVIQUE"
const GRID := 6


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var wallpaper := get_theme_color(&"wallpaper", &"Desktop")
	var pattern := get_theme_color(&"pattern", &"Desktop")
	var emblem := get_theme_color(&"emblem", &"Desktop")
	draw_rect(Rect2(Vector2.ZERO, size), wallpaper)
	# Trame en quinconce, façon écran à faible définition.
	for y in range(0, int(size.y), GRID):
		var shift := GRID / 2 if (y / GRID) % 2 == 1 else 0
		for x in range(shift, int(size.x), GRID * 2):
			draw_rect(Rect2(x, y, 1, 1), pattern)

	var center := size * Vector2(0.55, 0.42)
	var radius := clampf(minf(size.x, size.y) * 0.2, 60.0, 150.0)
	draw_arc(center, radius, 0.0, TAU, 72, emblem, 6.0)
	draw_arc(center, radius * 0.86, 0.0, TAU, 72, emblem, 2.0)
	# L'œil : deux arcs en amande, l'iris et la pupille.
	var eye_w := radius * 0.62
	var eye_h := radius * 0.34
	var top := PackedVector2Array()
	var bottom := PackedVector2Array()
	for i in 25:
		var t := lerpf(-1.0, 1.0, i / 24.0)
		top.append(center + Vector2(t * eye_w, -(1.0 - t * t) * eye_h))
		bottom.append(center + Vector2(t * eye_w, (1.0 - t * t) * eye_h))
	draw_polyline(top, emblem, 5.0)
	draw_polyline(bottom, emblem, 5.0)
	draw_arc(center, eye_h * 0.62, 0.0, TAU, 40, emblem, 4.0)
	draw_circle(center, eye_h * 0.28, emblem)

	var font := get_theme_default_font()
	var font_size := int(clampf(radius * 0.16, 14.0, 22.0))
	_draw_centered(font, MINISTRY_NAME, center + Vector2(0, radius + font_size * 2.0), font_size, emblem)
	_draw_centered(font, MOTTO, center + Vector2(0, radius + font_size * 3.6), int(font_size * 0.8), emblem)


func _draw_centered(font: Font, text: String, at: Vector2, font_size: int, color: Color) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, Vector2(at.x - width / 2.0, at.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
