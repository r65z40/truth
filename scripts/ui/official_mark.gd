class_name OfficialMark
extends Control
## Élément officiel dessiné en code (aucune image importée) : un cachet/tampon ou
## une signature. Sert à comparer une pièce authentique et une pièce suspecte à
## l'œil — c'est le cœur de l'authentification (« traquer les faussaires »). Deux
## marques qui diffèrent sur un détail se voient : c'est voulu.
##
## mark = {
##   "kind": "stamp" | "signature",
##   # cachet :
##   "emblem": "star|wheat|cross|eagle|none",
##   "star_points": 5,              nombre de branches de l'étoile (tell : 4)
##   "title": "BUREAU DES CULTES",
##   "subtitle": "DISTRICT 2",
##   "serial": "86/212",
##   "ink": "red|black|violet",
##   "wear": 0.5,                   usure de l'encre (0 = net, 1 = très marqué)
##   "tilt": 0.08,                  inclinaison du tampon
##   # signature :
##   "seed": 7,                     graphie déterministe
##   "slant": 0.25,
##   "label": "Dr. HAVEL"           nom sous la signature
## }

const INKS := {
	"red": Color(0.60, 0.13, 0.11),
	"black": Color(0.12, 0.12, 0.14),
	"violet": Color(0.34, 0.16, 0.42),
	"blue": Color(0.16, 0.22, 0.45),
}

var mark: Dictionary = {}:
	set(value):
		mark = value
		_resize()
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resize()


func _resize() -> void:
	custom_minimum_size = Vector2(150, 150) if mark.get("kind", "stamp") == "stamp" else Vector2(200, 84)


func _ink() -> Color:
	return INKS.get(mark.get("ink", "black"), INKS.black)


func _draw() -> void:
	if mark.is_empty():
		return
	if mark.get("kind", "stamp") == "signature":
		_draw_signature()
	else:
		_draw_stamp()


# --- Cachet / tampon ---------------------------------------------------------

func _draw_stamp() -> void:
	var ink := _ink()
	var center := Vector2(75, 72)
	var radius := 62.0
	var tilt: float = mark.get("tilt", 0.06)
	draw_set_transform(center, tilt, Vector2.ONE)
	# Deux anneaux concentriques, à l'encre usée.
	_draw_ring(Vector2.ZERO, radius, ink, 3.0)
	_draw_ring(Vector2.ZERO, radius - 9.0, ink, 1.5)
	# Emblème au centre.
	_draw_emblem(Vector2(0, -2), ink)
	# Texte : titre en haut, sous-titre en bas (droits, pour rester lisibles).
	var font := get_theme_default_font()
	_draw_centered(font, mark.get("title", ""), Vector2(0, -radius + 20), 11, ink)
	_draw_centered(font, mark.get("subtitle", ""), Vector2(0, radius - 14), 9, ink)
	var tag: String = mark.get("serial", "")
	if mark.get("date", "") != "":
		tag = (tag + "  " + str(mark.date)).strip_edges()
	_draw_centered(font, tag, Vector2(0, 26), 9, ink)
	draw_set_transform(Vector2.ZERO)


func _draw_ring(center: Vector2, radius: float, ink: Color, width: float) -> void:
	# Anneau tracé par segments, certains omis pour l'effet d'encre usée (déterministe).
	var wear: float = mark.get("wear", 0.4)
	var steps := 48
	for i in steps:
		if _noise(i) < wear * 0.35:
			continue
		var a0 := TAU * i / steps
		var a1 := TAU * (i + 1) / steps
		draw_line(center + Vector2(cos(a0), sin(a0)) * radius,
				center + Vector2(cos(a1), sin(a1)) * radius, ink, width)


func _draw_emblem(pos: Vector2, ink: Color) -> void:
	match mark.get("emblem", "star"):
		"star":
			draw_colored_polygon(_star(pos, 16.0, 7.0, int(mark.get("star_points", 5))), ink)
		"wheat":
			for side in [-1.0, 1.0]:
				var stalk := PackedVector2Array()
				for i in 9:
					stalk.append(pos + Vector2(side * i * 1.1, 14 - i * 3.4))
				draw_polyline(stalk, ink, 2.0)
				for i in range(1, 8):
					var p := pos + Vector2(side * i * 1.1, 14 - i * 3.4)
					draw_line(p, p + Vector2(side * 5, -3), ink, 1.5)
		"cross":
			draw_line(pos + Vector2(0, -14), pos + Vector2(0, 14), ink, 3.0)
			draw_line(pos + Vector2(-9, -4), pos + Vector2(9, -4), ink, 3.0)
		"eagle":
			# Oiseau stylisé : deux ailes et un corps.
			draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -8), pos + Vector2(-16, 2),
					pos + Vector2(-5, 0), pos + Vector2(0, 10), pos + Vector2(5, 0),
					pos + Vector2(16, 2)]), ink)
		"none":
			pass


## Étoile à N branches, centrée.
func _star(center: Vector2, outer: float, inner: float, points: int) -> PackedVector2Array:
	var poly := PackedVector2Array()
	var count := maxi(points, 3) * 2
	for i in count:
		var r := outer if i % 2 == 0 else inner
		var a := -PI / 2.0 + TAU * i / count
		poly.append(center + Vector2(cos(a), sin(a)) * r)
	return poly


# --- Signature ---------------------------------------------------------------

func _draw_signature() -> void:
	var ink := _ink()
	var seed: int = int(mark.get("seed", 1))
	var slant: float = mark.get("slant", 0.2)
	var baseline := 46.0
	var points := PackedVector2Array()
	var x := 18.0
	var phase := seed * 0.7
	for i in 48:
		var t := i / 47.0
		var y := baseline - sin(phase + t * (6.0 + seed % 4)) * 16.0 * (1.0 - t * 0.2) - t * 20.0 * slant
		y -= sin(phase * 1.7 + t * 13.0) * 4.0
		points.append(Vector2(x, y))
		x += 3.6
	draw_polyline(points, ink, 2.2)
	# Paraphe final.
	var endp: Vector2 = points[points.size() - 1]
	draw_line(endp, endp + Vector2(10, 8), ink, 2.2)
	draw_line(endp + Vector2(10, 8), endp + Vector2(-6, 10), ink, 1.6)
	# Nom imprimé sous la signature.
	var font := get_theme_default_font()
	var label: String = mark.get("label", "")
	if label != "":
		draw_string(font, Vector2(18, 70), label, HORIZONTAL_ALIGNMENT_LEFT, 170, 11,
				ink.lerp(Color(0.5, 0.5, 0.5), 0.3))


# --- Utilitaires -------------------------------------------------------------

func _draw_centered(font: Font, text: String, pos: Vector2, size: int, color: Color) -> void:
	if text == "":
		return
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, pos + Vector2(-width / 2.0, size / 2.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


## Bruit déterministe dans [0,1) à partir d'un index et de la graine du tampon.
func _noise(i: int) -> float:
	var v := sin(float(int(mark.get("seed", 3)) + i) * 12.9898) * 43758.5453
	return v - floor(v)
