class_name Backdrop
extends TextureRect
## Image de fond plein écran, assombrie, prise dans un emplacement de
## data/images.json (ImageSlots). Posée derrière le contenu d'un écran ;
## sans image, elle ne s'ajoute pas et l'écran garde son fond uni.

## Luminosité de l'image (0 : noir, 1 : telle quelle), pour garder le texte lisible.
const DEFAULT_BRIGHTNESS := 0.4


## Ajoute le fond de cet emplacement sous les autres enfants de parent.
## Renvoie le fond créé, ou null si l'image manque.
static func add_to(parent: Control, slot_id: String, brightness := DEFAULT_BRIGHTNESS) -> Backdrop:
	var texture := ImageSlots.texture(slot_id)
	if texture == null:
		return null
	var backdrop := Backdrop.new()
	backdrop.name = "Backdrop"
	backdrop.texture = texture
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.modulate = Color(brightness, brightness, brightness)
	parent.add_child(backdrop)
	parent.move_child(backdrop, 0)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return backdrop
