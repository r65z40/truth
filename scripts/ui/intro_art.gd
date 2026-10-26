class_name IntroArt
extends Control
## Illustrations de l'introduction, dessinées en code (aucune image importée).
## scene : "city" (Velmira de nuit), "badge" (carte d'inspecteur),
## "dossier" (pièces confrontées), "signature" (le tampon et ses conséquences).
## Dessin dans un repère de CANVAS, mis à l'échelle de la taille du contrôle.
## Couleurs : type de thème "IntroArt".

const CANVAS := Vector2(640, 300)

var scene := "city":
	set(value):
		scene = value
		queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(320, 150)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _c(name: String) -> Color:
	return get_theme_color(name, "IntroArt")


func _draw() -> void:
	var scale_factor := minf(size.x / CANVAS.x, size.y / CANVAS.y)
	var offset := (size - CANVAS * scale_factor) / 2.0
	draw_set_transform(offset, 0.0, Vector2.ONE * scale_factor)
	match scene:
		"city":
			_draw_city()
		"badge":
			_draw_badge()
		"dossier":
			_draw_dossier()
		"signature":
			_draw_signature()
		"clock":
			_draw_clock()
	draw_set_transform(Vector2.ZERO)


## Velmira la nuit : immeubles, tour du ministère et son horloge, projecteur.
func _draw_city() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS), _c("sky"))
	draw_rect(Rect2(0, 200, CANVAS.x, 100), _c("sky_low"))
	# Faisceau du projecteur.
	draw_colored_polygon(PackedVector2Array([Vector2(330, 70), Vector2(90, 0), Vector2(150, 0)]),
			Color(_c("window"), 0.08))
	# Immeubles lointains.
	var far := [[0, 170, 70], [60, 150, 60], [115, 185, 80], [420, 160, 70], [480, 140, 60], [535, 175, 105]]
	for b in far:
		draw_rect(Rect2(b[0], b[1], b[2], CANVAS.y - b[1]), _c("building_far"))
	# Immeubles proches, fenêtres allumées selon un motif fixe.
	var near := [[20, 210, 90], [120, 190, 70], [400, 200, 80], [490, 220, 120]]
	for i in near.size():
		var b: Array = near[i]
		draw_rect(Rect2(b[0], b[1], b[2], CANVAS.y - b[1]), _c("building"))
		for row in range(int(b[1]) + 12, int(CANVAS.y) - 10, 18):
			for col in range(int(b[0]) + 10, int(b[0]) + int(b[2]) - 10, 16):
				if (row * 7 + col * 3 + i * 11) % 5 == 0:
					draw_rect(Rect2(col, row, 7, 9), _c("window"))
	# Tour du ministère.
	draw_rect(Rect2(270, 90, 120, 210), _c("building"))
	draw_rect(Rect2(295, 50, 70, 40), _c("building"))
	draw_colored_polygon(PackedVector2Array([Vector2(295, 50), Vector2(330, 18), Vector2(365, 50)]), _c("building"))
	for row in range(110, 290, 22):
		for col in range(282, 380, 20):
			draw_rect(Rect2(col, row, 8, 12), _c("window") if (row + col) % 3 == 0 else _c("building_far"))
	# Horloge sans aiguille des minutes : 22h.
	draw_circle(Vector2(330, 70), 15, _c("paper"))
	draw_arc(Vector2(330, 70), 15, 0, TAU, 32, _c("ink"), 2.0)
	draw_line(Vector2(330, 70), Vector2(330, 59), _c("ink"), 2.0)
	draw_line(Vector2(330, 70), Vector2(323, 66), _c("ink"), 2.0)
	# Bannière rouge.
	draw_rect(Rect2(318, 100, 24, 60), _c("alert"))
	draw_circle(Vector2(330, 120), 6, _c("paper"))


