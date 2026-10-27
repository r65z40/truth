class_name FateRules
extends RefCounted
## Construit la "carte de destin" d'un sujet, affichée après la signature d'un
## dossier. Logique pure : ne lit que le dossier et son état, ne décide rien de
## nouveau. Le destin découle de la décision déjà prise (déterministe).
##
## Renvoie {} si aucune décision n'a encore été prise, sinon :
## {subject_name, photo, stamp, line, quote}
##  - subject_name : nom du sujet (ou titre du dossier à défaut)
##  - photo        : données de la photo d'identité (clé "photo" d'une pièce), ou {}
##  - stamp        : mention tamponnée (TRANSFÉRÉ / RELAXÉ / MUTÉ…), issue de la
##                   décision (surcouche possible par l'issue déclenchée)
##  - line         : ligne de conséquence (l'archive de la décision)
##  - quote        : phrase d'une famille ou d'un proche, facultative


static func fate_for(case_data: Dictionary, case_state: Dictionary) -> Dictionary:
	var decision_id: String = case_state.get("decision", "")
	if decision_id == "":
		return {}
	var decision := CaseLibrary.get_decision(case_data, decision_id)
	if decision.is_empty():
		return {}
	var outcome := _fired_outcome(decision, case_state)
	return {
		"subject_name": case_data.get("subject_name", case_data.get("title", "")),
		"photo": _subject_photo(case_data),
		"stamp": outcome.get("stamp", decision.get("stamp", UiText.of("CLASSÉ"))),
		# La carte montre la réalité crue (fate_line) si elle est écrite ; sinon la
		# ligne d'archive officielle, plus pudique.
		"line": outcome.get("fate_line", decision.get("fate_line", decision.get("archive", ""))),
		"quote": outcome.get("fate_quote", decision.get("fate_quote", "")),
	}


## Première issue de la décision dont la condition "when" est vraie (même ordre
## que DecisionRules). Renvoie {} si aucune (ne devrait pas arriver).
static func _fired_outcome(decision: Dictionary, case_state: Dictionary) -> Dictionary:
	for outcome in decision.get("outcomes", []):
		if DecisionRules.is_condition_met(outcome.get("when", "default"), case_state):
			return outcome
	return {}


## Photo d'identité du sujet : première pièce qui porte une clé "photo".
static func _subject_photo(case_data: Dictionary) -> Dictionary:
	for document in case_data.get("documents", []):
		if document.has("photo"):
			return document.photo
	return {}
