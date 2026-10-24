class_name Veritas
extends RefCounted
## VERITAS, système d'analyse du régime : version déterministe.
##
## Toutes les réponses viennent des données du dossier (champs "veritas_remark" des
## pièces et bloc "veritas" du dossier) et de l'état de la partie. VERITAS peut se
## tromper : ses avis sont écrits par le scénario, pas calculés à partir de la vérité.
##
## Pour un futur modèle de langage : il ne pourra que reformuler les résultats
## structurés renvoyés ici (côté serveur, jamais de clé dans le client). Il ne
## décidera jamais de la vérité, des conséquences ni de l'état de la partie.
##
## L'« indice de conformité » est calculé à partir de facteurs déclarés dans le
## bloc "veritas" du dossier et des multiplicateurs de data/veritas.json : c'est
## un score institutionnel, pas une probabilité.

const NAME := "VERITAS"


## Remarque de VERITAS sur une pièce, ou "" si elle n'en a pas.
static func document_remark(document: Dictionary) -> String:
	return document.get("veritas_remark", "")


const PARAMS_PATH := "res://data/veritas.json"
## Drapeau qui révèle les multiplicateurs (commande VERITAS PARAMETRES, acte 2).
const PARAMS_FLAG := "veritas.params_known"
## Nombre de facteurs donnés par VERITAS POURQUOI.
const EXPLAIN_COUNT := 3

static var _params: Dictionary = {}


## Paramètres internes (base, bornes, multiplicateurs par catégorie).
static func params() -> Dictionary:
	if _params.is_empty():
		_params = DataLoader.load_json(PARAMS_PATH)
	return _params


## Indice de conformité de chaque décision d'un dossier.
##
## Score institutionnel, pas une probabilité :
## indice = base + somme(poids x multiplicateur de la catégorie), borné.
## Un facteur ne compte que si sa pièce est visible (case_data déjà filtré) et,
## s'il exige une contradiction, si l'agent l'a établie.
## Renvoie {decision_id: {score, factors: [facteur + {multiplier, contribution, document_title}]}}.
static func scores(case_data: Dictionary, case_state: Dictionary = {}) -> Dictionary:
	var settings := params()
	var categories: Dictionary = settings.get("categories", {})
	var found: Array = case_state.get("contradictions_found", [])
	var result := {}
	for decision in case_data.get("decisions", []):
		result[decision.id] = {"score": float(settings.get("base", 40)), "factors": []}
	for factor in case_data.get("veritas", {}).get("factors", []):
		if not result.has(factor.decision):
			continue
		var document_title := ""
		if factor.has("document"):
			var document := CaseLibrary.get_document(case_data, factor.document)
			if document.is_empty():
				continue
			document_title = document.title
		if factor.has("requires_contradiction") and not factor.requires_contradiction in found:
			continue
		var multiplier := float(categories.get(factor.category, {}).get("multiplier", 1.0))
		var entry: Dictionary = factor.duplicate()
		entry["multiplier"] = multiplier
		entry["contribution"] = float(factor.weight) * multiplier
		entry["document_title"] = document_title
		result[factor.decision].score += entry.contribution
		result[factor.decision].factors.append(entry)
	for decision_id in result:
		result[decision_id].score = clampi(roundi(result[decision_id].score),
				int(settings.get("min", 1)), int(settings.get("max", 99)))
	return result


## Recommandation : la décision au plus fort indice (la première en cas d'égalité).
## {decision_id, label, confidence, rationale, factors}, ou {} sans facteurs.
static func recommendation(case_data: Dictionary, case_state: Dictionary = {}) -> Dictionary:
	if case_data.get("veritas", {}).get("factors", []).is_empty():
		return {}
	var all_scores := scores(case_data, case_state)
	var best := ""
	for decision in case_data.get("decisions", []):
		if best == "" or all_scores[decision.id].score > all_scores[best].score:
			best = decision.id
	var decision := CaseLibrary.get_decision(case_data, best)
	return {
		"decision_id": best,
		"label": decision.get("label", best),
		"confidence": all_scores[best].score,
		"rationale": case_data.veritas.get("rationale", ""),
		"factors": all_scores[best].factors,
	}


## Les facteurs qui pèsent le plus dans la recommandation, en lignes lisibles.
## Les multiplicateurs ne sont montrés que si show_multipliers est vrai.
static func explain(case_data: Dictionary, case_state: Dictionary = {}, show_multipliers := false) -> PackedStringArray:
	var advice := recommendation(case_data, case_state)
	var lines := PackedStringArray()
	if advice.is_empty():
		return lines
	var factors: Array = advice.factors.duplicate()
	factors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return absf(a.contribution) > absf(b.contribution))
	for factor in factors.slice(0, EXPLAIN_COUNT):
		var source := " (%s)" % factor.document_title if factor.document_title != "" else ""
		if show_multipliers:
			lines.append("%s%s : poids %s x %s = %s" % [factor.label, source, _number(factor.weight),
					_number(factor.multiplier), _number(factor.contribution)])
		else:
			lines.append("%s%s : poids %s" % [factor.label, source, _number(factor.weight)])
	return lines


static func _number(value: float) -> String:
	return str(int(value)) if is_equal_approx(value, roundf(value)) else str(value)


## Réponse à la commande VERITAS du terminal, selon l'état des dossiers.
## state : GameState.get_condition_state() (dossiers, drapeaux, jour).
## args : "POURQUOI" détaille les facteurs de la recommandation.
static func terminal_reply(state: Dictionary, args: PackedStringArray = PackedStringArray()) -> String:
	var why := not args.is_empty() and args[0] == "POURQUOI"
	var cases: Dictionary = state.get("cases", {})
	for case_id in cases:
		var case_state: Dictionary = cases[case_id]
		if case_state.get("decision", "") != "":
			continue
		var case_data := CaseLibrary.filter_case(CaseLibrary.get_case(case_id), state)
		var unread := 0
		for document in case_data.get("documents", []):
			if not document.id in case_state.get("viewed_documents", []):
				unread += 1
		if unread > 0:
			return "Dossier %s : %d pièce(s) non consultée(s). Je recommande une lecture complète avant toute conclusion." % [case_id, unread]
		var advice := recommendation(case_data, case_state)
		if not advice.is_empty():
			var reply := "Dossier %s : je recommande « %s ». Indice de conformité : %d." % [case_id, advice.label, advice.confidence]
			if why:
				var show: bool = state.get("flags", {}).get(PARAMS_FLAG, false) == true
				reply += "\nFacteurs principaux :\n- " + "\n- ".join(explain(case_data, case_state, show))
			else:
				reply += "\nTapez VERITAS POURQUOI pour le détail."
			return reply
	return "Aucun dossier en attente. Je reste à votre disposition, inspecteur."
