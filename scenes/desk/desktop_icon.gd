class_name DesktopIcon
extends Button
## Icône du bureau : image en pixels au-dessus de son nom, et une pastille
## rouge facultative (courrier non lu, dossiers en attente).

@export var icon_name := "document":
	set(value):
		icon_name = value
		_apply_icon()

## Nombre affiché dans la pastille ; 0 la masque.
var badge := 0:
	set(value):
		badge = value
		if _badge_label:
			_badge_label.text = str(value)
			_badge_label.visible = value > 0

var _badge_label: Label


func _ready() -> void:
	theme_type_variation = &"DesktopIcon"
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(104, 86)
	_badge_label = Label.new()
	_badge_label.name = "Badge"
	_badge_label.theme_type_variation = &"IconBadge"
	_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_badge_label.position = Vector2(size.x - 34, 2)
	add_child(_badge_label)
	resized.connect(func() -> void: _badge_label.position = Vector2(size.x * 0.5 + 12, 2))
	badge = badge
	_apply_icon()


func _apply_icon() -> void:
	if is_inside_tree():
		icon = PixelIcons.get_icon(icon_name, 3)
