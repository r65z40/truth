class_name PeopleDirectory
extends RefCounted
## Répertoire des personnes (menu MINISTÈRE). Logique pure : lit
## data/people.json et l'état de conditions, ne modifie rien.
##
## Une fiche est visible quand :
##  - son dossier (clé "case") a au moins une pièce lue, s'il en a un ;
##  - ses conditions (grammaire des événements) sont réunies.
## Le rôle affiché est celui de la dernière mise à jour dont les drapeaux sont
## posés ; le statut tamponné vient de la décision déjà signée (FateRules).

const PEOPLE_PATH := "res://data/people.json"
## Ordre d'affichage des groupes.
const GROUPS := ["ministry", "family", "subjects"]


static func all_people() -> Array:
	return DataLoader.load_json(PEOPLE_PATH).get("people", [])


## Fiches visibles, triées par groupe puis dans l'ordre du fichier. Chaque fiche :
## {id, name, group, role, case, stamp}
static func visible_entries(state: Dictionary) -> Array:
	var result: Array = []
	for group in GROUPS:
		for person: Dictionary in all_people():
			if person.get("group", "subjects") == group and is_visible(person, state):
				result.append(entry_for(person, state))
	return result


static func is_visible(person: Dictionary, state: Dictionary) -> bool:
	var case_id: String = person.get("case", "")
	if case_id != "":
		var case_state: Dictionary = state.get("cases", {}).get(case_id, {})
		if case_state.get("viewed_documents", []).is_empty():
			return false
	return EventRules.are_conditions_met(person.get("conditions", {}), state)


static func entry_for(person: Dictionary, state: Dictionary) -> Dictionary:
	var flags: Dictionary = state.get("flags", {})
	var role: String = person.get("role", "")
	for update: Dictionary in person.get("updates", []):
		var met := true
		for flag in update.get("requires_flags", []):
			if flags.get(flag) != true:
				met = false
		if met:
			role = update.get("role", role)
	var case_id: String = person.get("case", "")
	var stamp := ""
	if case_id != "":
		var fate := FateRules.fate_for(CaseLibrary.get_case(case_id), state.get("cases", {}).get(case_id, {}))
		stamp = fate.get("stamp", "")
	return {"id": person.id, "name": person.get("name", ""), "group": person.get("group", "subjects"),
			"role": role, "case": case_id, "stamp": stamp}
