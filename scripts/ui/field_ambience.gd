class_name FieldAmbience
extends Control
## Ambiance 2.5D posée sur l'image d'une scène de terrain (clé "ambience", voir
## FieldRules) : grain et lumière qui vacille (shader), poussière en suspension
## (dessinée ici). Purement visuel, sans effet sur le jeu ; coupé par le réglage
## « Scènes de terrain animées ». Le léger mouvement de l'image est fait par
## FieldScreen.

const SHADER := preload("res://ui/shaders/field_ambience.gdshader")
const MAX_DUST := 48

var _veil: ColorRect
var _dust := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil = ColorRect.new()
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_veil.material = ShaderMaterial.new()
	_veil.material.shader = SHADER
	add_child(_veil)


## Règle l'ambiance (valeurs de FieldRules.ambience) ; tout à zéro la coupe.
func configure(settings: Dictionary) -> void:
	_veil.material.set_shader_parameter("grain", float(settings.get("grain", 0.0)))
	_veil.material.set_shader_parameter("flicker", float(settings.get("flicker", 0.0)))
	_dust = float(settings.get("dust", 0.0))
	set_process(_dust > 0.0)
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


## Poussière : des grains qui flottent lentement, chacun sur sa propre trajectoire.
func _draw() -> void:
	if _dust <= 0.0:
		return
	var t := Time.get_ticks_msec() / 1000.0
	var color := Color(1.0, 0.9, 0.7, 0.22)
	for i in int(MAX_DUST * _dust):
		var seed_x := fposmod(sin(i * 12.9898) * 43758.5453, 1.0)
		var seed_y := fposmod(sin(i * 78.233) * 12345.678, 1.0)
		var x := fposmod(seed_x + t * (0.004 + seed_y * 0.006), 1.0)
		var y := fposmod(seed_y - t * (0.003 + seed_x * 0.004) + sin(t * 0.7 + i) * 0.01, 1.0)
		draw_circle(Vector2(x, y) * size, 1.0 + seed_x * 1.5, color)
