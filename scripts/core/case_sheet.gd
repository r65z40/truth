class_name CaseSheet
extends RefCounted
## Fiche d'enquête : les questions d'un dossier, remplies par les éléments notés.
## Logique pure (ne lit que les données du dossier et l'état passé en argument).
##
## Un dossier peut déclarer un bloc "questions" :
##   {"id": "where", "text": "Où était SEDLAR le 21 octobre ?",
##    "keys": ["sedlar.location.1986-10-21"], "main": true}
## Chaque élément noté dont la clé figure dans "keys" se range sous la question.
## Une question "main" est visible dès l'ouverture ; les autres restent cachées
## (« question à découvrir ») tant qu'aucun de leurs éléments n'est noté.
##
## Deux éléments d'une même question qui portent sur la même clé avec des valeurs
## différentes forment un CONFLIT (« deux versions ») : c'est exactement une
## contradiction au sens de CaseLibrary.confront(). Le joueur retient alors l'une
## des deux versions (GameState.retain_version), ce qui établit la contradiction.
## La fiche ne dit jamais quelle version est vraie.
##
## Une question peut porter "truth" : la ou les valeurs vraies de sa clé
## contradictoire (donnée cachée, jamais affichée). Retenir une autre version ne
## change rien sur le moment ; à la signature, le dossier reçoit le drapeau
## "<dossier>.version_contestee", que des événements plus tard peuvent lire.

## États d'une question, pour l'interface et l'aide.
const HIDDEN := "hidden"          ## pas encore découverte (aucun élément noté)
const OPEN := "open"              ## visible, aucune réponse
const ANSWERED := "answered"      ## une ou plusieurs réponses concordantes
const CONFLICT := "conflict"      ## deux versions, pas encore tranché
const TO_PROVE := "to_prove"      ## tranché, mais la contradiction a un prix à payer
const SETTLED := "settled"        ## contradiction établie


static func has_sheet(case_data: Dictionary) -> bool:
	return not case_data.get("questions", []).is_empty()


static func get_question(case_data: Dictionary, question_id: String) -> Dictionary:
	for question in case_data.get("questions", []):
		if question.get("id", "") == question_id:
			return question
	return {}


## Question sous laquelle se range un élément, ou "" s'il n'en a pas.
static func question_of_fact(case_data: Dictionary, fact_id: String) -> String:
	var key: String = CaseLibrary.get_fact(case_data, fact_id).get("key", "")
	if key == "":
		return ""
	for question in case_data.get("questions", []):
		if key in question.get("keys", []):
			return question.get("id", "")
	return ""


## La fiche complète, dans l'ordre du dossier. Chaque question :
##   {id, text, state, answers: [{fact_id, label, document_title, reliability}],
##    conflict: [fact_a, fact_b] ou [], key: clé du conflit ou "", retained: fact_id ou ""}
## case_state : état du dossier (noted_facts, contradictions_found,
## contradictions_noticed, sheet_choices).
static func build(case_data: Dictionary, case_state: Dictionary) -> Array:
	var noted: Array = case_state.get("noted_facts", [])
	var found: Array = case_state.get("contradictions_found", [])
	var noticed: Array = case_state.get("contradictions_noticed", [])
	var choices: Dictionary = case_state.get("sheet_choices", {})
	var sheet := []
	for question in case_data.get("questions", []):
		var keys: Array = question.get("keys", [])
		var answers := []
		for fact_id in noted:
			var fact := CaseLibrary.get_fact(case_data, fact_id)
			if fact.is_empty() or not fact.get("key", "") in keys:
				continue
			var document := CaseLibrary.get_document(case_data, fact.document_id)
			answers.append({"fact_id": fact_id, "label": fact.get("label", fact_id),
					"key": fact.key, "value": fact.get("value", ""),
					"document_title": document.get("title", ""),
					"reliability": document.get("reliability", "")})
		var conflict := _first_conflict(answers)
		var conflict_key: String = conflict[2] if not conflict.is_empty() else ""
		var state := OPEN
		if conflict_key != "":
			if conflict_key in found:
				state = SETTLED
			elif conflict_key in noticed:
				state = TO_PROVE
			else:
				state = CONFLICT
		elif not answers.is_empty():
			state = ANSWERED
		elif not question.get("main", false):
			state = HIDDEN
		sheet.append({"id": question.get("id", ""), "text": question.get("text", ""), "state": state,
				"answers": answers, "conflict": conflict.slice(0, 2), "key": conflict_key,
				"retained": choices.get(question.get("id", ""), "")})
	return sheet


