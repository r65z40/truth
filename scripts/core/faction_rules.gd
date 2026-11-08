class_name FactionRules
extends RefCounted
## Factions (docs/design/FACTIONS.md) : la Direction, la Section 7, la Milice,
## L'HEURE JUSTE, les familles.
##
## L'attitude d'une faction envers l'agent n'est pas un état de plus : elle se
## déduit des drapeaux déjà posés (data/factions.json, un poids par drapeau), puis
## d'un palier (hostile, méfiante, neutre, favorable, alliée). Logique pure et
## déterministe : rien à sauvegarder, tout se recalcule depuis la partie.

const DATA_PATH := "res://data/factions.json"


## Fichier lu une fois : ne pas modifier ce qui est renvoyé.
static var _data := {}


static func get_data() -> Dictionary:
	if _data.is_empty():
		_data = DataLoader.load_json(DATA_PATH)
	return _data


static func get_faction(faction_id: String, data: Dictionary = get_data()) -> Dictionary:
	for faction: Dictionary in data.get("factions", []):
		if faction.id == faction_id:
			return faction
	return {}


## Somme des poids des drapeaux posés pour cette faction.
static func score(faction: Dictionary, flags: Dictionary) -> int:
	var total := 0
	var weights: Dictionary = faction.get("weights", {})
	for flag in weights:
		if flags.get(flag) == true:
			total += int(weights[flag])
	return total


## Rang du palier (0 = hostile ... 4 = alliée) pour un score.
static func level_index(value: int, data: Dictionary = get_data()) -> int:
	var levels: Array = data.get("levels", [])
	for i in levels.size():
		if value < int(levels[i].below):
			return i
	return levels.size() - 1


## Rang du palier d'un identifiant de palier ("neutre"...), ou -1.
static func level_rank(level_id: String, data: Dictionary = get_data()) -> int:
	var levels: Array = data.get("levels", [])
	for i in levels.size():
		if levels[i].id == level_id:
			return i
	return -1


## Rang du palier actuel d'une faction.
static func standing_rank(faction_id: String, flags: Dictionary, data: Dictionary = get_data()) -> int:
	return level_index(score(get_faction(faction_id, data), flags), data)


## Identifiant du palier actuel ("hostile"...) d'une faction.
static func standing(faction_id: String, flags: Dictionary, data: Dictionary = get_data()) -> String:
	return data.levels[standing_rank(faction_id, flags, data)].id


## Conditions d'événement : {"milice": "mefiante"} = au moins / au plus ce palier.
static func at_least(requirements: Dictionary, flags: Dictionary, data: Dictionary = get_data()) -> bool:
	for faction_id in requirements:
		if standing_rank(faction_id, flags, data) < level_rank(requirements[faction_id], data):
			return false
	return true


static func at_most(requirements: Dictionary, flags: Dictionary, data: Dictionary = get_data()) -> bool:
	for faction_id in requirements:
		if standing_rank(faction_id, flags, data) > level_rank(requirements[faction_id], data):
			return false
	return true


## Lignes du dossier personnel : [{name, label, id}] dans l'ordre du fichier.
static func describe(flags: Dictionary, data: Dictionary = get_data()) -> Array:
	var out := []
	for faction: Dictionary in data.get("factions", []):
		var level: Dictionary = data.levels[level_index(score(faction, flags), data)]
		out.append({"id": faction.id, "name": faction.name, "label": level.label, "level": level.id})
	return out
