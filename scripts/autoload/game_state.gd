extends Node
## État de la partie en cours : source unique de vérité pour tout ce qui est sauvegardé.
##
## L'interface lit cet état et écoute ses signaux, mais ne le stocke jamais elle-même.
## Toute modification passe par les méthodes ci-dessous, qui émettent state_changed.

signal state_changed
## Émis après une décision : le bureau s'en sert pour afficher la réponse du supérieur.
signal decision_applied(case_id: String, decision_id: String, message_id: String)
## Émis au début d'une nouvelle journée, avec les événements qui se sont déclenchés.
signal day_started(day_index: int, events: Array)

const INITIAL_MESSAGES_PATH := "res://data/messages/initial_messages.json"

const INDICATOR_MIN := 0
const INDICATOR_MAX := 100
## Indicateurs internes (0-100), non affichés directement au joueur :
## - loyalty    : loyauté perçue envers le régime.
## - suspicion  : méfiance de la hiérarchie envers le joueur.
## - influence  : poids institutionnel du joueur.
const INITIAL_INDICATORS := {"loyalty": 50, "suspicion": 20, "influence": 10}

## Statuts possibles d'un dossier dans la partie.
const CASE_OPEN := "open"
const CASE_CLOSED := "closed"
const CASE_UNDER_INVESTIGATION := "under_investigation"

var player: Dictionary = {}
var day_index: int = 0
var indicators: Dictionary = {}
## case_id -> {status, viewed_documents, noted_facts, contradictions_found, decision}
var cases: Dictionary = {}
## Messages reçus : {id, from, subject, date_label, body, read}
var messages: Array = []
## Historique des décisions prises : {case_id, decision_id, day_index}
var decisions: Array = []
## Drapeaux narratifs libres (conséquences persistantes).
var flags: Dictionary = {}
## Identifiants des événements différés déjà déclenchés.
var fired_events: Array = []


func _ready() -> void:
	new_game()


## Réinitialise complètement l'état pour une nouvelle partie.
func new_game() -> void:
	player = {
		"name": "A. VOSK",
		"badge": "INS-7734",
		"rank": Career.Rank.INSPECTOR,
	}
	day_index = 0
	indicators = INITIAL_INDICATORS.duplicate()
	cases = {}
	for case_id in CaseLibrary.get_case_ids():
		cases[case_id] = _new_case_state()
	messages = []
	for message in DataLoader.load_json(INITIAL_MESSAGES_PATH).get("messages", []):
		receive_message(message, false)
	decisions = []
	flags = {}
	fired_events = []
	state_changed.emit()


func get_rank_title() -> String:
	return Career.rank_title(player.get("rank", Career.Rank.INSPECTOR))


func get_date_long() -> String:
	return FictionalCalendar.format_long(day_index)


func get_date_short() -> String:
	return FictionalCalendar.format_short(day_index)


# --- Indicateurs -------------------------------------------------------------

func get_indicator(indicator: String) -> int:
	return indicators.get(indicator, 0)


## Modifie un indicateur en restant dans les bornes [INDICATOR_MIN, INDICATOR_MAX].
func adjust_indicator(indicator: String, delta: int) -> void:
	if not indicators.has(indicator):
		push_error("GameState: indicateur inconnu : %s" % indicator)
		return
	indicators[indicator] = clampi(indicators[indicator] + delta, INDICATOR_MIN, INDICATOR_MAX)
	state_changed.emit()


# --- Dossiers ----------------------------------------------------------------

func get_case_state(case_id: String) -> Dictionary:
	if not cases.has(case_id):
		cases[case_id] = _new_case_state()
	return cases[case_id]


## Mémorise qu'un document a été consulté (servira aux preuves et à VERITAS).
func mark_document_viewed(case_id: String, document_id: String) -> void:
	var case_state := get_case_state(case_id)
	if document_id in case_state.viewed_documents:
		return
	case_state.viewed_documents.append(document_id)
	state_changed.emit()


func is_document_viewed(case_id: String, document_id: String) -> bool:
	return document_id in get_case_state(case_id).viewed_documents


## Ajoute un élément notable au carnet d'enquête du dossier.
func note_fact(case_id: String, fact_id: String) -> void:
	var case_state := get_case_state(case_id)
	if fact_id in case_state.noted_facts:
		return
	case_state.noted_facts.append(fact_id)
	state_changed.emit()


## Confronte deux éléments notés. Enregistre la contradiction si elle existe.
## Renvoie la clé contredite, ou "" si les éléments ne se contredisent pas.
func confront_facts(case_id: String, fact_a_id: String, fact_b_id: String) -> String:
	var key := CaseLibrary.confront(CaseLibrary.get_case(case_id), fact_a_id, fact_b_id)
	var case_state := get_case_state(case_id)
	if key != "" and not key in case_state.contradictions_found:
		case_state.contradictions_found.append(key)
		state_changed.emit()
	return key


