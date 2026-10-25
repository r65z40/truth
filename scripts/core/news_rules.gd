class_name NewsRules
extends RefCounted
## Journal du matin (logique pure) : choisit les articles de l'édition du jour
## dans data/news.json. Les titres sont écrits à la main ; le moteur ne fait
## que choisir, selon le jour, les drapeaux et les décisions de la veille.
##
## Conditions : celles de MusicRules (jour, acte, drapeaux, indicateurs), plus
## - day            : jour exact (day_index) de parution ;
## - after_decision : {"case": id, "decisions": [ids]} : décision prise la veille
##                    sur ce dossier (liste vide ou absente : n'importe laquelle).

const NEWS_PATH := "res://data/news.json"
## Nombre d'articles d'une édition.
const MAX_ARTICLES := 3

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		_data = DataLoader.load_json(NEWS_PATH)
	return _data


## Édition du jour : {number, masthead, tagline, articles (au plus MAX_ARTICLES,
## le premier est la une)}. state : GameState.get_condition_state() avec
## « decisions » (GameState.decisions) et « indicators ».
static func edition(state: Dictionary, articles: Array = data().get("articles", [])) -> Dictionary:
	var matching: Array = []
	for i in articles.size():
		if are_conditions_met(articles[i].get("conditions", {}), state):
			matching.append({"order": i, "article": articles[i]})
	# Priorité décroissante, puis ordre du fichier : le choix est toujours le même.
	matching.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var pa := int(a.article.get("priority", 0))
		var pb := int(b.article.get("priority", 0))
		return pa > pb if pa != pb else a.order < b.order)
	var chosen: Array = []
	for entry in matching.slice(0, MAX_ARTICLES):
		chosen.append(entry.article)
	return {
		"number": int(data().get("first_number", 1)) + int(state.get("day_index", 0)),
		"masthead": data().get("masthead", ""),
		"tagline": data().get("tagline", ""),
		"articles": chosen,
	}


static func are_conditions_met(conditions: Dictionary, state: Dictionary) -> bool:
	var day := int(state.get("day_index", 0))
	if conditions.has("day") and int(conditions.day) != day:
		return false
	if conditions.has("after_decision") and not _decided_yesterday(conditions.after_decision, state):
		return false
	return MusicRules.are_conditions_met(conditions, state)


static func _decided_yesterday(condition: Dictionary, state: Dictionary) -> bool:
	var wanted: Array = condition.get("decisions", [])
	for decision in state.get("decisions", []):
		if decision.get("case_id", "") != condition.get("case", ""):
			continue
		if int(decision.get("day_index", -1)) != int(state.get("day_index", 0)) - 1:
			continue
		if wanted.is_empty() or decision.get("decision_id", "") in wanted:
			return true
	return false
