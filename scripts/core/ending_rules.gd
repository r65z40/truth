class_name EndingRules
extends RefCounted
## Résolution de la fin de partie (terme de l'acte 4, fin du jour 20).
##
## Logique pure : lit les drapeaux et indicateurs déjà posés par la partie et
## renvoie LA fin atteinte. Le moteur ne décide rien de neuf — la fin découle des
## conséquences accumulées. Les fins sont décrites dans res://data/endings.json.
##
## On évalue les fins dans l'ordre du fichier (de la plus rare/méritée à la plus
## générale) ; la première dont une règle est satisfaite gagne. LE SILENCE, sans
## règle, est le défaut et doit rester en dernier.
##
## Une fin porte une liste `rules` (OR de ET) : elle est atteinte si l'une des
## règles est satisfaite. Chaque règle reprend la grammaire des conditions
## d'événement (requires_flags, forbidden_flags, min_indicators, max_indicators),
## évaluée par EventRules. L'indicateur spécial `spared` est injecté : c'est le
## nombre d'innocents épargnés (drapeaux de clémence `spared_flags`).

const ENDINGS_PATH := "res://data/endings.json"


static func get_data() -> Dictionary:
	return DataLoader.load_json(ENDINGS_PATH)


static func get_endings() -> Array:
	return get_data().get("endings", [])


static func spared_flags() -> Array:
	return get_data().get("spared_flags", [])


## Nombre d'innocents épargnés : drapeaux de clémence actifs (voir spared_flags).
static func count_spared(flags: Dictionary, data: Dictionary = get_data()) -> int:
	var count := 0
	for flag in data.get("spared_flags", []):
		if flags.get(flag) == true:
			count += 1
	return count


## Résout la fin atteinte. state : {flags, indicators}. Renvoie la fin complète
## (dictionnaire du fichier), ou {} si aucune (ne doit pas arriver : LE SILENCE
## est le défaut). `spared` est ajouté aux indicateurs pour l'évaluation.
static func resolve(state: Dictionary, data: Dictionary = get_data()) -> Dictionary:
	var flags: Dictionary = state.get("flags", {})
	var indicators: Dictionary = state.get("indicators", {}).duplicate()
	indicators["spared"] = count_spared(flags, data)
	var eval_state := {"flags": flags, "indicators": indicators, "day_index": 0,
			"cases": state.get("cases", {}), "fired_events": []}
	for ending in data.get("endings", []):
		if _is_reached(ending, eval_state):
			return ending
	return {}


## Vrai si une des règles de la fin est satisfaite. Sans règle : fin par défaut.
static func _is_reached(ending: Dictionary, eval_state: Dictionary) -> bool:
	var rules: Array = ending.get("rules", [])
	if rules.is_empty():
		return true
	for rule in rules:
		if EventRules.are_conditions_met(rule, eval_state):
			return true
	return false
