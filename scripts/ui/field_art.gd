class_name FieldArt
extends Control
## Décors des scènes de terrain, dessinés en code (aucune image importée), vus
## à la première personne. Repère de dessin CANVAS, mis à l'échelle du contrôle ;
## to_local_rect() convertit une zone du repère (les "spot" des perquisitions)
## en coordonnées du contrôle.
## scene : "interrogation" (le sujet de l'autre côté de la table, d'après subject)
## ou "sedlar_flat" (l'appartement des SEDLAR).
## Couleurs : type de thème "IntroArt" (même palette que l'introduction).

const CANVAS := Vector2(640, 300)

var scene := "interrogation":
	set(value):
		scene = value
		queue_redraw()
## Pour un interrogatoire : traits du sujet (même format que la photo d'identité).
var subject: Dictionary = {}:
	set(value):
		subject = value
		queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(320, 150)
	mouse_filter = Control.MOUSE_FILTER_PASS
	resized.connect(queue_redraw)


func get_canvas_scale() -> float:
	return minf(size.x / CANVAS.x, size.y / CANVAS.y)


func _offset() -> Vector2:
	return (size - CANVAS * get_canvas_scale()) / 2.0


## Zone [x, y, w, h] du repère de dessin, en coordonnées du contrôle.
func to_local_rect(area: Array) -> Rect2:
	var factor := get_canvas_scale()
	return Rect2(_offset() + Vector2(area[0], area[1]) * factor, Vector2(area[2], area[3]) * factor)


func _c(name: String) -> Color:
	return get_theme_color(name, "IntroArt")


func _draw() -> void:
	# Le décor déborde du repère : mur en haut, sol en bas, sans bandes noires.
	var horizon := _offset().y + 230.0 * get_canvas_scale()
	match scene:
		"interrogation":
			draw_rect(Rect2(Vector2.ZERO, size), _c("sky"))
			draw_rect(Rect2(0, 0, size.x, _offset().y + 200.0 * get_canvas_scale()), _c("building_far"))
		"sedlar_flat":
			draw_rect(Rect2(0, 0, size.x, horizon), _c("paper_dark").darkened(0.45))
			draw_rect(Rect2(0, horizon, size.x, size.y - horizon), _c("wood"))
	draw_set_transform(_offset(), 0.0, Vector2.ONE * get_canvas_scale())
	match scene:
		"interrogation":
			_draw_interrogation()
		"sedlar_flat":
			_draw_sedlar_flat()
	draw_set_transform(Vector2.ZERO)


## Salle d'audition : mur nu, lampe, le sujet assis en face, la table au premier plan.
func _draw_interrogation() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS), _c("sky"))
	draw_rect(Rect2(0, 0, CANVAS.x, 200), _c("building_far"))
	for x in range(0, int(CANVAS.x), 80):
		draw_line(Vector2(x, 0), Vector2(x, 200), Color(_c("sky"), 0.6), 2.0)
	# Cône de la lampe.
	draw_colored_polygon(PackedVector2Array([Vector2(300, 18), Vector2(340, 18), Vector2(470, 300), Vector2(170, 300)]),
			Color(_c("window"), 0.10))
	draw_line(Vector2(320, 0), Vector2(320, 12), _c("ink"), 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(300, 22), Vector2(310, 10), Vector2(330, 10), Vector2(340, 22)]), _c("building"))
	_draw_subject(Vector2(320, 120))
	# Table et papiers.
	draw_rect(Rect2(60, 228, 520, 72), _c("wood"))
	draw_rect(Rect2(60, 228, 520, 6), _c("wood").lightened(0.15))
	draw_rect(Rect2(150, 244, 120, 46), _c("paper"))
	draw_rect(Rect2(380, 240, 90, 50), _c("paper_dark"))
	for i in 4:
		draw_rect(Rect2(160, 252 + i * 9, 90 - i * 12, 3), Color(_c("ink"), 0.5))
	# Le planton, silhouette derrière la porte vitrée.
	draw_rect(Rect2(560, 40, 60, 150), _c("building"))
	draw_rect(Rect2(570, 50, 40, 60), Color(_c("window"), 0.15))
	draw_circle(Vector2(590, 78), 10, _c("sky"))


