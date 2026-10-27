class_name FieldArt
extends Control
## Décors des scènes de terrain, dessinés en code (aucune image importée), vus
## à la première personne. Repère de dessin CANVAS, mis à l'échelle du contrôle ;
## to_local_rect() convertit une zone du repère (les "spot" des perquisitions)
## en coordonnées du contrôle.
## scene : "interrogation" (le sujet de l'autre côté de la table, d'après subject)
## ou un lieu : "sedlar_flat" (appartement des SEDLAR), "bakery" (boulangerie
## n° 12), "benes_flat" (appartement 40 du quai des Tanneurs), "clock_shop" et
## "clock_back" (atelier d'ADLER et son arrière-boutique).
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
## Image de fond facultative (res://...). Si le fichier existe, elle remplace le
## décor dessiné ; sinon on retombe sur le dessin, ce qui permet de livrer les
## images une par une sans jamais casser une scène.
var image_path := "":
	set(value):
		image_path = value
		_texture = load(value) if value != "" and ResourceLoader.exists(value) else null
		queue_redraw()
var _texture: Texture2D = null
## Mode vidéo : la scène joue une vidéo de fond (gérée par FieldScreen, posée
## derrière). FieldArt ne dessine alors rien (fond transparent) et sert seulement
## de support aux zones cliquables, qui couvrent tout le cadre 16:9.
var video_mode := false:
	set(value):
		video_mode = value
		queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(320, 150)
	mouse_filter = Control.MOUSE_FILTER_PASS
	resized.connect(queue_redraw)


func get_canvas_scale() -> float:
	return minf(size.x / CANVAS.x, size.y / CANVAS.y)


func _offset() -> Vector2:
	return (size - CANVAS * get_canvas_scale()) / 2.0


## Rectangle où l'image de fond est réellement affichée : ajustée pour tenir en
## entier sans être déformée ni rognée (« contain »). Sans image, c'est le repère
## de dessin CANVAS mis à l'échelle. Les zones cliquables exprimées en fractions
## s'y réfèrent, donc elles tombent toujours au même endroit de l'image.
func image_rect() -> Rect2:
	if video_mode:
		return Rect2(Vector2.ZERO, size)
	if _texture == null:
		return Rect2(_offset(), CANVAS * get_canvas_scale())
	var tex := _texture.get_size()
	var fit := minf(size.x / tex.x, size.y / tex.y)
	var draw_size := tex * fit
	return Rect2((size - draw_size) / 2.0, draw_size)


## Une zone est-elle donnée en fractions (toutes ses valeurs entre 0 et 1) ?
static func is_fractional(area: Array) -> bool:
	return area.size() == 4 and area.all(func(v: float) -> bool: return absf(v) <= 1.0)


## Zone [x, y, w, h] en coordonnées du contrôle. Deux conventions :
## - fractions de l'image affichée (valeurs entre 0 et 1) : recommandé pour les
##   scènes avec image, les zones restent calées sur l'image à toute taille ;
## - pixels du repère de dessin 640 x 300 (hérité) : pour les décors dessinés.
func to_local_rect(area: Array) -> Rect2:
	if is_fractional(area):
		var base := image_rect()
		return Rect2(base.position + Vector2(area[0], area[1]) * base.size,
				Vector2(area[2], area[3]) * base.size)
	var factor := get_canvas_scale()
	return Rect2(_offset() + Vector2(area[0], area[1]) * factor, Vector2(area[2], area[3]) * factor)


func _c(name: String) -> Color:
	return get_theme_color(name, "IntroArt")


## Une image de fond est-elle chargée (fichier présent) ?
func has_image() -> bool:
	return _texture != null


