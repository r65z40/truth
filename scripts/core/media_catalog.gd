class_name MediaCatalog
extends RefCounted
## Inventaire de tous les médias attendus par le jeu (musiques, ambiances,
## bruitages, images, décors de terrain), d'après les fichiers de données.
## Sert à l'outil « Médias » de la visite des scènes : on voit d'un coup
## d'œil ce qui est déjà fourni et ce qui manque.

const FIELD_DIR := "res://data/field"


## Liste de {kind, id, usage, files, present} ; kind : music, ambiance,
## effect, image, field. present : nombre de fichiers trouvés.
static func entries() -> Array:
	var result: Array = []
	var tracks: Dictionary = MusicRules.data().get("tracks", {})
	for track_id in tracks:
		result.append(_entry("music", track_id, "", [tracks[track_id].get("file", "")]))
	var ambiances: Dictionary = SoundRules.data().get("ambiances", {})
	for ambiance_id in ambiances:
		result.append(_entry("ambiance", ambiance_id, ambiances[ambiance_id].get("usage", ""),
				[ambiances[ambiance_id].get("file", "")]))
	for effect_id in SoundRules.get_effect_ids():
		var effect := SoundRules.get_effect(effect_id)
		result.append(_entry("effect", effect_id, effect.get("usage", ""), effect.get("files", [])))
	for slot_id in ImageSlots.get_slot_ids():
		var slot := ImageSlots.get_slot(slot_id)
		result.append(_entry("image", slot_id, slot.get("usage", ""), [slot.get("file", "")]))
	result.append_array(field_entries())
	return result


## Décors des scènes de terrain (clés image et video, pièce par pièce).
static func field_entries() -> Array:
	var result: Array = []
	for file_name in DirAccess.get_files_at(FIELD_DIR):
		if file_name.get_extension() != "json":
			continue
		var scene := DataLoader.load_json(FIELD_DIR.path_join(file_name))
		var views: Array = [scene]
		views.append_array(scene.get("rooms", []))
		for view: Dictionary in views:
			var usage := "%s%s" % [scene.get("title", file_name),
					(" > " + view.get("label", view.id)) if view.has("id") else ""]
			for key in ["image", "video"]:
				if view.has(key):
					result.append(_entry("field", "%s:%s" % [file_name.get_basename(), view.get("id", key)],
							usage, [view[key]]))
	return result


## Compte des médias fournis : {present, total}.
static func summary(list: Array) -> Dictionary:
	var present := 0
	for entry: Dictionary in list:
		if int(entry.present) > 0:
			present += 1
	return {"present": present, "total": list.size()}


static func _entry(kind: String, id: String, usage: String, files: Array) -> Dictionary:
	return {"kind": kind, "id": id, "usage": usage, "files": files,
			"present": files.filter(MediaLibrary.exists).size()}
