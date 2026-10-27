class_name CaseLibrary
extends RefCounted
## Accès en lecture aux dossiers d'enquête définis dans res://data/cases.
##
## Un dossier est un Dictionary issu du JSON (voir ARCHITECTURE.md > Format d'un dossier).
## Ajouter un dossier = ajouter un fichier case_<id>.json et référencer l'id dans index.json.
## Ce module ne connaît ni l'interface ni l'état de la partie.

const CASES_DIR := "res://data/cases"
const INDEX_PATH := CASES_DIR + "/index.json"

## Champs obligatoires pour qu'un dossier soit utilisable.
const REQUIRED_CASE_FIELDS := ["id", "title", "subject_name", "documents"]
const REQUIRED_DOCUMENT_FIELDS := ["id", "type", "title", "source", "reliability"]

static var _cache: Dictionary = {}


## Liste des identifiants de tous les dossiers du jeu, dans l'ordre de index.json.
static func get_case_ids() -> Array:
	var index := DataLoader.load_json(INDEX_PATH)
	return index.get("cases", [])


## Dossiers attribués dès le début d'une partie. Les autres arrivent par des
## événements ("assign_cases" dans data/events/events.json).
static func get_starting_case_ids() -> Array:
	var index := DataLoader.load_json(INDEX_PATH)
	return index.get("starting_cases", get_case_ids())


## Copie du dossier ne contenant que les pièces visibles dans l'état donné.
## Une pièce peut porter des "conditions" (même format que les événements) :
## par exemple, un procès-verbal qui n'existe que si une audition a eu lieu.
## state : {day_index, flags, cases}
## Un élément ("facts") peut lui aussi porter des "conditions" : il n'apparaît
## qu'une fois obtenu sur le terrain (voir FieldRules).
## Une pièce qui porte "request" n'existe qu'une fois demandée par l'agent, à partir
## du lendemain de la demande (requested_documents de l'état du dossier).
static func filter_case(case_data: Dictionary, state: Dictionary) -> Dictionary:
	var view := case_data.duplicate()
	var documents := []
	var case_state: Dictionary = state.get("cases", {}).get(case_data.get("id", ""), {})
	var requested: Dictionary = case_state.get("requested_documents", {})
	for document in case_data.get("documents", []):
		if document.has("request"):
			if not requested.has(document.id) or int(requested[document.id]) >= int(state.get("day_index", 0)):
				continue
		if not EventRules.are_conditions_met(document.get("conditions", {}), state):
			continue
		# Un élément peut aussi porter des conditions (procès-verbaux de terrain).
		var shown: Dictionary = document
		var facts: Array = document.get("facts", [])
		if facts.any(func(fact: Dictionary) -> bool: return fact.has("conditions")):
			shown = document.duplicate()
			shown["facts"] = facts.filter(func(fact: Dictionary) -> bool:
				return EventRules.are_conditions_met(fact.get("conditions", {}), state))
		documents.append(shown)
	view["documents"] = documents
	return view


## Renvoie le dossier complet, ou un Dictionary vide s'il n'existe pas.
static func get_case(case_id: String) -> Dictionary:
	if not _cache.has(case_id):
		var data := DataLoader.load_json("%s/case_%s.json" % [CASES_DIR, case_id])
		if data.is_empty():
			return {}
		_cache[case_id] = data
	return _cache[case_id]


## Renvoie un document d'un dossier par son identifiant.
static func get_document(case_data: Dictionary, document_id: String) -> Dictionary:
	for document in case_data.get("documents", []):
		if document.get("id") == document_id:
			return document
	return {}


## Renvoie un élément notable (fact) par son identifiant, avec l'id de sa pièce
## ajouté sous "document_id". Dictionary vide s'il n'existe pas.
static func get_fact(case_data: Dictionary, fact_id: String) -> Dictionary:
	for document in case_data.get("documents", []):
		for fact in document.get("facts", []):
			if fact.get("id") == fact_id:
				var result: Dictionary = fact.duplicate()
				result["document_id"] = document.id
				return result
	return {}


