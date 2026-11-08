class_name MailSorting
extends RefCounted
## Tri du courrier (logique pure) : certains jours, un paquet de lettres interceptées.
## Pour chacune, l'agent choisit TRANSMETTRE, RETENIR ou SIGNALER. Rien ne dit ce
## qui est « juste » : seules les conséquences parlent. Tout l'état tient dans les
## drapeaux « mail.<lettre>.<verdict> ». Données : data/mail_sorting.json.

const DATA_PATH := "res://data/mail_sorting.json"
const VERDICTS := ["transmit", "hold", "report"]
## Issue d'une lettre que personne n'a triée : elle part telle quelle.
const DEFAULT_VERDICT := "transmit"

static var _data := {}


static func get_data() -> Dictionary:
	if _data.is_empty():
		_data = DataLoader.load_json(DATA_PATH)
	return _data


## Paquet du jour, ou {}.
static func batch_for_day(day: int) -> Dictionary:
	for batch in get_data().get("batches", []):
		if int(batch.get("day", -1)) == day:
			return batch
	return {}


static func verdict_of(letter_id: String, flags: Dictionary) -> String:
	for verdict in VERDICTS:
		if flags.get("mail.%s.%s" % [letter_id, verdict], false):
			return verdict
	return ""


## Lettres du jour pas encore triées.
static func pending(day: int, flags: Dictionary) -> Array:
	return batch_for_day(day).get("letters", []).filter(func(letter: Dictionary) -> bool:
		return verdict_of(letter.id, flags) == "")


static func get_letter(letter_id: String) -> Dictionary:
	for batch in get_data().get("batches", []):
		for letter in batch.get("letters", []):
			if letter.get("id", "") == letter_id:
				return letter
	return {}


## Conséquence d'un verdict : {effects, flags} ; {} si inconnu.
static func resolve(letter: Dictionary, verdict: String) -> Dictionary:
	if letter.is_empty() or not verdict in VERDICTS:
		return {}
	var outcome: Dictionary = letter.get("outcomes", {}).get(verdict, {})
	var flags: Dictionary = outcome.get("flags", {}).duplicate()
	flags["mail.%s.%s" % [letter.id, verdict]] = true
	return {"effects": outcome.get("effects", {}), "flags": flags}


## Libellé d'un verdict (bouton).
static func verdict_label(verdict: String) -> String:
	return get_data().get("verdicts", {}).get(verdict, verdict.to_upper())