## Liens visibles entre les pièces : pour chaque élément noté dans cette pièce,
## les autres pièces visibles qui parlent du même sujet (même clé, rattachée à une
## question). On ne montre un lien qu'à partir de ce que l'agent a déjà relevé :
## le jeu indique où regarder, jamais qui ment.
## Renvoie [{document_id, title, question}] sans doublon, dans l'ordre des pièces.
static func links(case_data: Dictionary, case_state: Dictionary, document_id: String) -> Array:
	var keys := {}
	for fact_id in case_state.get("noted_facts", []):
		var fact := CaseLibrary.get_fact(case_data, fact_id)
		if fact.get("document_id", "") == document_id and fact.get("key", "") != "":
			keys[fact.key] = true
	var result := []
	var seen := {}
	for document in case_data.get("documents", []):
		if document.get("id", "") == document_id:
			continue
		for fact in document.get("facts", []):
			var key: String = fact.get("key", "")
			if not keys.has(key):
				continue
			var question := _question_for_key(case_data, key)
			if question.is_empty():
				continue
			var tag := "%s|%s" % [document.id, question.id]
			if seen.has(tag):
				continue
			seen[tag] = true
			result.append({"document_id": document.id, "title": document.get("title", ""),
					"question": question.get("text", "")})
	return result


static func _question_for_key(case_data: Dictionary, key: String) -> Dictionary:
	for question in case_data.get("questions", []):
		if key in question.get("keys", []):
			return question
	return {}


## Questions où l'agent a retenu une version que les données savent fausse.
static func wrong_versions(case_data: Dictionary, case_state: Dictionary) -> Array:
	var wrong := []
	for question in build(case_data, case_state):
		var truth: Array = get_question(case_data, question.id).get("truth", [])
		if truth.is_empty() or question.retained == "":
			continue
		for answer in question.answers:
			if answer.fact_id == question.retained and not answer.value in truth:
				wrong.append(question.id)
	return wrong


## Première paire d'éléments qui se contredisent : [fact_a, fact_b, clé] ou [].
static func _first_conflict(answers: Array) -> Array:
	for i in answers.size():
		for j in range(i + 1, answers.size()):
			if answers[i].key == answers[j].key and answers[i].value != answers[j].value:
				return [answers[i].fact_id, answers[j].fact_id, answers[i].key]
	return []


## Première question qui attend que le joueur tranche (ou paie la preuve), ou {}.
static func pending_conflict(sheet: Array) -> Dictionary:
	for question in sheet:
		if question.state in [CONFLICT, TO_PROVE]:
			return question
	return {}


## Nombre de questions encore cachées.
static func hidden_count(sheet: Array) -> int:
	return sheet.filter(func(q: Dictionary) -> bool: return q.state == HIDDEN).size()


## Éléments notés qui ne répondent à aucune question (« autres notes »).
static func loose_facts(case_data: Dictionary, noted: Array) -> Array:
	return noted.filter(func(fact_id: String) -> bool: return question_of_fact(case_data, fact_id) == "")


## Vérifie le bloc "questions" d'un dossier : identifiants uniques, texte, clés
## existantes, une clé par question au plus. Comme la fiche ne montre qu'un conflit
## par question, une question ne porte qu'une clé contradictoire ; et toute clé
## contradictoire a sa question (sinon cette contradiction serait introuvable au
## niveau débutant). Renvoie la liste des problèmes (vide si tout va bien).
static func validate(case_data: Dictionary) -> Array[String]:
	var problems: Array[String] = []
	var known_keys := {}
	for document in case_data.get("documents", []):
		for fact in document.get("facts", []):
			known_keys[fact.get("key", "")] = true
	var seen := {}
	var claimed := {}
	for question in case_data.get("questions", []):
		var qid: String = question.get("id", "")
		if qid == "" or seen.has(qid):
			problems.append("question sans identifiant ou en double : %s" % qid)
		seen[qid] = true
		if question.get("text", "") == "":
			problems.append("question %s sans texte" % qid)
		if question.get("keys", []).is_empty():
			problems.append("question %s sans clé" % qid)
		for value in question.get("truth", []):
			if not _has_value(case_data, question.get("keys", []), value):
				problems.append("question %s : valeur vraie inconnue %s" % [qid, value])
		for key in question.get("keys", []):
			if not known_keys.has(key):
				problems.append("question %s : clé inconnue %s" % [qid, key])
			if claimed.has(key):
				problems.append("clé %s rangée sous deux questions" % key)
			claimed[key] = true
	if not has_sheet(case_data):
		return problems
	var conflicting := CaseLibrary.find_contradictions(case_data).map(func(c: Dictionary) -> String: return c.key)
	for question in case_data.get("questions", []):
		var count := 0
		for key in question.get("keys", []):
			if key in conflicting:
				count += 1
		if count > 1:
			problems.append("question %s : plusieurs clés contradictoires" % question.get("id", ""))
	for key in conflicting:
		if not claimed.has(key):
			problems.append("clé contradictoire %s sans question" % key)
	return problems


static func _has_value(case_data: Dictionary, keys: Array, value: String) -> bool:
	for document in case_data.get("documents", []):
		for fact in document.get("facts", []):
			if fact.get("key", "") in keys and fact.get("value", "") == value:
				return true
	return false
