class_name DecisionRules
extends RefCounted
## Règles de résolution d'une décision sur un dossier. Logique pure : ne modifie
## rien, renvoie ce qui doit arriver. GameState applique ensuite le résultat.
##
## Chaque décision du JSON liste des "outcomes" testés dans l'ordre ; le premier
## dont la condition "when" est vraie s'applique. Le dernier doit être "default".
##
## Conditions disponibles :
## - "contradiction_found" : le joueur a établi au moins une contradiction.
## - "contradiction:<clé>"  : le joueur a établi la contradiction sur cette clé
##                            (ex. "contradiction:horvat.status").
## - "default"             : toujours vraie.


## Résout une décision. Renvoie {} si la décision n'existe pas, sinon :
## {decision_id, status_after, effects: {indicateur: delta}, response: Dictionary, flags: Dictionary}
static func resolve(case_data: Dictionary, case_state: Dictionary, decision_id: String) -> Dictionary:
	var decision := CaseLibrary.get_decision(case_data, decision_id)
	if decision.is_empty():
		return {}
	for outcome in decision.get("outcomes", []):
		if is_condition_met(outcome.get("when", "default"), case_state):
			var response: Dictionary = case_data.get("responses", {}).get(outcome.get("response", ""), {})
			return {
				"decision_id": decision_id,
				"status_after": decision.get("status_after", "closed"),
				"effects": outcome.get("effects", {}),
				"response_id": outcome.get("response", ""),
				"response": response,
				"flags": outcome.get("flags", {}),
			}
	return {}


static func is_condition_met(condition: String, case_state: Dictionary) -> bool:
	match condition:
		"default":
			return true
		"contradiction_found":
			return not case_state.get("contradictions_found", []).is_empty()
	if condition.begins_with("contradiction:"):
		return condition.trim_prefix("contradiction:") in case_state.get("contradictions_found", [])
	push_warning("DecisionRules: condition inconnue : %s" % condition)
	return false
