class_name FieldLamp
extends ColorRect
## Obscurité d'une scène de terrain (clé "darkness", voir FieldRules) : un voile
## noir posé sur l'image, percé par le halo de la lampe. Purement visuel : c'est
## FieldScreen qui déplace la lampe et décide de ce qui est éclairé.

const SHADER := preload("res://ui/shaders/lamp.gdshader")


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color.BLACK
	material = ShaderMaterial.new()
	material.shader = SHADER
	resized.connect(func() -> void: material.set_shader_parameter("rect_size", size))


## Place le halo : centre et rayon en pixels du contrôle.
func set_lamp(center: Vector2, radius_px: float) -> void:
	material.set_shader_parameter("rect_size", size)
	material.set_shader_parameter("lamp", center)
	material.set_shader_parameter("radius", radius_px)