## Carte d'inspecteur posée sur un bureau.
func _draw_badge() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS), _c("wood"))
	for y in range(0, int(CANVAS.y), 14):
		draw_line(Vector2(0, y), Vector2(CANVAS.x, y + 6), Color(_c("ink"), 0.25), 1.0)
	var card := Rect2(170, 50, 300, 190)
	draw_rect(Rect2(card.position + Vector2(6, 8), card.size), Color(0, 0, 0, 0.35))
	draw_rect(card, _c("paper"))
	draw_rect(Rect2(card.position, Vector2(card.size.x, 34)), _c("alert"))
	# Photo : silhouette.
	var photo := Rect2(190, 100, 80, 104)
	draw_rect(photo, _c("paper_dark"))
	draw_circle(Vector2(230, 138), 20, _c("ink").lightened(0.25))
	draw_colored_polygon(PackedVector2Array([Vector2(196, 204), Vector2(206, 168), Vector2(254, 168), Vector2(264, 204)]),
			_c("ink").lightened(0.25))
	# Lignes de texte et matricule.
	for i in 5:
		draw_rect(Rect2(290, 108 + i * 20, 150 - (i % 2) * 40, 6), Color(_c("ink"), 0.6))
	# Tampon rond.
	draw_arc(Vector2(420, 200), 26, 0, TAU, 40, Color(_c("alert"), 0.8), 3.0)
	draw_arc(Vector2(420, 200), 18, 0, TAU, 40, Color(_c("alert"), 0.6), 1.5)
	# Œil du ministère sur le bandeau.
	draw_arc(Vector2(200, 67), 10, PI * 1.1, PI * 1.9, 12, _c("paper"), 2.0)
	draw_arc(Vector2(200, 61), 10, PI * 0.1, PI * 0.9, 12, _c("paper"), 2.0)
	draw_circle(Vector2(200, 64), 3, _c("paper"))


## Deux pièces côte à côte, deux lignes reliées : la contradiction.
func _draw_dossier() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS), _c("wood"))
	draw_rect(Rect2(90, 40, 460, 230), _c("folder"))
	var left := Rect2(120, 30, 190, 240)
	var right := Rect2(330, 30, 190, 240)
	for page in [left, right]:
		draw_rect(Rect2(page.position + Vector2(4, 5), page.size), Color(0, 0, 0, 0.3))
		draw_rect(page, _c("paper"))
		draw_rect(Rect2(page.position + Vector2(16, 18), Vector2(110, 8)), _c("ink"))
		for i in 9:
			draw_rect(Rect2(page.position + Vector2(16, 44 + i * 20), Vector2(150 - (i * 37) % 50, 5)),
					Color(_c("ink"), 0.45))
	# Lignes surlignées et reliées.
	var a := Rect2(left.position + Vector2(12, 99), Vector2(150, 12))
	var b := Rect2(right.position + Vector2(12, 159), Vector2(140, 12))
	draw_rect(a, Color(_c("accent"), 0.35))
	draw_rect(b, Color(_c("accent"), 0.35))
	draw_line(a.position + Vector2(a.size.x, 6), b.position + Vector2(0, 6), _c("alert"), 3.0)
	draw_circle(a.position + Vector2(a.size.x, 6), 5, _c("alert"))
	draw_circle(b.position + Vector2(0, 6), 5, _c("alert"))
	# « ≠ » au milieu.
	draw_circle(Vector2(320, 140), 16, _c("alert"))
	draw_line(Vector2(311, 135), Vector2(329, 135), _c("paper"), 3.0)
	draw_line(Vector2(311, 145), Vector2(329, 145), _c("paper"), 3.0)
	draw_line(Vector2(326, 128), Vector2(314, 152), _c("paper"), 3.0)