func _draw() -> void:
	# En mode vidéo, FieldArt est transparent : la vidéo (posée derrière par
	# FieldScreen) occupe le cadre, et seules les zones cliquables restent dessus.
	if video_mode:
		return
	# Image de fond si elle existe : fond sombre pour les éventuelles marges, puis
	# l'image dans le repère de dessin, alignée sur les zones cliquables (spots).
	if _texture != null:
		draw_rect(Rect2(Vector2.ZERO, size), _c("paper_dark").darkened(0.6))
		# L'image est affichée en entier, sans déformation ni rognage, pour que les
		# zones cliquables (en fractions) tombent exactement sur ses objets.
		draw_texture_rect(_texture, image_rect(), false)
		return
	# Le décor déborde du repère : mur en haut, sol en bas, sans bandes noires.
	var horizon := _offset().y + 230.0 * get_canvas_scale()
	match scene:
		"interrogation":
			draw_rect(Rect2(Vector2.ZERO, size), _c("sky"))
			draw_rect(Rect2(0, 0, size.x, _offset().y + 200.0 * get_canvas_scale()), _c("building_far"))
		"sedlar_flat", "benes_flat":
			draw_rect(Rect2(0, 0, size.x, horizon), _c("paper_dark").darkened(0.45))
			draw_rect(Rect2(0, horizon, size.x, size.y - horizon), _c("wood"))
		"bakery":
			draw_rect(Rect2(0, 0, size.x, horizon), _c("paper").darkened(0.55))
			draw_rect(Rect2(0, horizon, size.x, size.y - horizon), _c("ink").lightened(0.12))
		"clock_shop", "clock_back":
			draw_rect(Rect2(0, 0, size.x, horizon), _c("paper_dark").darkened(0.55))
			draw_rect(Rect2(0, horizon, size.x, size.y - horizon), _c("wood").darkened(0.25))
	draw_set_transform(_offset(), 0.0, Vector2.ONE * get_canvas_scale())
	match scene:
		"interrogation":
			_draw_interrogation()
		"sedlar_flat":
			_draw_sedlar_flat()
		"bakery":
			_draw_bakery()
		"benes_flat":
			_draw_benes_flat()
		"clock_shop":
			_draw_clock_shop()
		"clock_back":
			_draw_clock_back()
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


