class_name SourceWear
extends RefCounted
## Sources qui s'usent (logique pure) : un informateur ou un service pris en défaut
## dans un dossier voit sa cote abaissée dans les dossiers suivants. Seule la cote
## affichée et le commentaire de VERITAS changent : la vérité des pièces, elle, ne
## bouge pas. Règles : data/sources.json.
##
## Une règle : {id, source_prefix, documents (ids, facultatif), caught_in: {case,
## contradictions_any}, remark}. Une source est « prise en défaut » quand l'agent a
## établi une de ces contradictions dans le dossier indiqué. Chaque règle remplie
## abaisse la cote d'un cran (A > B > C > D), sans effet dans le dossier même.

const DATA_PATH := "res://data/sources.json"
const SCALE := "ABCD"

static var _data := {}


static func get_data() -> Dictionary:
	if _data.is_empty():
		_data = DataLoader.load_json(DATA_PATH)
	return _data


## Cote abaissée de `steps` crans, sans descendre sous D.
static func downgrade(letter: String, steps: int) -> String:
	var index := SCALE.find(letter)
	if index < 0:
		return letter
	return SCALE[mini(index + steps, SCALE.length() - 1)]


## La règle est-elle remplie dans cet état de partie ?
static func is_caught(rule: Dictionary, state: Dictionary) -> bool:
	var caught: Dictionary = rule.get("caught_in", {})
	var case_state: Dictionary = state.get("cases", {}).get(str(caught.get("case", "")), {})
	var found: Array = case_state.get("contradictions_found", [])
	for key in caught.get("contradictions_any", []):
		if key in found:
			return true
	return false


## Règles qui touchent une pièce de ce dossier.
static func rules_for(case_id: String, document: Dictionary, state: Dictionary) -> Array:
	var result: Array = []
	for rule in get_data().get("rules", []):
		if str(rule.get("caught_in", {}).get("case", "")) == case_id:
			continue
		var prefix: String = rule.get("source_prefix", "")
		if prefix == "" or not str(document.get("source", "")).begins_with(prefix):
			continue
		var ids: Array = rule.get("documents", [])
		if not ids.is_empty() and not document.get("id", "") in ids:
			continue
		if is_caught(rule, state):
			result.append(rule)
	return result


## Pièces du dossier, cotes abaissées pour les sources prises en défaut.
static func apply(case_id: String, documents: Array, state: Dictionary) -> Array:
	var result: Array = []
	for document: Dictionary in documents:
		var rules := rules_for(case_id, document, state)
		if rules.is_empty():
			result.append(document)
			continue
		var worn := document.duplicate()
		var before: String = document.get("reliability", "")
		worn["reliability"] = downgrade(before, rules.size())
		worn["reliability_before"] = before
		var remarks: Array = rules.map(func(rule: Dictionary) -> String: return rule.get("remark", ""))
		if document.get("veritas_remark", "") != "":
			remarks.append(document.veritas_remark)
		worn["veritas_remark"] = " ".join(remarks)
		result.append(worn)
	return result
