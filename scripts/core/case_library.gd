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


## Liste des identifiants de dossiers disponibles, dans l'ordre de index.json.
static func get_case_ids() -> Array:
	var index := DataLoader.load_json(INDEX_PATH)
	return index.get("cases", [])


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
