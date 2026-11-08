class_name Features
extends RefCounted
## Fonctions de l'interface et actions débloquées progressivement
## (data/rules/features.json). Logique pure : une fonction absente du fichier
## est toujours disponible.

const DATA_PATH := "res://data/rules/features.json"

## Fichier lu une fois (consulté à chaque rafraîchissement d'écran).
static var _data := {}


static func get_data() -> Dictionary:
	if _data.is_empty():
		_data = DataLoader.load_json(DATA_PATH)
	return _data


## state : état des conditions (GameState.get_condition_state()).
static func is_unlocked(feature: String, state: Dictionary,
		data: Dictionary = get_data()) -> bool:
	var features: Dictionary = data.get("features", {})
	if not features.has(feature):
		return true
	return EventRules.are_conditions_met(features[feature], state)
