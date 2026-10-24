extends Node
## État de la partie en cours : source unique de vérité pour tout ce qui est sauvegardé.
##
## L'interface lit cet état et écoute ses signaux, mais ne le stocke jamais elle-même.
## Toute modification passe par les méthodes ci-dessous, qui émettent state_changed.

signal state_changed

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

var player: Dictionary = {}
var day_index: int = 0
var indicators: Dictionary = {}
## case_id -> {status, viewed_documents: Array, decision: String}
var cases: Dictionary = {}
## Messages reçus : {id, from, subject, date_label, body, read}
var messages: Array = []
## Historique des décisions prises : {case_id, decision_id, day_index}
var decisions: Array = []
## Drapeaux narratifs libres (conséquences persistantes).
var flags: Dictionary = {}


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
	# Un dossier ajouté au jeu après la sauvegarde doit quand même apparaître.
	for case_id in CaseLibrary.get_case_ids():
		if not cases.has(case_id):
			cases[case_id] = _new_case_state()
	messages = data.get("messages", [])
	decisions = data.get("decisions", [])
	flags = data.get("flags", {})
	state_changed.emit()


func _new_case_state() -> Dictionary:
	return {"status": CASE_OPEN, "viewed_documents": [], "decision": ""}
