class_name FictionalCalendar
extends RefCounted
## Calendrier du jeu. La partie commence le lundi 3 novembre 1986 ;
## l'état de la partie ne stocke que le nombre de jours écoulés (day_index).

const START_DATE := {"year": 1986, "month": 11, "day": 3, "hour": 12, "minute": 0, "second": 0}
const SECONDS_PER_DAY := 86400

const WEEKDAYS := ["DIMANCHE", "LUNDI", "MARDI", "MERCREDI", "JEUDI", "VENDREDI", "SAMEDI"]
const MONTHS := ["JANVIER", "FÉVRIER", "MARS", "AVRIL", "MAI", "JUIN", "JUILLET",
		"AOÛT", "SEPTEMBRE", "OCTOBRE", "NOVEMBRE", "DÉCEMBRE"]


## Date (year, month, day, weekday) correspondant au jour n de la partie.
static func date_for_day(day_index: int) -> Dictionary:
	var start := Time.get_unix_time_from_datetime_dict(START_DATE)
	return Time.get_datetime_dict_from_unix_time(start + day_index * SECONDS_PER_DAY)


## Format long, par exemple « LUNDI 3 NOVEMBRE 1986 ».
static func format_long(day_index: int) -> String:
	var d := date_for_day(day_index)
	return "%s %d %s %d" % [WEEKDAYS[d.weekday], d.day, MONTHS[d.month - 1], d.year]


## Format administratif court, par exemple « 03.11.1986 ».
static func format_short(day_index: int) -> String:
	var d := date_for_day(day_index)
	return "%02d.%02d.%d" % [d.day, d.month, d.year]
