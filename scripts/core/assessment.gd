class_name Assessment
extends RefCounted
## Évaluation de l'agent en mots, sans chiffres : traduit les indicateurs internes
## et certains drapeaux en appréciations administratives (data/assessment.json).
## Le joueur comprend sa situation sans voir de jauge.

const DATA_PATH := "res://data/assessment.json"


## Renvoie {lines: [{label, text}], notes: [String]} pour les indicateurs et drapeaux donnés.
static func describe(indicators: Dictionary, flags: Dictionary) -> Dictionary:
	var data := DataLoader.load_json(DATA_PATH)
	var lines := []
	for indicator in data.get("indicators", []):
		var value := int(indicators.get(indicator.id, 0))
		lines.append({"label": indicator.label, "text": level_text(indicator.levels, value)})
	var notes := []
	for note in data.get("flag_notes", []):
		if flags.get(note.flag) == true:
			notes.append(note.text)
	return {"lines": lines, "notes": notes}


## Texte du premier palier dont la borne "below" dépasse la valeur.
static func level_text(levels: Array, value: int) -> String:
	for level in levels:
		if value < int(level.below):
			return level.text
	return levels[-1].text if not levels.is_empty() else "?"
