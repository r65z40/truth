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

const NAME := "VERITAS"


## Remarque de VERITAS sur une pièce, ou "" si elle n'en a pas.
static func document_remark(document: Dictionary) -> String:
	return document.get("veritas_remark", "")


## Recommandation sur un dossier : {decision_id, label, confidence, rationale}, ou {}.
static func recommendation(case_data: Dictionary) -> Dictionary:
	var data: Dictionary = case_data.get("veritas", {})
	if not data.has("recommendation"):
		return {}
	var decision := CaseLibrary.get_decision(case_data, data.recommendation)
	return {
		"decision_id": data.recommendation,
		"label": decision.get("label", data.recommendation),
		"confidence": int(data.get("confidence", 50)),
		"rationale": data.get("rationale", ""),
	}


## Réponse à la commande VERITAS du terminal, selon l'état des dossiers.
## cases : GameState.cases (case_id -> état du dossier).
static func terminal_reply(cases: Dictionary) -> String:
	for case_id in cases:
		var case_state: Dictionary = cases[case_id]
		if case_state.get("decision", "") != "":
			continue
		var case_data := CaseLibrary.get_case(case_id)
		var unread := 0
		for document in case_data.get("documents", []):
			if not document.id in case_state.get("viewed_documents", []):
				unread += 1
		if unread > 0:
			return "Dossier %s : %d pièce(s) non consultée(s). Je recommande une lecture complète avant toute conclusion." % [case_id, unread]
		var advice := recommendation(case_data)
		if not advice.is_empty():
			return "Dossier %s : je recommande « %s ». Indice de confiance : %d %%." % [case_id, advice.label, advice.confidence]
	return "Aucun dossier en attente. Je reste à votre disposition, inspecteur."
