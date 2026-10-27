class_name ImageSlots
extends RefCounted
## Images remplaçables (« emplacements ») déclarées dans data/images.json :
## chaque écran demande son image par un nom stable (« menu_background »),
## jamais par un chemin écrit dans le code. Absente : null, et l'écran garde
## son repli (dessin ou fond uni).

const IMAGES_PATH := "res://data/images.json"

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		_data = DataLoader.load_json(IMAGES_PATH)
	return _data


static func get_slot(slot_id: String) -> Dictionary:
	return data().get("slots", {}).get(slot_id, {})


static func get_slot_ids() -> Array:
	return data().get("slots", {}).keys()


static func has_image(slot_id: String) -> bool:
	return MediaLibrary.exists(get_slot(slot_id).get("file", ""))


static func texture(slot_id: String) -> Texture2D:
	return MediaLibrary.load_texture(get_slot(slot_id).get("file", ""))
