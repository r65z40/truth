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
	return scene.get("options", []).filter(func(option: Dictionary) -> bool:
		return not option.id in chosen and are_conditions_met(option.get("conditions", {}), state, noted))


static func get_option(scene: Dictionary, option_id: String) -> Dictionary:
	for option in scene.get("options", []):
		if option.id == option_id:
			return option
	return {}


## Réaction du sujet à un élément présenté : la présentation qui cite cet
## élément (une seule fois), sinon la réponse par défaut, sans effet.
static func presentation_for(scene: Dictionary, scene_state: Dictionary, fact_id: String) -> Dictionary:
	for presentation in scene.get("presentations", []):
		if fact_id in presentation.get("facts", []) and not presentation.id in scene_state.get("chosen", []):
			return presentation
	return {"id": "", "text": scene.get("present_default", "Rien."), "note": []}
