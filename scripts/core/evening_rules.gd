class_name EveningRules
extends RefCounted
## Soirées dans l'appartement de Vosk : une action par soir, choisie parmi 2 ou 3.
##
## Les soirées sont décrites dans res://data/evenings.json. Logique pure : ce
## module dit quelle soirée a lieu, quelles actions sont possibles et ce qu'elles
## produisent ; GameState applique le résultat.
##
## Conditions : celles des événements (EventRules), plus
## - min_count : {"radio": 2} = au moins 2 soirées passées à cette activité
##               (le champ "kind" des actions), choix du soir compris.
## Historique (dans GameState.evenings) : {"<jour>": {"action": id, "kind": kind}},
## action vide si la soirée a été perdue en heures supplémentaires.

const EVENINGS_PATH := "res://data/evenings.json"


static func get_data() -> Dictionary:
	return DataLoader.load_json(EVENINGS_PATH)


## Soirée prévue pour ce jour, ou {} s'il n'y en a pas.
static func evening_for_day(day: int, data: Dictionary = get_data()) -> Dictionary:
	for evening in data.get("evenings", []):
		if int(evening.get("day", -1)) == day:
			return evening
	return {}


## Nombre de soirées passées à chaque activité.
static func counts(history: Dictionary) -> Dictionary:
	var result := {}
	for day in history:
		var kind: String = history[day].get("kind", "")
		if kind != "":
			result[kind] = int(result.get(kind, 0)) + 1
	return result


## state : état des conditions (voir GameState.get_condition_state) avec
## "evening_counts" en plus.
static func are_conditions_met(conditions: Dictionary, state: Dictionary) -> bool:
	if not EventRules.are_conditions_met(conditions, state):
		return false
	var current: Dictionary = state.get("evening_counts", {})
	var required: Dictionary = conditions.get("min_count", {})
	for kind in required:
		if int(current.get(kind, 0)) < int(required[kind]):
			return false
	return true


## Actions proposées ce soir, dans l'ordre du fichier.
static func available_actions(evening: Dictionary, state: Dictionary) -> Array:
	return evening.get("actions", []).filter(func(action: Dictionary) -> bool:
		return are_conditions_met(action.get("conditions", {}), state))


static func get_action(evening: Dictionary, action_id: String) -> Dictionary:
	for action in evening.get("actions", []):
		if action.id == action_id:
			return action
	return {}


## Résultat d'une action pour l'état donné (avant application) :
## {text, effects, set_flags}. Le texte est la première variante dont les
## conditions sont remplies, suivi des suites ("followups") déclenchées.
## Les conditions des suites voient le choix du soir déjà compté.
static func resolve(action: Dictionary, state: Dictionary) -> Dictionary:
	var texts: PackedStringArray = []
	for variant in action.get("results", []):
		if are_conditions_met(variant.get("conditions", {}), state):
			texts.append(variant.get("text", ""))
			break
	var effects: Dictionary = action.get("effects", {}).duplicate()
	var set_flags: Dictionary = action.get("set_flags", {}).duplicate()
	var after := state.duplicate()
	var after_counts: Dictionary = state.get("evening_counts", {}).duplicate()
	var kind: String = action.get("kind", "")
	if kind != "":
		after_counts[kind] = int(after_counts.get(kind, 0)) + 1
	after["evening_counts"] = after_counts
	var after_flags: Dictionary = state.get("flags", {}).duplicate()
	after_flags.merge(set_flags, true)
	after["flags"] = after_flags
	for followup in action.get("followups", []):
		if not are_conditions_met(followup.get("conditions", {}), after):
			continue
		if followup.has("text"):
			texts.append(followup.text)
		for indicator in followup.get("effects", {}):
			effects[indicator] = int(effects.get(indicator, 0)) + int(followup.effects[indicator])
		set_flags.merge(followup.get("set_flags", {}), true)
	return {"text": "\n\n".join(texts), "effects": effects, "set_flags": set_flags}
