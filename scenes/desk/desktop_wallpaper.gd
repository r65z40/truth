class_name DesktopWallpaper
extends Control
## Fond du bureau : trame discrète et emblème du ministère (un œil dans un
## double cercle) avec la devise, dessinés aux couleurs du thème (type Desktop).
## Une image « desk_wallpaper » (data/images.json) remplace ce dessin : elle
## couvre tout le bureau, recadrée au centre.
##
## Le bureau change avec la partie (set_state, affichage seul) : la plaque
## porte le grade de l'agent, la plante de l'acte 1 se fane d'acte en acte, et
## la pupille de l'œil s'élargit à mesure que la hiérarchie se méfie.

const MINISTRY_NAME := "MINISTÈRE DE LA SÉCURITÉ NATIONALE"
const MOTTO := "LA VIGILANCE EST UN DEVOIR CIVIQUE"
const GRID := 6
## Coin du décor (plaque, plante) : à droite des icônes, au-dessus de la barre des tâches.
const BOTTOM_LEFT := Vector2(150, 70)

var _image: Texture2D
## Acte en cours (1 à 4), grade affiché sur la plaque, méfiance (0 à 100).
var act := 1
var plate := ""
var suspicion := 20


func set_state(new_act: int, new_plate: String, new_suspicion: int) -> void:
	act = clampi(new_act, 1, 4)
	plate = new_plate
	suspicion = clampi(new_suspicion, 0, 100)
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_image = ImageSlots.texture("desk_wallpaper")
	resized.connect(queue_redraw)


func _draw() -> void:
	if _image != null:
		var cover := maxf(size.x / _image.get_width(), size.y / _image.get_height())
		var image_size := _image.get_size() * cover
		draw_texture_rect(_image, Rect2((size - image_size) / 2.0, image_size), false)
		return
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
	# Plus la hiérarchie se méfie, plus l'œil s'ouvre sur vous.
	draw_circle(center, eye_h * lerpf(0.22, 0.5, suspicion / 100.0), emblem)

	var font := get_theme_default_font()
	var font_size := int(clampf(radius * 0.16, 14.0, 22.0))
	_draw_centered(font, tr(MINISTRY_NAME), center + Vector2(0, radius + font_size * 2.0), font_size, emblem)
	_draw_centered(font, tr(MOTTO), center + Vector2(0, radius + font_size * 3.6), int(font_size * 0.8), emblem)
	# En bas à gauche, à côté des icônes et au-dessus de la barre des tâches.
	_draw_plant(Vector2(BOTTOM_LEFT.x + 30.0, size.y - BOTTOM_LEFT.y - 44.0), emblem)
	if plate != "":
		_draw_plate(font, Vector2(BOTTOM_LEFT.x, size.y - BOTTOM_LEFT.y), emblem, pattern)


## Plaque de cuivre (dessinée aux couleurs du thème) : nom et grade de l'agent.
func _draw_plate(font: Font, bottom_left: Vector2, line: Color, fill: Color) -> void:
	var width := font.get_string_size(plate, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 24.0
	var rect := Rect2(bottom_left - Vector2(0, 30), Vector2(width, 30))
	draw_rect(rect, fill)
	draw_rect(rect, line, false, 2.0)
	draw_string(font, rect.position + Vector2(12, 20), plate, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, line)


## Plante en pot : droite et feuillue à l'acte 1, penchée, puis sèche, puis morte.
func _draw_plant(base: Vector2, color: Color) -> void:
	var pot := PackedVector2Array([base + Vector2(-18, 0), base + Vector2(18, 0), base + Vector2(22, -26), base + Vector2(-22, -26)])
	draw_colored_polygon(pot, color)
	var lean: float = [0.0, 0.25, 0.55, 0.9][act - 1]
	var leaves: int = [5, 4, 2, 0][act - 1]
	var top := base + Vector2(0, -26)
	var tip := top + Vector2(sin(lean) * 50.0, -cos(lean) * 50.0)
	draw_line(top, tip, color, 3.0)
	for i in leaves:
		var t := (i + 1.0) / (leaves + 1.0)
		var at := top.lerp(tip, t)
		var side := 1.0 if i % 2 == 0 else -1.0
		draw_line(at, at + Vector2(side * 14.0, -6.0 + lean * 8.0), color, 3.0)
	if act == 4:
		# Feuilles tombées au pied du pot.
		draw_line(base + Vector2(26, 0), base + Vector2(36, -2), color, 2.0)
		draw_line(base + Vector2(-30, 0), base + Vector2(-40, 1), color, 2.0)


func _draw_centered(font: Font, text: String, at: Vector2, font_size: int, color: Color) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, Vector2(at.x - width / 2.0, at.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
