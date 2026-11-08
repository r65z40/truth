class_name RadioRules
extends RefCounted
## Radio étrangère (logique pure) : capter Radio Aldria le soir, au volume choisi.
## Volume bas : le début du bulletin seulement, sans risque. Volume haut : tout le
## bulletin, mais chaque soirée « forte » compte, et les voisins finissent par
## entendre. Données : data/radio.json.

const DATA_PATH := "res://data/radio.json"
const LOW := "low"
const LOUD := "loud"

static var _data := {}


static func get_data() -> Dictionary:
	if _data.is_empty():
		_data = DataLoader.load_json(DATA_PATH)
	return _data


static func is_radio(action: Dictionary) -> bool:
	return action.get("kind", "") == "radio"


## Bulletin entendu à volume bas : la première phrase, puis le brouillage.
static func muffle(text: String) -> String:
	var cut := -1
	for mark in [". ", " : ", " ! ", " ? "]:
		var index := text.find(mark)
		if index >= 0 and (cut < 0 or index < cut):
			cut = index + (1 if mark == ". " else mark.length() - 1)
	var head := text if cut < 0 else text.substr(0, cut).strip_edges()
	return "%s %s" % [head, get_data().get("muffled_suffix", "")]


## Nombre de soirées passées à écouter la radio fort (historique des soirées).
static func loud_count(evenings: Dictionary) -> int:
	return evenings.values().filter(func(evening: Variant) -> bool:
		return evening is Dictionary and evening.get("volume", "") == LOUD).size()


## Drapeaux posés quand le compteur de soirées fortes atteint `count`.
static func flags_at(count: int) -> Dictionary:
	var result := {}
	for threshold in get_data().get("loud_thresholds", []):
		if int(threshold.get("count", 0)) == count:
			result[threshold.flag] = true
	return result
