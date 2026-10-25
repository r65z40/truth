class_name MinistryRecord
extends RefCounted
## Mémoire institutionnelle : le dossier administratif secret que le ministère
## tient sur l'agent, nourri par ses propres actions dans le jeu.
##
## Chaque entrée associe un fait objectif (ce que l'agent a fait, champ "tag") à la
## lecture biaisée qu'en fait le ministère (champ "reading"), écrite à la main dans
## data/ministry_record.json. C'est cette asymétrie qui alimentera le dossier 54100
## à l'acte 3. Aucune donnée personnelle réelle : uniquement des actions de la
## partie. Déterministe : rien n'est inventé à l'exécution.

const PATH := "res://data/ministry_record.json"

static var _entries: Array = []


## Règles de mémoire déclarées dans les données.
static func rules() -> Array:
	if _entries.is_empty():
		_entries = DataLoader.load_json(PATH).get("entries", [])
	return _entries


## Règle correspondant à un drapeau posé, ou {} si ce drapeau n'est pas suivi.
## Correspondance par "flag" exact ou par suffixe "flag_endswith" (drapeaux par
## dossier, ex. "53118.consulted_superior").
static func rule_for(flag: String) -> Dictionary:
	for rule in rules():
		if rule.get("flag", "") == flag:
			return rule
		var suffix: String = rule.get("flag_endswith", "")
		if suffix != "" and flag.ends_with(suffix):
			return rule
	return {}
