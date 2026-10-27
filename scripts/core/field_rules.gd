class_name FieldRules
extends RefCounted
## Scènes de terrain : interrogatoires et perquisitions (docs/design/TERRAIN.md).
##
## Une scène est décrite dans res://data/field/<id>.json et rattachée à un dossier
## par la clé "field_scene". Logique pure : ce module dit si une scène est
## possible, quels choix restent, et ce que produit un choix ; GameState applique.
##
## Chaque choix (question, endroit fouillé, élément présenté) consomme un tour et
## pose le drapeau field.<scène>.<choix>, dont dépendent les éléments du
## procès-verbal versé au dossier. Conditions des choix : celles des événements,
## plus requires_noted_any (au moins un de ces éléments noté dans le carnet).
## État d'une scène (GameState.field_scenes[id]) :
## {"turns_used": int, "chosen": [ids], "finished": bool}

const FIELD_DIR := "res://data/field/"


static func get_scene(scene_id: String) -> Dictionary:
	if scene_id == "":
		return {}
	return DataLoader.load_json(FIELD_DIR + scene_id + ".json")


## Scène rattachée au dossier, ou {}.
static func scene_for_case(case_data: Dictionary) -> Dictionary:
	return get_scene(case_data.get("field_scene", ""))


static func flag_for(scene: Dictionary, choice_id: String) -> String:
	return "field.%s.%s" % [scene.id, choice_id]


## La scène peut-elle commencer ? (une seule fois, si l'une des conditions
## "available_when" est remplie)
static func is_available(scene: Dictionary, scene_state: Dictionary, state: Dictionary) -> bool:
	if scene.is_empty() or not scene_state.is_empty():
		return false
	for conditions in scene.get("available_when", [{}]):
		if EventRules.are_conditions_met(conditions, state):
			return true
	return false


static func turns_left(scene: Dictionary, scene_state: Dictionary) -> int:
	return maxi(0, int(scene.get("turns", 1)) - int(scene_state.get("turns_used", 0)))


## noted : éléments notés dans le carnet du dossier.
static func are_conditions_met(conditions: Dictionary, state: Dictionary, noted: Array) -> bool:
	if not EventRules.are_conditions_met(conditions, state):
		return false
	var wanted: Array = conditions.get("requires_noted_any", [])
	return wanted.is_empty() or wanted.any(func(fact_id: String) -> bool: return fact_id in noted)


## Questions ou endroits encore possibles.
static func available_options(scene: Dictionary, scene_state: Dictionary, state: Dictionary, noted: Array) -> Array:
	if scene_state.get("finished", false) or turns_left(scene, scene_state) == 0:
		return []
	var chosen: Array = scene_state.get("chosen", [])
	return all_options(scene).filter(func(option: Dictionary) -> bool:
		return not option.id in chosen \
				and are_conditions_met(option.get("conditions", {}), state, noted) \
				and composure_ok(option, scene, scene_state))


# --- Tension d'un interrogatoire (sang-froid du sujet) ------------------------
#
# Une scène peut déclarer "tension": {"start": int, "label"?} pour varier le
# ressenti (acte 3). Le sang-froid du sujet part de "start" et bouge selon la
# clé "composure_delta" des questions et présentations choisies (négatif = on le
# pousse, positif = on le ménage). Certaines options ne s'ouvrent que dans une
# fenêtre de sang-froid : "requires_composure": {"min"?, "max"?} — par ex. un
# aveu quand le sujet est ébranlé (sang-froid bas) mais pas encore muré (pas
# trop bas). Une scène sans "tension" se comporte comme avant.

static func has_tension(scene: Dictionary) -> bool:
	return not scene.get("tension", {}).is_empty()


## Sang-froid courant du sujet (0-100), ou -1 si la scène n'a pas de tension.
static func composure(scene: Dictionary, scene_state: Dictionary) -> int:
	var tension: Dictionary = scene.get("tension", {})
	if tension.is_empty():
		return -1
	var value := int(tension.get("start", 50))
	var chosen: Array = scene_state.get("chosen", [])
	for entry in all_options(scene) + scene.get("presentations", []):
		if entry.get("id", "") in chosen:
			value += int(entry.get("composure_delta", 0))
	return clampi(value, 0, 100)


## L'option est-elle dans la fenêtre de sang-froid requise ? (vrai si aucune
## fenêtre, ou si la scène n'a pas de tension).
static func composure_ok(option: Dictionary, scene: Dictionary, scene_state: Dictionary) -> bool:
	var band: Dictionary = option.get("requires_composure", {})
	if band.is_empty():
		return true
	var value := composure(scene, scene_state)
	if value < 0:
		return true
	if band.has("min") and value < int(band.min):
		return false
	if band.has("max") and value > int(band.max):
		return false
	return true


static func get_option(scene: Dictionary, option_id: String) -> Dictionary:
	for option in all_options(scene):
		if option.id == option_id:
			return option
	return {}


# --- Pièces (perquisitions en plusieurs pièces reliées par des portes) --------
#
# Une scène peut découper son décor en pièces : chaque pièce a sa propre image,
# ses endroits à fouiller (options) et ses portes vers d'autres pièces. Changer
# de pièce est gratuit ; le budget de fouilles reste commun à toute la scène.
# Une scène sans "rooms" garde ses "options" à plat, comme avant.

static func has_rooms(scene: Dictionary) -> bool:
	return not scene.get("rooms", []).is_empty()


## Toutes les options de la scène, à plat (fusion des pièces s'il y en a).
static func all_options(scene: Dictionary) -> Array:
	if not has_rooms(scene):
		return scene.get("options", [])
	var out: Array = []
	for room: Dictionary in scene.rooms:
		out.append_array(room.get("options", []))
	return out


## Pièce où l'on arrive : celle marquée "start", sinon la première.
static func start_room(scene: Dictionary) -> Dictionary:
	for room: Dictionary in scene.get("rooms", []):
		if room.get("start", false):
			return room
	var rooms: Array = scene.get("rooms", [])
	return rooms[0] if not rooms.is_empty() else {}


static func get_room(scene: Dictionary, room_id: String) -> Dictionary:
	for room: Dictionary in scene.get("rooms", []):
		if room.get("id", "") == room_id:
			return room
	return {}


## Identifiant de la pièce qui contient cette option, ou "".
static func room_of_option(scene: Dictionary, option_id: String) -> String:
	for room: Dictionary in scene.get("rooms", []):
		for option: Dictionary in room.get("options", []):
			if option.get("id", "") == option_id:
				return room.get("id", "")
	return ""


## Réaction du sujet à un élément présenté : la présentation qui cite cet
## élément (une seule fois), sinon la réponse par défaut, sans effet.
static func presentation_for(scene: Dictionary, scene_state: Dictionary, fact_id: String) -> Dictionary:
	for presentation in scene.get("presentations", []):
		if fact_id in presentation.get("facts", []) and not presentation.id in scene_state.get("chosen", []):
			return presentation
	return {"id": "", "text": scene.get("present_default", "Rien."), "note": []}
