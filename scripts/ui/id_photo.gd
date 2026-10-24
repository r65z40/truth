class_name IdPhoto
extends Control
## Photo d'identité dessinée à partir des données d'une pièce (aucune image
## importée). Clé "photo" d'un document :
## {
##   "caption": "Cliché du 12.03.1979",
##   "face": "round|long",              forme du visage
##   "hair": "short|long|curly|receding|bald",
##   "gray": true,                      cheveux gris
##   "glasses": true,
##   "facial_hair": "none|mustache|beard",
##   "mark": "none|scar|mole"           signe particulier
## }
## Deux photos qui diffèrent sur un trait se voient : c'est voulu.
## Couleurs : type de thème "IdPhoto" (paper, ink, skin, shade).

## Taille de dessin ; DISPLAY_SCALE réduit la photo à l'écran.
const PHOTO_SIZE := Vector2(132, 168)
const DISPLAY_SCALE := 0.62
const CAPTION_HEIGHT := 18

var photo: Dictionary = {}:
	set(value):
		photo = value
		queue_redraw()


func _init() -> void:
	custom_minimum_size = PHOTO_SIZE * DISPLAY_SCALE + Vector2(0, CAPTION_HEIGHT)
	size_flags_horizontal = Control.SIZE_SHRINK_END
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _color(name: String) -> Color:
	return get_theme_color(name, "IdPhoto")


func _draw() -> void:
	if photo.is_empty():
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * DISPLAY_SCALE)
	var paper := _color("paper")
	var ink := _color("ink")
	var skin := _color("skin")
	var shade := _color("shade")
	var hair_color := shade.lerp(paper, 0.45) if photo.get("gray", false) else ink
	var frame := Rect2(Vector2.ZERO, PHOTO_SIZE)
	draw_rect(frame, paper)
	draw_rect(frame.grow(-6), shade.lerp(paper, 0.7))
	var cx := PHOTO_SIZE.x / 2.0
	var long_face: bool = photo.get("face", "round") == "long"
	var head := Vector2(30, 40 if long_face else 36)
	var head_center := Vector2(cx, 70)
	# Épaules et cou.
	draw_colored_polygon(PackedVector2Array([
		Vector2(14, PHOTO_SIZE.y - 6), Vector2(28, 132), Vector2(cx - 18, 120),
		Vector2(cx + 18, 120), Vector2(PHOTO_SIZE.x - 28, 132), Vector2(PHOTO_SIZE.x - 14, PHOTO_SIZE.y - 6),
	]), shade)
	draw_rect(Rect2(cx - 11, head_center.y + head.y - 8, 22, 22), skin.darkened(0.12))
	# Cheveux longs derrière la tête.
	var hair: String = photo.get("hair", "short")
	if hair == "long":
		draw_colored_polygon(_ellipse(head_center + Vector2(0, 14), head + Vector2(8, 18)), hair_color)
	draw_colored_polygon(_ellipse(head_center, head), skin)
	match hair:
		"short", "long":
			draw_colored_polygon(_cap(head_center, head, 0.95), hair_color)
		"curly":
			for i in 9:
				var angle := PI + PI * i / 8.0
				draw_circle(head_center + Vector2(cos(angle) * head.x, sin(angle) * head.y * 0.9), 9.0, hair_color)
		"receding":
			draw_colored_polygon(_cap(head_center, head, 0.45), hair_color)
			draw_rect(Rect2(head_center.x - head.x - 2, head_center.y - 14, 6, 18), hair_color)
			draw_rect(Rect2(head_center.x + head.x - 4, head_center.y - 14, 6, 18), hair_color)
	# Yeux, nez, bouche.
	var eye_y := head_center.y - 2
	for side in [-1, 1]:
		draw_circle(Vector2(cx + side * 11, eye_y), 2.4, ink)
	draw_line(Vector2(cx, eye_y + 4), Vector2(cx - 3, eye_y + 15), shade, 1.5)
	draw_line(Vector2(cx - 3, eye_y + 15), Vector2(cx + 2, eye_y + 15), shade, 1.5)
	var facial: String = photo.get("facial_hair", "none")
	if facial == "beard":
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - head.x + 4, eye_y + 12), Vector2(cx + head.x - 4, eye_y + 12),
			Vector2(cx + 14, head_center.y + head.y + 4), Vector2(cx - 14, head_center.y + head.y + 4),
		]), hair_color)
	if facial == "mustache" or facial == "beard":
		draw_rect(Rect2(cx - 10, eye_y + 18, 20, 4), hair_color)
	if facial != "beard":
		draw_line(Vector2(cx - 7, eye_y + 25), Vector2(cx + 7, eye_y + 25), ink, 1.5)
	if photo.get("glasses", false):
		for side in [-1, 1]:
			draw_arc(Vector2(cx + side * 11, eye_y), 7.5, 0, TAU, 20, ink, 1.6)
		draw_line(Vector2(cx - 3.5, eye_y), Vector2(cx + 3.5, eye_y), ink, 1.6)
	match photo.get("mark", "none"):
		"scar":
			draw_line(Vector2(cx + 15, eye_y + 6), Vector2(cx + 22, eye_y + 18), ink.lerp(skin, 0.3), 2.0)
		"mole":
			draw_circle(Vector2(cx - 14, eye_y + 16), 2.2, ink)
	# Grain du tirage.
	for i in 40:
		var p := Vector2(fmod(i * 37.0, PHOTO_SIZE.x - 12) + 6, fmod(i * 53.0, PHOTO_SIZE.y - 12) + 6)
		draw_rect(Rect2(p, Vector2.ONE), paper.lerp(ink, 0.25))
	draw_rect(frame, ink, false, 1.0)
	draw_set_transform(Vector2.ZERO)
	var font := get_theme_default_font()
	# La légende déborde de la photo de part et d'autre, centrée.
	var width := PHOTO_SIZE.x * DISPLAY_SCALE
	var caption_width := width + 60.0
	draw_string(font, Vector2((width - caption_width) / 2.0, PHOTO_SIZE.y * DISPLAY_SCALE + 14), str(photo.get("caption", "")),
			HORIZONTAL_ALIGNMENT_CENTER, caption_width, 11, shade)


func _ellipse(center: Vector2, radius: Vector2, from := 0.0, to := TAU, steps := 32) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in steps + 1:
		var angle := from + (to - from) * i / steps
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	return points


## Calotte de cheveux : haut de l'ellipse, couvrant une part "coverage" du front.
func _cap(center: Vector2, radius: Vector2, coverage: float) -> PackedVector2Array:
	var points := _ellipse(center, radius + Vector2(3, 4), PI, TAU, 24)
	var base_y := center.y - radius.y * (1.0 - coverage) * 0.9
	points.append(Vector2(center.x + radius.x, base_y))
	points.append(Vector2(center.x - radius.x, base_y))
	return points
