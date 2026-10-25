class_name MusicRules
extends RefCounted
## Choix du morceau (logique pure) : data/music.json associe chaque moment du jeu
## (« contexte » : menu, bureau, soirée, terrain...) à un morceau, selon l'état
## de la partie (acte, jour, drapeaux, indicateurs). La première règle qui
## convient l'emporte ; aucune règle : silence.

const MUSIC_PATH := "res://data/music.json"

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		_data = DataLoader.load_json(MUSIC_PATH)
	return _data


## Identifiant du morceau pour ce contexte ("" : silence).
static func track_for(context: String, state: Dictionary) -> String:
	for rule in data().get("rules", []):
		var contexts = rule.get("context", "")
		var matches: bool = context in contexts if contexts is Array else context == contexts
		if matches and are_conditions_met(rule.get("conditions", {}), state):
			return rule.get("track", "")
	return ""


## Fiche du morceau : {file, volume_db} ; vide si inconnu.
static func get_track(track_id: String) -> Dictionary:
	return data().get("tracks", {}).get(track_id, {})


## Conditions des événements (jour, drapeaux), plus l'acte et les indicateurs :
## {"act": 2, "min_indicator": {"suspicion": 60}, "max_indicator": {"loyalty": 30}}.
static func are_conditions_met(conditions: Dictionary, state: Dictionary) -> bool:
	if not EventRules.are_conditions_met(conditions, state):
		return false
	var day := int(state.get("day_index", 0))
	if conditions.has("max_day") and day > int(conditions.max_day):
		return false
	if conditions.has("act") and int(FictionalCalendar.act_for_day(day).get("number", 1)) != int(conditions.act):
		return false
	var indicators: Dictionary = state.get("indicators", {})
	for indicator in conditions.get("min_indicator", {}):
		if int(indicators.get(indicator, 0)) < int(conditions.min_indicator[indicator]):
			return false
	for indicator in conditions.get("max_indicator", {}):
		if int(indicators.get(indicator, 0)) > int(conditions.max_indicator[indicator]):
			return false
	return true