## Boulangerie d'État n° 12 : étagères presque vides, comptoir, caisse, la gérante,
## la porte de l'arrière-boutique à gauche et la file d'attente derrière la vitrine.
func _draw_bakery() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS), _c("paper").darkened(0.55))
	draw_rect(Rect2(0, 230, CANVAS.x, 70), _c("ink").lightened(0.12))
	for x in range(0, int(CANVAS.x), 32):
		draw_line(Vector2(x, 230), Vector2(x, 300), Color(_c("ink"), 0.5), 1.0)
	# Porte de l'arrière-boutique, entrouverte sur la lueur du four.
	draw_rect(Rect2(20, 50, 70, 180), _c("wood").darkened(0.2))
	draw_rect(Rect2(26, 56, 30, 168), Color(_c("window"), 0.25))
	# Étagères à pain : trois miches pour tout le quartier.
	for i in 3:
		var y := 40 + i * 40
		draw_rect(Rect2(110, y + 26, 210, 6), _c("wood"))
	for loaf in [Vector2(140, 58), Vector2(260, 98), Vector2(180, 138)]:
		draw_colored_polygon(_ellipse(loaf, Vector2(22, 10)), _c("folder"))
	# Affiche des rations et cahier de visite accroché à son clou.
	draw_rect(Rect2(350, 50, 45, 60), _c("paper"))
	for i in 5:
		draw_rect(Rect2(356, 60 + i * 9, 32, 3), Color(_c("ink"), 0.5))
	# Photo du fils et sa lettre.
	draw_rect(Rect2(405, 60, 30, 38), _c("wood"))
	draw_rect(Rect2(409, 64, 22, 30), _c("paper_dark"))
	draw_circle(Vector2(420, 74), 5, _c("ink").lightened(0.3))
	draw_rect(Rect2(428, 84, 22, 16), _c("paper"))
	# Vitrine sur la rue : la file d'attente.
	draw_rect(Rect2(470, 30, 160, 150), _c("sky_low"))
	for i in 6:
		var x := 490 + i * 24
		draw_circle(Vector2(x, 100 + (i % 2) * 6), 9, _c("building"))
		draw_rect(Rect2(x - 10, 110 + (i % 2) * 6, 20, 70), _c("building"))
	draw_rect(Rect2(470, 30, 160, 150), _c("wood"), false, 5.0)
	draw_string(get_theme_default_font(), Vector2(492, 52), UiText.of("PAIN  //  N° 12"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
			Color(_c("paper"), 0.6))
	# La gérante derrière le comptoir.
	draw_rect(Rect2(205, 110, 50, 70), _c("paper"))
	draw_circle(Vector2(230, 96), 15, get_theme_color("skin", "IdPhoto"))
	draw_colored_polygon(_ellipse_arc(Vector2(230, 94), Vector2(17, 17), 0.2), _c("paper_dark").darkened(0.3))
	# Comptoir, caisse aux tickets, sacs sous le comptoir.
	draw_rect(Rect2(90, 165, 370, 65), _c("wood"))
	draw_rect(Rect2(90, 165, 370, 6), _c("wood").lightened(0.2))
	draw_rect(Rect2(305, 138, 60, 28), _c("cloth"))
	draw_rect(Rect2(312, 132, 46, 8), _c("paper"))
	draw_rect(Rect2(135, 195, 110, 30), _c("wood").darkened(0.35))
	draw_rect(Rect2(145, 198, 36, 24), _c("paper_dark"))


## Appartement 40, quai des Tanneurs : étagère vidée, bureau de correcteur,
## boîte à photos, armoire, et une latte de plancher qui bouge.
func _draw_benes_flat() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS), _c("paper_dark").darkened(0.5))
	draw_rect(Rect2(0, 230, CANVAS.x, 70), _c("wood"))
	for y in [245, 262, 280]:
		draw_line(Vector2(0, y), Vector2(CANVAS.x, y), Color(_c("ink"), 0.35), 1.0)
	draw_rect(Rect2(275, 252, 120, 10), _c("wood").darkened(0.3))
	# Étagère vide, les traces de poussière des livres enlevés.
	draw_rect(Rect2(40, 40, 150, 160), _c("wood").darkened(0.15), false, 6.0)
	for i in 4:
		var y := 75 + i * 40
		draw_rect(Rect2(40, y, 150, 5), _c("wood"))
		for j in 9:
			draw_rect(Rect2(48 + j * 15, y - 30, 11, 30), Color(_c("paper"), 0.07))
	draw_rect(Rect2(172, 125, 10, 30), _c("alert").darkened(0.4))
	# Fenêtre sur le canal.
	draw_rect(Rect2(400, 30, 90, 80), _c("sky_low"))
	draw_rect(Rect2(400, 30, 90, 80), _c("wood"), false, 4.0)
	# Bureau du correcteur : lampe, courrier, épreuves.
	draw_rect(Rect2(200, 160, 190, 10), _c("wood").lightened(0.1))
	draw_rect(Rect2(210, 170, 10, 60), _c("wood"))
	draw_rect(Rect2(370, 170, 10, 60), _c("wood"))
	draw_rect(Rect2(210, 140, 50, 18), _c("paper_dark"))
	draw_rect(Rect2(290, 136, 80, 22), _c("paper"))
	for i in 3:
		draw_line(Vector2(296, 142 + i * 5), Vector2(360, 142 + i * 5), Color(_c("accent"), 0.6), 1.0)
	draw_line(Vector2(270, 160), Vector2(270, 110), _c("ink"), 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(258, 112), Vector2(282, 112), Vector2(276, 100), Vector2(264, 100)]),
			_c("cloth"))
	# Chaise et boîte à photos.
	draw_rect(Rect2(420, 225, 60, 8), _c("wood"))
	draw_rect(Rect2(420, 200, 60, 28), _c("folder"))
	# Armoire, Irena BENES à côté.
	draw_rect(Rect2(520, 40, 100, 190), _c("wood").lightened(0.05))
	draw_line(Vector2(570, 44), Vector2(570, 226), _c("ink"), 2.0)
	draw_circle(Vector2(562, 135), 3, _c("paper_dark"))
	draw_circle(Vector2(578, 135), 3, _c("paper_dark"))
	draw_rect(Rect2(486, 120, 30, 110), _c("cloth").darkened(0.3))
	draw_circle(Vector2(501, 108), 12, get_theme_color("skin", "IdPhoto").darkened(0.2))


