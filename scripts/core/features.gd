class_name Features
extends RefCounted
## Fonctions de l'interface et actions débloquées progressivement
## (data/rules/features.json). Logique pure : une fonction absente du fichier
## est toujours disponible.

const DATA_PATH := "res://data/rules/features.json"


## state : état des conditions (GameState.get_condition_state()).
static func is_unlocked(feature: String, state: Dictionary,
		data: Dictionary = DataLoader.load_json(DATA_PATH)) -> bool:
	var features: Dictionary = data.get("features", {})
	if not features.has(feature):
		return true
	return EventRules.are_conditions_met(features[feature], state)
