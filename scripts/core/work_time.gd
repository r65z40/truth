class_name WorkTime
extends RefCounted
## Horloge de service (logique pure). Chaque action importante coûte des heures ;
## lire, noter et confronter sont gratuits. Règles et coûts : data/rules/work_time.json.
##
## Une journée compte day_hours heures, plus overtime_hours heures supplémentaires
## (qui coûtent la soirée de l'agent). Signer une conclusion reste toujours possible.

const RULES_PATH := "res://data/rules/work_time.json"

static var _rules: Dictionary = {}


static func rules() -> Dictionary:
	if _rules.is_empty():
		_rules = DataLoader.load_json(RULES_PATH)
	return _rules


static func day_hours() -> int:
	return int(rules().get("day_hours", 8))


static func overtime_hours() -> int:
	return int(rules().get("overtime_hours", 2))


## Coût en heures d'une action (0 si inconnue).
static func cost(action: String) -> int:
	return int(rules().get("costs", {}).get(action, 0))


## Heures encore disponibles, heures supplémentaires comprises.
static func remaining(hours_used: int) -> int:
	return maxi(day_hours() + overtime_hours() - hours_used, 0)


## L'action est-elle possible ? {ok, overtime} ; overtime = elle déborde sur la soirée.
static func check(hours_used: int, action: String) -> Dictionary:
	var hours := cost(action)
	return {"ok": hours <= remaining(hours_used), "overtime": hours_used + hours > day_hours()}


## Heure affichée sur l'horloge du bureau, par exemple « 09h00 ».
static func clock_text(hours_used: int) -> String:
	return "%02dh00" % (int(rules().get("day_start_hour", 8)) + hours_used)


static func is_overtime(hours_used: int) -> bool:
	return hours_used > day_hours()