func can_decide(case_id: String) -> bool:
	return get_case_state(case_id).decision == ""


## Applique une décision : indicateurs, statut, drapeaux, historique, message du supérieur.
## Renvoie le résultat de DecisionRules.resolve(), ou {} si la décision est impossible.
func apply_decision(case_id: String, decision_id: String) -> Dictionary:
	if not can_decide(case_id):
		push_warning("GameState: le dossier %s a déjà fait l'objet d'une décision." % case_id)
		return {}
	var case_state := get_case_state(case_id)
	var result := DecisionRules.resolve(CaseLibrary.get_case(case_id), case_state, decision_id)
	if result.is_empty():
		push_error("GameState: décision inconnue %s pour le dossier %s" % [decision_id, case_id])
		return {}
	for indicator in result.effects:
		indicators[indicator] = clampi(indicators.get(indicator, 0) + int(result.effects[indicator]),
				INDICATOR_MIN, INDICATOR_MAX)
	case_state.status = result.status_after
	case_state.decision = decision_id
	flags.merge(result.flags, true)
	# On garde la trace de l'accord avec VERITAS : le système s'en souviendra.
	var advice := Veritas.recommendation(CaseLibrary.get_case(case_id))
	decisions.append({"case_id": case_id, "decision_id": decision_id, "day_index": day_index,
			"outcome": result.response_id, "veritas_agreed": advice.get("decision_id", "") == decision_id})
	var message_id := "%s.%s" % [case_id, result.response_id]
	if not result.response.is_empty():
		var message: Dictionary = result.response.duplicate()
		message["id"] = message_id
		message["date_label"] = get_date_short()
		receive_message(message, false)
	state_changed.emit()
	decision_applied.emit(case_id, decision_id, message_id)
	return result


# --- Messages ----------------------------------------------------------------

func receive_message(message: Dictionary, notify := true) -> void:
	var entry := message.duplicate()
	entry["read"] = false
	messages.append(entry)
	if notify:
		state_changed.emit()


func mark_message_read(message_id: String) -> void:
	for message in messages:
		if message.id == message_id and not message.read:
			message.read = true
			state_changed.emit()
			return


func get_unread_count() -> int:
	var count := 0
	for message in messages:
		if not message.read:
			count += 1
	return count


# --- Journées -------------------------------------------------------------

## Termine la journée : passe au jour suivant et applique les événements dus.
## Renvoie la liste des événements déclenchés.
func end_day() -> Array:
	day_index += 1
	var fired := EventRules.due_events({
		"day_index": day_index, "flags": flags, "cases": cases, "fired_events": fired_events})
	for event in fired:
		for indicator in event.get("effects", {}):
			indicators[indicator] = clampi(indicators.get(indicator, 0) + int(event.effects[indicator]),
					INDICATOR_MIN, INDICATOR_MAX)
		flags.merge(event.get("set_flags", {}), true)
		if event.has("message"):
			var message: Dictionary = event.message.duplicate()
			message["id"] = "event.%s.%d" % [event.id, day_index]
			message["date_label"] = get_date_short()
			receive_message(message, false)
		if not event.id in fired_events:
			fired_events.append(event.id)
	state_changed.emit()
	day_started.emit(day_index, fired)
	return fired


# --- Sérialisation (utilisée par SaveManager) ---------------------------------

func to_dict() -> Dictionary:
	return {
		"player": player.duplicate(true),
		"day_index": day_index,
		"indicators": indicators.duplicate(),
		"cases": cases.duplicate(true),
		"messages": messages.duplicate(true),
		"decisions": decisions.duplicate(true),
		"flags": flags.duplicate(true),
		"fired_events": fired_events.duplicate(),
	}


func from_dict(data: Dictionary) -> void:
	player = data.get("player", {})
	# JSON ne distingue pas entiers et flottants : on reconvertit les nombres.
	player["rank"] = int(player.get("rank", Career.Rank.INSPECTOR))
	day_index = int(data.get("day_index", 0))
	indicators = INITIAL_INDICATORS.duplicate()
	for key in data.get("indicators", {}):
		indicators[key] = int(data.indicators[key])
	cases = data.get("cases", {})
	for case_id in cases:
		# Complète les champs ajoutés au format après la création de la sauvegarde.
		var defaults := _new_case_state()
		defaults.merge(cases[case_id], true)
		cases[case_id] = defaults
	# Un dossier ajouté au jeu après la sauvegarde doit quand même apparaître.
	for case_id in CaseLibrary.get_case_ids():
		if not cases.has(case_id):
			cases[case_id] = _new_case_state()
	messages = data.get("messages", [])
	decisions = data.get("decisions", [])
	flags = data.get("flags", {})
	fired_events = data.get("fired_events", [])
	state_changed.emit()


func _new_case_state() -> Dictionary:
	return {"status": CASE_OPEN, "viewed_documents": [], "noted_facts": [],
			"contradictions_found": [], "decision": ""}
