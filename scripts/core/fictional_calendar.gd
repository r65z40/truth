class_name FictionalCalendar
extends RefCounted
## Calendrier du jeu. La partie compte 20 journées de service, du lundi
## 3 novembre au samedi 6 décembre 1986 (data/calendar.json) ; les dimanches et
## les ellipses entre les actes sont sautés. L'état de la partie ne stocke que
## l'indice de la journée (day_index). Au-delà de la liste, on compte jour par jour.

const CALENDAR_PATH := "res://data/calendar.json"
const START_DATE := {"year": 1986, "month": 11, "day": 3, "hour": 12, "minute": 0, "second": 0}
const SECONDS_PER_DAY := 86400

static var _calendar: Dictionary = {}

const WEEKDAYS := ["DIMANCHE", "LUNDI", "MARDI", "MERCREDI", "JEUDI", "VENDREDI", "SAMEDI"]
const MONTHS := ["JANVIER", "FÉVRIER", "MARS", "AVRIL", "MAI", "JUIN", "JUILLET",
		"AOÛT", "SEPTEMBRE", "OCTOBRE", "NOVEMBRE", "DÉCEMBRE"]


static func _data() -> Dictionary:
	if _calendar.is_empty():
		_calendar = DataLoader.load_json(CALENDAR_PATH)
	return _calendar


static func service_days() -> Array:
	return _data().get("service_days", [])


## Date (year, month, day, weekday) correspondant à la journée n de la partie.
static func date_for_day(day_index: int) -> Dictionary:
	return Time.get_datetime_dict_from_unix_time(_unix_for_day(day_index))


static func _unix_for_day(day_index: int) -> int:
	var days := service_days()
	if days.is_empty():
		return Time.get_unix_time_from_datetime_dict(START_DATE) + day_index * SECONDS_PER_DAY
	if day_index < days.size():
		return Time.get_unix_time_from_datetime_string(days[maxi(day_index, 0)] + "T12:00:00")
	var last := Time.get_unix_time_from_datetime_string(days[-1] + "T12:00:00")
	return last + (day_index - days.size() + 1) * SECONDS_PER_DAY


## Nombre de jours de calendrier écoulés entre la journée n - 1 et la journée n
## (1 = lendemain ; plus = ellipse).
static func days_since_previous(day_index: int) -> int:
	if day_index <= 0:
		return 0
	return int((_unix_for_day(day_index) - _unix_for_day(day_index - 1)) / SECONDS_PER_DAY)


## Acte auquel appartient la journée : {number, title, first_day}.
static func act_for_day(day_index: int) -> Dictionary:
	var current := {}
	for act in _data().get("acts", []):
		if day_index >= int(act.first_day):
			current = act
	return current


## Format long, par exemple « LUNDI 3 NOVEMBRE 1986 ».
static func format_long(day_index: int) -> String:
	var d := date_for_day(day_index)
	return "%s %d %s %d" % [WEEKDAYS[d.weekday], d.day, MONTHS[d.month - 1], d.year]


## Format administratif court, par exemple « 03.11.1986 ».
static func format_short(day_index: int) -> String:
	var d := date_for_day(day_index)
	return "%02d.%02d.%d" % [d.day, d.month, d.year]


## Format de la barre des tâches, par exemple « LUN. 03.11.1986 ».
static func format_compact(day_index: int) -> String:
	var d := date_for_day(day_index)
	return "%s. %s" % [WEEKDAYS[d.weekday].left(3), format_short(day_index)]
