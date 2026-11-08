class_name MessageTone
extends RefCounted
## Ton du courrier : choisit le post-scriptum d'un pli selon son expéditeur et
## l'état caché de la partie (indicateurs, drapeaux), d'après data/message_tone.json.
## Logique pure ; les conditions sont celles des événements (EventRules).

const DATA_PATH := "res://data/message_tone.json"

static var _data := {}


static func get_data() -> Dictionary:
	if _data.is_empty():
		_data = DataLoader.load_json(DATA_PATH)
	return _data


## Post-scriptum pour un pli de cet expéditeur, ou "" si aucune règle ne convient.
## state : GameState.get_condition_state().
static func postscript(from: String, state: Dictionary) -> String:
	for rule in get_data().get("rules", []):
		if not from.begins_with(rule.get("from_prefix", "")):
			continue
		if EventRules.are_conditions_met(rule.get("conditions", {}), state):
			return rule.get("postscript", "")
	return ""
