class_name EventRules
extends RefCounted
## Événements différés : ce qui arrive au début d'une nouvelle journée selon l'état
## de la partie (conséquences des décisions, rappels, bulletins).
##
## Les événements sont décrits dans res://data/events/events.json. Logique pure :
## ce module dit quels événements sont dus ; GameState.end_day() les applique.
##
## Conditions disponibles (toutes doivent être vraies) :
## - min_day          : jour minimal (day_index) de déclenchement.
## - requires_flags   : drapeaux qui doivent valoir true.
## - forbidden_flags  : drapeaux qui ne doivent pas valoir true.
## - undecided_cases  : dossiers encore sans décision.
## Un événement ne se déclenche qu'une fois, sauf "repeatable": true.

const EVENTS_PATH := "res://data/events/events.json"


static func get_events() -> Array:
	return DataLoader.load_json(EVENTS_PATH).get("events", [])


## Événements à déclencher pour l'état donné, dans l'ordre du fichier.
## state : {day_index, flags, cases, fired_events}
static func due_events(state: Dictionary, events: Array = get_events()) -> Array:
	var due := []
	for event in events:
		if event.id in state.get("fired_events", []) and not event.get("repeatable", false):
			continue
		if are_conditions_met(event.get("conditions", {}), state):
			due.append(event)
	return due


static func are_conditions_met(conditions: Dictionary, state: Dictionary) -> bool:
	var flags: Dictionary = state.get("flags", {})
	if int(state.get("day_index", 0)) < int(conditions.get("min_day", 0)):
		return false
	for flag in conditions.get("requires_flags", []):
		if flags.get(flag) != true:
			return false
	for flag in conditions.get("forbidden_flags", []):
		if flags.get(flag) == true:
			return false
	for case_id in conditions.get("undecided_cases", []):
		var case_state: Dictionary = state.get("cases", {}).get(case_id, {})
		if case_state.get("decision", "") != "":
			return false
	return true
