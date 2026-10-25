@tool
class_name BevelStyleBox
extends StyleBox
## Cadre en relief des fenêtres et boutons du bureau : une face unie et deux
## liserés (clair en haut à gauche, sombre en bas à droite), inversés quand
## le relief est « enfoncé ». Utilisé par le thème, jamais directement en scène.

@export var face := Color(0.6, 0.6, 0.6):
	set(value):
		face = value
		emit_changed()
@export var light := Color(0.85, 0.85, 0.85):
	set(value):
		light = value
		emit_changed()
@export var shadow := Color(0.35, 0.35, 0.35):
	set(value):
		shadow = value
		emit_changed()
@export var dark := Color(0.1, 0.1, 0.1):
	set(value):
		dark = value
		emit_changed()
## Vrai : relief creusé (bouton enfoncé, zone de saisie).
@export var sunken := false:
	set(value):
		sunken = value
		emit_changed()
## Épaisseur de chaque liseré, en pixels (deux liserés par côté).
@export var line_width := 1:
	set(value):
		line_width = maxi(value, 1)
		emit_changed()
## Couleur de l'intérieur, si le relief n'est qu'un cadre (fenêtre) ;
## transparente : la face couvre tout (bouton).
@export var fill := Color(0, 0, 0, 0):
	set(value):
		fill = value
		emit_changed()
## Largeur du cadre autour de l'intérieur, liserés compris.
@export var frame_width := 4:
	set(value):
		frame_width = value
		emit_changed()
## Faux : seulement la face, sans liseré (fenêtre inactive, bouton plat).
@export var draw_bevel := true:
	set(value):
		draw_bevel = value
		emit_changed()


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	RenderingServer.canvas_item_add_rect(to_canvas_item, rect, face)
	if fill.a > 0.0:
		RenderingServer.canvas_item_add_rect(to_canvas_item, rect.grow(-frame_width), fill)
	if not draw_bevel:
		return
	var w := float(line_width)
	var outer_top := dark if sunken else light
	var outer_bottom := light if sunken else dark
	var inner_top := shadow if sunken else face.lightened(0.18)
	var inner_bottom := face.lightened(0.18) if sunken else shadow
	_frame(to_canvas_item, rect, w, outer_top, outer_bottom)
	_frame(to_canvas_item, rect.grow(-w), w, inner_top, inner_bottom)


## Trace un liseré : haut et gauche d'une couleur, bas et droite d'une autre.
func _frame(item: RID, rect: Rect2, w: float, top_left: Color, bottom_right: Color) -> void:
	var p := rect.position
	var s := rect.size
	RenderingServer.canvas_item_add_rect(item, Rect2(p, Vector2(s.x, w)), top_left)
	RenderingServer.canvas_item_add_rect(item, Rect2(p, Vector2(w, s.y)), top_left)
	RenderingServer.canvas_item_add_rect(item, Rect2(p + Vector2(0, s.y - w), Vector2(s.x, w)), bottom_right)
	RenderingServer.canvas_item_add_rect(item, Rect2(p + Vector2(s.x - w, 0), Vector2(w, s.y)), bottom_right)