## Buste du sujet, d'après ses traits (visage, cheveux, moustache, cicatrice).
func _draw_subject(head_center: Vector2) -> void:
	var skin: Color = get_theme_color("skin", "IdPhoto")
	var shade: Color = get_theme_color("shade", "IdPhoto")
	var ink := _c("ink")
	var hair_color := shade.lerp(_c("paper"), 0.45) if subject.get("gray", false) else ink
	var long_face: bool = subject.get("face", "round") == "long"
	var head := Vector2(42, 56 if long_face else 50)
	# Épaules (bleu de travail).
	draw_colored_polygon(PackedVector2Array([Vector2(190, 240), Vector2(205, 190), Vector2(280, 168),
			Vector2(360, 168), Vector2(435, 190), Vector2(450, 240)]), _c("cloth"))
	draw_rect(Rect2(head_center.x - 16, head_center.y + head.y - 14, 32, 30), skin.darkened(0.15))
	draw_colored_polygon(_ellipse(head_center, head), skin)
	match subject.get("hair", "short"):
		"short", "long":
			draw_colored_polygon(_ellipse_arc(head_center, head + Vector2(4, 5), 0.25), hair_color)
		"receding":
			draw_rect(Rect2(head_center.x - head.x - 3, head_center.y - 20, 9, 26), hair_color)
			draw_rect(Rect2(head_center.x + head.x - 6, head_center.y - 20, 9, 26), hair_color)
		"curly":
			for i in 9:
				var angle := PI + PI * i / 8.0
				draw_circle(head_center + Vector2(cos(angle) * head.x, sin(angle) * head.y * 0.9), 12.0, hair_color)
	var eye_y := head_center.y - 4
	for side in [-1, 1]:
		draw_line(Vector2(head_center.x + side * 22, eye_y - 9), Vector2(head_center.x + side * 8, eye_y - 7), ink, 3.0)
		draw_circle(Vector2(head_center.x + side * 15, eye_y), 3.5, ink)
	draw_line(Vector2(head_center.x, eye_y + 5), Vector2(head_center.x - 5, eye_y + 22), shade, 2.0)
	draw_line(Vector2(head_center.x - 12, eye_y + 36), Vector2(head_center.x + 12, eye_y + 36), shade.darkened(0.3), 2.5)
	if subject.get("facial_hair", "none") in ["mustache", "beard"]:
		draw_rect(Rect2(head_center.x - 15, eye_y + 26, 30, 6), hair_color)
	if subject.get("mark", "none") == "scar":
		draw_line(Vector2(head_center.x + 22, eye_y + 6), Vector2(head_center.x + 30, eye_y + 26), _c("scar"), 2.5)


## Appartement des SEDLAR : commode, poêle, photo au mur, lit, lit d'enfant, cartable.
func _draw_sedlar_flat() -> void:
	# Mur à rayures et plancher.
	draw_rect(Rect2(Vector2.ZERO, CANVAS), _c("paper_dark").darkened(0.45))
	for x in range(0, int(CANVAS.x), 24):
		draw_rect(Rect2(x, 0, 10, 230), Color(_c("paper_dark"), 0.12))
	draw_rect(Rect2(0, 230, CANVAS.x, 70), _c("wood"))
	for x in range(0, int(CANVAS.x), 46):
		draw_line(Vector2(x, 230), Vector2(x - 30, 300), Color(_c("ink"), 0.35), 1.0)
	# Fenêtre sur les toits.
	draw_rect(Rect2(400, 20, 90, 80), _c("sky"))
	draw_rect(Rect2(410, 60, 30, 40), _c("building_far"))
	draw_rect(Rect2(445, 50, 40, 50), _c("building"))
	draw_rect(Rect2(400, 20, 90, 80), _c("wood"), false, 4.0)
	draw_line(Vector2(445, 20), Vector2(445, 100), _c("wood"), 3.0)
	# Commode.
	draw_rect(Rect2(40, 120, 120, 90), _c("wood").lightened(0.1))
	for i in 3:
		draw_rect(Rect2(48, 128 + i * 27, 104, 22), _c("wood").darkened(0.15))
		draw_circle(Vector2(100, 139 + i * 27), 3, _c("paper_dark"))
	draw_rect(Rect2(60, 104, 30, 16), _c("paper"))
	# Poêle et tuyau.
	draw_rect(Rect2(210, 130, 60, 100), _c("ink").lightened(0.1))
	draw_rect(Rect2(222, 180, 36, 24), _c("alert").darkened(0.6))
	draw_rect(Rect2(232, 0, 16, 130), _c("ink").lightened(0.15))
	# Photo de famille au mur.
	draw_rect(Rect2(300, 40, 70, 56), _c("wood"))
	draw_rect(Rect2(306, 46, 58, 44), _c("paper_dark"))
	for i in 3:
		draw_circle(Vector2(320 + i * 15, 62), 5, _c("ink").lightened(0.3))
		draw_rect(Rect2(316 + i * 15, 68, 8, 16), _c("ink").lightened(0.3))
	# Lit des parents.
	draw_rect(Rect2(420, 180, 170, 50), _c("paper"))
	draw_rect(Rect2(420, 172, 170, 12), _c("paper_dark"))
	draw_rect(Rect2(410, 160, 14, 70), _c("wood"))
	draw_rect(Rect2(586, 170, 14, 60), _c("wood"))
	draw_rect(Rect2(430, 186, 50, 18), _c("paper").lightened(0.3))
	# Lit de l'enfant, contre le mur de droite.
	draw_rect(Rect2(520, 110, 90, 50), _c("folder"))
	draw_rect(Rect2(524, 104, 82, 14), _c("paper"))
	draw_circle(Vector2(560, 96), 8, get_theme_color("skin", "IdPhoto"))
	# Cartable de Vera.
	draw_rect(Rect2(115, 220, 60, 38), _c("alert").darkened(0.35))
	draw_rect(Rect2(135, 212, 20, 10), _c("alert").darkened(0.5), false, 3.0)
	# Vera, debout près de la porte, de dos à la lumière.
	draw_rect(Rect2(300, 130, 40, 100), _c("building"))
	draw_circle(Vector2(320, 118), 14, _c("building"))


func _ellipse(center: Vector2, radius: Vector2, steps := 32) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in steps:
		var angle := TAU * i / steps
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	return points


## Calotte de cheveux : le haut de l'ellipse jusqu'à la hauteur "depth" (0 à 1).
func _ellipse_arc(center: Vector2, radius: Vector2, depth: float) -> PackedVector2Array:
	var start := asin(clampf(depth, 0.0, 1.0))
	var points := PackedVector2Array()
	for i in 25:
		var angle := PI + start + (PI - 2.0 * start) * i / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	return points
