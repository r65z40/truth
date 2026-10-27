class_name Career
extends RefCounted
## Échelons de carrière et revue de fin d'acte (docs/design/CARRIERE.md).
##
## La promotion est décidée par une règle déterministe (data/rules/promotion.json) :
## dossiers conclus, conclusions appuyées par une contradiction, loyauté,
## suspicion. Une faveur de la Milice peut remplacer la qualité des conclusions.
## Logique pure : GameState applique le résultat.

enum Rank { INSPECTOR, INSPECTOR_2ND, PRINCIPAL_INSPECTOR, DEPUTY_SECTION_CHIEF, ACTING_DEPUTY_DIRECTOR, MINISTER, LEADER }

const RANK_TITLES := {
	Rank.INSPECTOR: "Inspecteur de 3e classe",
	Rank.INSPECTOR_2ND: "Inspecteur de 2e classe",
	Rank.PRINCIPAL_INSPECTOR: "Inspecteur principal",
	Rank.DEPUTY_SECTION_CHIEF: "Chef de section adjoint",
	Rank.ACTING_DEPUTY_DIRECTOR: "Directeur adjoint par intérim",
	Rank.MINISTER: "Ministre de la Sécurité",
	Rank.LEADER: "Haut dirigeant du régime",
}

const RULES_PATH := "res://data/rules/promotion.json"


static func rank_title(rank: int) -> String:
	return UiText.of(RANK_TITLES.get(rank, "Grade inconnu"))


## Règle de promotion de l'acte, ou {} s'il n'y en a pas.
static func act_rules(act: int, data: Dictionary = DataLoader.load_json(RULES_PATH)) -> Dictionary:
	for rules in data.get("acts", []):
		if int(rules.act) == act:
			return rules
	return {}


## Évalue la promotion de fin d'acte.
## state : {indicators, flags, cases} (comme GameState).
## Renvoie {eligible, bought, criteria: [{label, ok}]}.
static func evaluate(rules: Dictionary, state: Dictionary) -> Dictionary:
	var cases: Dictionary = state.get("cases", {})
	var indicators: Dictionary = state.get("indicators", {})
	var flags: Dictionary = state.get("flags", {})
	var decided := 0
	var supported := 0
	for case_id in rules.get("cases", []):
		var case_state: Dictionary = cases.get(case_id, {})
		if case_state.get("decision", "") != "":
			decided += 1
			if not case_state.get("contradictions_found", []).is_empty():
				supported += 1
	var all_decided: bool = decided == rules.get("cases", []).size()
	var quality: bool = supported >= int(rules.get("min_supported_conclusions", 0))
	var loyal: bool = int(indicators.get("loyalty", 0)) >= int(rules.get("min_loyalty", 0))
	var trusted: bool = int(indicators.get("suspicion", 0)) <= int(rules.get("max_suspicion", 100))
	var favor := false
	for flag in rules.get("bought_by_flags", []):
		if flags.get(flag) == true:
			favor = true
	var bought := not quality and favor
	var criteria := [
		{"label": UiText.of("Tous les dossiers conclus"), "ok": all_decided},
		{"label": UiText.of("Conclusions appuyées par une contradiction établie"), "ok": quality or bought},
		{"label": UiText.of("Loyauté au moins conforme"), "ok": loyal},
		{"label": UiText.of("Pas de surveillance renforcée"), "ok": trusted},
	]
	var eligible := all_decided and (quality or bought) and loyal and trusted
	return {"eligible": eligible, "bought": bought and eligible, "criteria": criteria}
