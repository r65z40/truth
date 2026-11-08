class_name DeadlineRules
extends RefCounted
## Dossier urgent (logique pure) : certains dossiers sont « à rendre avant midi ».
## L'échéance se compte en heures de service, jamais en temps réel : lire reste
## gratuit, seules les actions qui coûtent des heures rapprochent l'aiguille.
##
## Format dans le JSON du dossier :
##   "deadline": {"day": 7, "hour": 12,
##                "on_time": {"effects": {...}, "flags": {...}},
##                "late": {"effects": {...}, "flags": {...}}}
## Rendre à temps pose « <dossier>.rendu_a_temps », en retard « <dossier>.rendu_en_retard ».

const ON_TIME_FLAG := "%s.rendu_a_temps"
const LATE_FLAG := "%s.rendu_en_retard"


static func has_deadline(case_data: Dictionary) -> bool:
	return case_data.get("deadline", {}) is Dictionary and not case_data.get("deadline", {}).is_empty()


## Heures de service disponibles le jour de l'échéance (midi = 4 heures après 08h00).
static func limit_hours(case_data: Dictionary) -> int:
	var deadline: Dictionary = case_data.get("deadline", {})
	return int(deadline.get("hour", 12)) - int(WorkTime.rules().get("day_start_hour", 8))


## Heure d'échéance affichée, par exemple « 12h00 ».
static func hour_text(case_data: Dictionary) -> String:
	return "%02dh00" % int(case_data.get("deadline", {}).get("hour", 12))


## Une signature maintenant (qui coûte sign_hours) arriverait-elle à temps ?
static func is_on_time(case_data: Dictionary, day_index: int, hours_used: int, sign_hours: int) -> bool:
	if not has_deadline(case_data):
		return true
	var day := int(case_data.deadline.get("day", 0))
	if day_index != day:
		return day_index < day
	return hours_used + sign_hours <= limit_hours(case_data)


## État d'un dossier non encore signé : "none", "pending" ou "late".
static func status(case_data: Dictionary, day_index: int, hours_used: int, sign_hours: int) -> String:
	if not has_deadline(case_data):
		return "none"
	return "pending" if is_on_time(case_data, day_index, hours_used, sign_hours) else "late"


## Conséquence (effets + drapeaux) d'une remise à temps ou en retard.
static func outcome(case_data: Dictionary, case_id: String, on_time: bool) -> Dictionary:
	var block: Dictionary = case_data.get("deadline", {}).get("on_time" if on_time else "late", {})
	var flags: Dictionary = block.get("flags", {}).duplicate()
	flags[(ON_TIME_FLAG if on_time else LATE_FLAG) % case_id] = true
	return {"effects": block.get("effects", {}), "flags": flags}