## Lampe de bureau, rapport signé, tampon : la décision.
func _draw_signature() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS), _c("sky"))
	draw_colored_polygon(PackedVector2Array([Vector2(170, 60), Vector2(40, 300), Vector2(470, 300), Vector2(260, 60)]),
			Color(_c("window"), 0.12))
	draw_rect(Rect2(0, 230, CANVAS.x, 70), _c("wood"))
	# Lampe.
	draw_colored_polygon(PackedVector2Array([Vector2(160, 62), Vector2(190, 20), Vector2(240, 20), Vector2(270, 62)]), _c("accent").darkened(0.5))
	draw_line(Vector2(215, 20), Vector2(250, -10), _c("building"), 6.0)
	# Rapport.
	var page := Rect2(180, 150, 220, 120)
	draw_colored_polygon(PackedVector2Array([page.position, page.position + Vector2(page.size.x, -10),
			page.end, page.position + Vector2(-8, page.size.y)]), _c("paper"))
	for i in 4:
		draw_rect(Rect2(200, 168 + i * 16, 150 - i * 20, 5), Color(_c("ink"), 0.5))
	# Signature.
	var points := PackedVector2Array()
	for i in 30:
		points.append(Vector2(220 + i * 4, 248 + sin(i * 0.9) * 6 - i * 0.2))
	draw_polyline(points, _c("ink"), 2.0)
	# Tampon rouge.
	draw_rect(Rect2(300, 200, 84, 34), Color(_c("alert"), 0.15))
	draw_rect(Rect2(300, 200, 84, 34), Color(_c("alert"), 0.8), false, 3.0)
	draw_line(Vector2(308, 217), Vector2(376, 217), Color(_c("alert"), 0.8), 4.0)
	# Tampon encreur.
	draw_rect(Rect2(470, 190, 60, 50), _c("building"))
	draw_rect(Rect2(485, 150, 30, 40), _c("ink"))
	# Silhouettes à la fenêtre : ceux qui attendent la décision.
	for i in 3:
		var x := 520 + i * 32
		draw_circle(Vector2(x, 80), 10, _c("building_far").lightened(0.15))
		draw_rect(Rect2(x - 12, 92, 24, 40), _c("building_far").lightened(0.15))


## Horloge de service : une journée de 8 heures, l'aiguille proche du soir.
func _draw_clock() -> void:
	draw_rect(Rect2(Vector2.ZERO, CANVAS), _c("sky"))
	draw_rect(Rect2(0, 236, CANVAS.x, 64), _c("wood"))
	var center := Vector2(320, 140)
	var radius := 96.0
	# Cadran.
	draw_circle(center + Vector2(5, 7), radius, Color(0, 0, 0, 0.35))
	draw_circle(center, radius, _c("paper"))
	draw_arc(center, radius, 0, TAU, 48, _c("ink"), 3.0)
	# Secteur des heures de bureau (08h -> 16h) mis en évidence.
	draw_arc(center, radius - 10, -PI / 2.0, -PI / 2.0 + TAU * (8.0 / 12.0), 32, _c("accent"), 6.0)
	# Graduations.
	for h in 12:
		var a := -PI / 2.0 + TAU * h / 12.0
		var outer := center + Vector2(cos(a), sin(a)) * (radius - 4)
		var inner := center + Vector2(cos(a), sin(a)) * (radius - (16 if h % 3 == 0 else 10))
		draw_line(inner, outer, _c("ink"), 3.0 if h % 3 == 0 else 1.5)
	# Aiguilles : fin de journée approchant.
	var hour_angle := -PI / 2.0 + TAU * (7.3 / 12.0)
	var minute_angle := -PI / 2.0 + TAU * (20.0 / 60.0)
	draw_line(center, center + Vector2(cos(hour_angle), sin(hour_angle)) * (radius * 0.52), _c("ink"), 5.0)
	draw_line(center, center + Vector2(cos(minute_angle), sin(minute_angle)) * (radius * 0.78), _c("alert"), 3.0)
	draw_circle(center, 6, _c("ink"))
	# Feuillet « 08h00 -> 16h00 ».
	draw_rect(Rect2(248, 250, 144, 34), _c("paper"))
	draw_rect(Rect2(248, 250, 144, 34), _c("ink"), false, 2.0)
	for i in 3:
		draw_rect(Rect2(262, 260 + i * 7, 116 - i * 24, 3), Color(_c("ink"), 0.5))