## Confronte deux éléments notables. Renvoie la clé contredite si les deux
## éléments portent sur le même point avec des valeurs différentes, sinon "".
static func confront(case_data: Dictionary, fact_a_id: String, fact_b_id: String) -> String:
	var a := get_fact(case_data, fact_a_id)
	var b := get_fact(case_data, fact_b_id)
	if a.is_empty() or b.is_empty() or fact_a_id == fact_b_id:
		return ""
	if a.key == b.key and a.value != b.value:
		return a.key
	return ""


## Prix à payer pour PROUVER (établir officiellement) une contradiction, ou {} si
## elle s'établit gratuitement. Déclaré au dossier sous "contradiction_prices" :
##   "<clé>": {"hours": h, "suspicion": s, "requires_flag": f, "label": "..."}
## Repérer la contradiction reste toujours gratuit ; seul l'établir a un prix.
## "hours" = une heure de service (le temps), "suspicion" = le risque, et
## "requires_flag" = une faveur/un appui sans lequel on ne peut pas la prouver.
static func contradiction_price(case_data: Dictionary, key: String) -> Dictionary:
	return case_data.get("contradiction_prices", {}).get(key, {})


## Renvoie une décision du dossier par son identifiant.
static func get_decision(case_data: Dictionary, decision_id: String) -> Dictionary:
	for decision in case_data.get("decisions", []):
		if decision.get("id") == decision_id:
			return decision
	return {}


## Liste des problèmes de structure d'un dossier (vide si le dossier est valide).
static func validate_case(case_data: Dictionary) -> Array[String]:
	var problems: Array[String] = []
	for field in REQUIRED_CASE_FIELDS:
		if not case_data.has(field):
			problems.append("champ manquant : %s" % field)
	var seen_ids := {}
	for document in case_data.get("documents", []):
		for field in REQUIRED_DOCUMENT_FIELDS:
			if not document.has(field):
				problems.append("document %s : champ manquant %s" % [document.get("id", "?"), field])
		var doc_id: String = document.get("id", "")
		if seen_ids.has(doc_id):
			problems.append("identifiant de document en double : %s" % doc_id)
		seen_ids[doc_id] = true
		for fact in document.get("facts", []):
			for field in ["id", "key", "value", "label"]:
				if not fact.has(field):
					problems.append("document %s : élément sans %s" % [doc_id, field])
			if seen_ids.has(fact.get("id", "")):
				problems.append("identifiant en double : %s" % fact.get("id", ""))
			seen_ids[fact.get("id", "")] = true
	var responses: Dictionary = case_data.get("responses", {})
	for decision in case_data.get("decisions", []):
		var outcomes: Array = decision.get("outcomes", [])
		if outcomes.is_empty() or outcomes[-1].get("when") != "default":
			problems.append("décision %s : la dernière issue doit être \"default\"" % decision.get("id", "?"))
		for outcome in outcomes:
			if not responses.has(outcome.get("response", "")):
				problems.append("décision %s : réponse introuvable %s" % [decision.get("id", "?"), outcome.get("response", "")])
	return problems


## Détecte les contradictions factuelles entre documents.
##
## Chaque document peut déclarer des "facts" {key, value}. Deux documents qui
## donnent une valeur différente pour la même clé se contredisent.
## Renvoie une liste de {key, entries: [{document_id, value}, ...]}.
## Note : une contradiction n'indique pas quel document ment. C'est au joueur de trancher.
static func find_contradictions(case_data: Dictionary) -> Array[Dictionary]:
	var by_key := {}
	for document in case_data.get("documents", []):
		for fact in document.get("facts", []):
			var key: String = fact.get("key", "")
			if not by_key.has(key):
				by_key[key] = []
			by_key[key].append({"document_id": document.get("id"), "value": fact.get("value")})
	var contradictions: Array[Dictionary] = []
	for key in by_key:
		var values := {}
		for entry in by_key[key]:
			values[entry.value] = true
		if values.size() > 1:
			contradictions.append({"key": key, "entries": by_key[key]})
	return contradictions