## Atelier d'ADLER : le mur des pendules arrêtées, l'établi et sa loupe, le
## carton du poste de radio, la porte de l'arrière-boutique.
func _draw_clock_shop() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS), _c("paper_dark").darkened(0.55))
	draw_rect(Rect2(0, 230, CANVAS.x, 70), _c("wood").darkened(0.25))
	for x in range(40, int(CANVAS.x), 40):
		draw_line(Vector2(x, 230), Vector2(x - 24, 300), Color(_c("ink"), 0.3), 1.0)
	# Le mur des pendules : toutes sur 05 h 20, sauf la petite claire, sur 06 h 05.
	var clocks := [Vector2(70, 50), Vector2(130, 42), Vector2(195, 55), Vector2(255, 45),
			Vector2(95, 105), Vector2(160, 100), Vector2(225, 108), Vector2(280, 98)]
	for i in clocks.size():
		var center: Vector2 = clocks[i]
		var odd := i == 5
		draw_circle(center, 20.0, _c("wood").lightened(0.35) if odd else _c("wood"))
		draw_circle(center, 16.0, _c("paper"))
		var hours := 6.0 if odd else 5.0
		var minutes := 5.0 if odd else 20.0
		_draw_hand(center, (hours + minutes / 60.0) / 12.0, 9.0)
		_draw_hand(center, minutes / 60.0, 13.0)
	# Étagère basse et carton du poste de radio.
	draw_rect(Rect2(40, 210, 120, 6), _c("wood"))
	draw_rect(Rect2(52, 168, 80, 42), _c("folder"))
	draw_rect(Rect2(60, 176, 40, 10), _c("paper"))
	# L'établi : plateau, loupe articulée, boîte de fiches, pièces éparses.
	draw_rect(Rect2(320, 168, 240, 12), _c("wood").lightened(0.1))
	draw_rect(Rect2(330, 180, 12, 50), _c("wood"))
	draw_rect(Rect2(538, 180, 12, 50), _c("wood"))
	draw_rect(Rect2(470, 146, 60, 22), _c("paper_dark"))
	for i in 4:
		draw_rect(Rect2(476 + i * 13, 140, 9, 10), _c("paper"))
	draw_line(Vector2(380, 168), Vector2(400, 120), _c("ink"), 3.0)
	draw_line(Vector2(400, 120), Vector2(430, 140), _c("ink"), 3.0)
	draw_circle(Vector2(436, 146), 11.0, Color(_c("window"), 0.4))
	for i in 6:
		draw_circle(Vector2(350 + i * 17, 162 - (i % 2) * 3), 2.5, _c("folder"))
	# Porte de l'arrière-boutique, entrouverte.
	draw_rect(Rect2(580, 40, 50, 190), _c("wood").darkened(0.2))
	draw_rect(Rect2(586, 46, 18, 178), Color(_c("ink"), 0.6))
	draw_circle(Vector2(618, 140), 3.0, _c("paper_dark"))


## Arrière-boutique : la pendule du père sous un drap, le lit de camp, l'armoire.
func _draw_clock_back() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS), _c("paper_dark").darkened(0.6))
	draw_rect(Rect2(0, 230, CANVAS.x, 70), _c("wood").darkened(0.3))
	# Lucarne grise.
	draw_rect(Rect2(260, 30, 80, 40), _c("sky_low"))
	draw_rect(Rect2(260, 30, 80, 40), _c("wood"), false, 3.0)
	# Étagère et pendule de voyage sous un drap.
	draw_rect(Rect2(50, 150, 140, 6), _c("wood"))
	draw_colored_polygon(PackedVector2Array([Vector2(80, 150), Vector2(90, 80), Vector2(150, 76),
			Vector2(165, 150)]), _c("paper").darkened(0.15))
	draw_line(Vector2(95, 92), Vector2(150, 140), Color(_c("ink"), 0.25), 1.0)
	# Lit de camp, couverture pliée, oreiller.
	draw_rect(Rect2(220, 200, 200, 22), _c("cloth").darkened(0.2))
	draw_rect(Rect2(226, 222, 6, 18), _c("ink"))
	draw_rect(Rect2(408, 222, 6, 18), _c("ink"))
	draw_rect(Rect2(230, 186, 50, 16), _c("paper"))
	# Armoire, la porte entrouverte sur un fond sombre.
	draw_rect(Rect2(460, 40, 120, 190), _c("wood").lightened(0.05))
	draw_rect(Rect2(470, 50, 46, 170), Color(_c("ink"), 0.7))
	draw_line(Vector2(520, 44), Vector2(520, 226), _c("ink"), 2.0)
	draw_circle(Vector2(530, 135), 3.0, _c("paper_dark"))
	# Porte vers la boutique.
	draw_rect(Rect2(10, 40, 40, 190), _c("wood").darkened(0.2))
	draw_circle(Vector2(42, 140), 3.0, _c("paper_dark"))


## Aiguille de pendule : turn est la fraction de tour (0 = midi), length en pixels.
func _draw_hand(center: Vector2, turn: float, length: float) -> void:
	var angle := TAU * turn - PI / 2.0
	draw_line(center, center + Vector2(cos(angle), sin(angle)) * length, _c("ink"), 2.0)


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
