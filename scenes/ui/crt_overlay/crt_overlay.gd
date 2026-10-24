extends CanvasLayer
## Filtre CRT global, au-dessus de toutes les scènes. Activable dans les paramètres.


func _ready() -> void:
	Settings.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	visible = Settings.crt_effect
