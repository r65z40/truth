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
## Profil du personnage joué et identifiant de la campagne.
const CAMPAIGN_PATH := "res://data/campaign.json"

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
## Heures de service déjà employées aujourd'hui (voir WorkTime).
var hours_used: int = 0
## Journées où l'agent a fait des heures supplémentaires (soirée perdue).
var overtime_days: Array = []
## Soirées passées : {"<jour>": {"action": id, "kind": kind}} (voir EveningRules).
var evenings: Dictionary = {}
## Scènes de terrain commencées : {"<scène>": {turns_used, chosen, finished}} (voir FieldRules).
var field_scenes: Dictionary = {}
## Mémoire institutionnelle : dossier administratif secret nourri par les actions de
## l'agent, {jour, tag, reading} (voir MinistryRecord). Graine du dossier 54100.
var ministry_record: Array = []


func _ready() -> void:
	new_game()


## Réinitialise complètement l'état pour une nouvelle partie.
func new_game() -> void:
	var campaign := DataLoader.load_json(CAMPAIGN_PATH)
	player = campaign.get("player", {}).duplicate()
	player["campaign"] = campaign.get("id", "vosk")
	player["rank"] = Career.Rank.INSPECTOR
	day_index = 0
	indicators = INITIAL_INDICATORS.duplicate()
	cases = {}
	for case_id in CaseLibrary.get_starting_case_ids():
		cases[case_id] = _new_case_state()
	messages = []
	for message in DataLoader.load_json(INITIAL_MESSAGES_PATH).get("messages", []):
		receive_message(message, false)
	decisions = []
	flags = {}
	fired_events = []
	hours_used = 0
	overtime_days = []
	evenings = {}
	field_scenes = {}
	ministry_record = []
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

## Attribue un dossier au joueur (sans effet s'il l'a déjà).
func assign_case(case_id: String) -> void:
	if cases.has(case_id):
		return
	if CaseLibrary.get_case(case_id).is_empty():
		push_error("GameState: dossier inconnu : %s" % case_id)
		return
	cases[case_id] = _new_case_state()
	state_changed.emit()


## État minimal utilisé pour évaluer des conditions (événements, pièces).
func get_condition_state() -> Dictionary:
	return {"day_index": day_index, "flags": flags, "cases": cases, "fired_events": fired_events,
			"evening_counts": EveningRules.counts(evenings)}


## Le dossier tel que le joueur le voit : seulement les pièces disponibles.
func get_case_view(case_id: String) -> Dictionary:
	return CaseLibrary.filter_case(CaseLibrary.get_case(case_id), get_condition_state())


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


## Fonction débloquée à ce stade de la partie (voir Features).
func is_feature_unlocked(feature: String) -> bool:
	return Features.is_unlocked(feature, get_condition_state())


# --- Horloge de service ------------------------------------------------------

func get_clock_text() -> String:
	return WorkTime.clock_text(hours_used)


## Dépense les heures d'une action si possible. Renvoie false si la journée ne le
## permet plus. Les heures supplémentaires sont notées pour la soirée.
func spend_time(action: String) -> bool:
	if not WorkTime.check(hours_used, action).ok:
		return false
	hours_used += WorkTime.cost(action)
	if WorkTime.is_overtime(hours_used) and not day_index in overtime_days:
		overtime_days.append(day_index)
	state_changed.emit()
	return true


func is_overtime_today() -> bool:
	return day_index in overtime_days


## Demande une pièce complémentaire (livrée le lendemain). Renvoie false si
## impossible : pièce inconnue, déjà demandée, ou plus assez de temps.
func request_document(case_id: String, document_id: String) -> bool:
	var document := CaseLibrary.get_document(CaseLibrary.get_case(case_id), document_id)
	var case_state := get_case_state(case_id)
	if not document.has("request") or case_state.requested_documents.has(document_id) \
			or not is_feature_unlocked("request_document"):
		return false
	if not spend_time("request_document"):
		return false
	case_state.requested_documents[document_id] = day_index
	var request: Dictionary = document.request
	_merge_flags(request.get("flags", {}))
	for indicator in request.get("effects", {}):
		indicators[indicator] = clampi(indicators.get(indicator, 0) + int(request.effects[indicator]),
				INDICATOR_MIN, INDICATOR_MAX)
	state_changed.emit()
	return true


## Pièces que l'agent peut encore demander pour ce dossier.
func get_requestable_documents(case_id: String) -> Array:
	var case_state := get_case_state(case_id)
	var result := []
	for document in CaseLibrary.get_case(case_id).get("documents", []):
		if document.has("request") and not case_state.requested_documents.has(document.id) \
				and EventRules.are_conditions_met(document.get("conditions", {}), get_condition_state()):
			result.append(document)
	return result


## Consulte le supérieur sur un dossier (une fois par dossier) : message de conseil.
func consult_superior(case_id: String) -> bool:
	var consultation: Dictionary = CaseLibrary.get_case(case_id).get("consultation", {})
	var case_state := get_case_state(case_id)
	if consultation.is_empty() or case_state.consulted or not can_decide(case_id) \
			or not is_feature_unlocked("consult_superior"):
		return false
	if not spend_time("consult_superior"):
		return false
	case_state.consulted = true
	_set_flag("%s.consulted_superior" % case_id, true)
	var message := consultation.duplicate()
	message["id"] = "%s.consultation" % case_id
	message["date_label"] = get_date_short()
	receive_message(message, false)
	state_changed.emit()
	return true


func can_decide(case_id: String) -> bool:
	return get_case_state(case_id).decision == ""


## Nombre de dossiers déjà conclus (avec décision signée). Sert à estomper
## l'aide pas à pas une fois que le joueur a pris la main.
func concluded_case_count() -> int:
	var count := 0
	for case_id in cases:
		if get_case_state(case_id).decision != "":
			count += 1
	return count


## Applique une décision : indicateurs, statut, drapeaux, historique, message du supérieur.
## Renvoie le résultat de DecisionRules.resolve(), ou {} si la décision est impossible.
func apply_decision(case_id: String, decision_id: String) -> Dictionary:
	if not can_decide(case_id):
		push_warning("GameState: le dossier %s a déjà fait l'objet d'une décision." % case_id)
		return {}
	var case_state := get_case_state(case_id)
	# Signer reste toujours possible ; l'heure n'est comptée que s'il en reste.
	if WorkTime.check(hours_used, "sign_conclusion").ok:
		hours_used += WorkTime.cost("sign_conclusion")
		if WorkTime.is_overtime(hours_used) and not day_index in overtime_days:
			overtime_days.append(day_index)
	# Avis de VERITAS sur le dossier tel que l'agent l'a vu, avant la décision.
	var advice := Veritas.recommendation(get_case_view(case_id), case_state, flags)
	var result := DecisionRules.resolve(CaseLibrary.get_case(case_id), case_state, decision_id)
	if result.is_empty():
		push_error("GameState: décision inconnue %s pour le dossier %s" % [decision_id, case_id])
		return {}
	for indicator in result.effects:
		indicators[indicator] = clampi(indicators.get(indicator, 0) + int(result.effects[indicator]),
				INDICATOR_MIN, INDICATOR_MAX)
	case_state.status = result.status_after
	case_state.decision = decision_id
	_merge_flags(result.flags)
	# On garde la trace de l'accord avec VERITAS : le système s'en souviendra.
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


# --- Terrain : interrogatoires et perquisitions ------------------------------

## Scène de terrain du dossier, ou {}.
func get_field_scene(case_id: String) -> Dictionary:
	return FieldRules.scene_for_case(CaseLibrary.get_case(case_id))


func get_field_state(scene_id: String) -> Dictionary:
	return field_scenes.get(scene_id, {})


## Vrai si la scène du dossier peut commencer maintenant (sans compter les heures).
func can_start_field(case_id: String) -> bool:
	var scene := get_field_scene(case_id)
	return is_feature_unlocked("field_work") \
			and FieldRules.is_available(scene, get_field_state(scene.get("id", "")), get_condition_state())


## Commence la scène de terrain du dossier (coûte ses heures). Renvoie la scène, ou {}.
func start_field(case_id: String) -> Dictionary:
	var scene := get_field_scene(case_id)
	if not can_start_field(case_id) or not spend_time(scene.get("time_action", "interrogate")):
		return {}
	field_scenes[scene.id] = {"turns_used": 0, "chosen": [], "finished": false}
	_set_flag(FieldRules.flag_for(scene, "started"), true)
	_merge_flags(scene.get("start_flags", {}))
	_apply_effects(scene.get("start_effects", {}))
	state_changed.emit()
	return scene


## Choix encore possibles dans la scène en cours.
func get_field_options(scene_id: String) -> Array:
	var scene := FieldRules.get_scene(scene_id)
	return FieldRules.available_options(scene, get_field_state(scene_id), get_condition_state(),
			get_case_state(scene.get("case_id", "")).noted_facts)


## Pose une question ou fouille un endroit. Renvoie {text, noted, finished}, ou {}.
func field_choose(scene_id: String, option_id: String) -> Dictionary:
	if not get_field_options(scene_id).any(func(o: Dictionary) -> bool: return o.id == option_id):
		return {}
	var scene := FieldRules.get_scene(scene_id)
	return _apply_field_result(scene, FieldRules.get_option(scene, option_id))


## Présente un élément du carnet au sujet (interrogatoire). Renvoie {text, noted, finished}, ou {}.
func field_present(scene_id: String, fact_id: String) -> Dictionary:
	var scene := FieldRules.get_scene(scene_id)
	var scene_state := get_field_state(scene_id)
	var case_id: String = scene.get("case_id", "")
	if scene_state.is_empty() or scene_state.finished or FieldRules.turns_left(scene, scene_state) == 0 \
			or not fact_id in get_case_state(case_id).noted_facts:
		return {}
	return _apply_field_result(scene, FieldRules.presentation_for(scene, scene_state, fact_id))


## Quitte la scène avant la fin des tours. Renvoie le texte de sortie.
func field_leave(scene_id: String) -> String:
	var scene_state := get_field_state(scene_id)
	if scene_state.is_empty():
		return ""
	scene_state.finished = true
	state_changed.emit()
	return FieldRules.get_scene(scene_id).get("outro", "")


func _apply_field_result(scene: Dictionary, result: Dictionary) -> Dictionary:
	var scene_state: Dictionary = field_scenes[scene.id]
	scene_state.turns_used += 1
	if result.get("id", "") != "":
		scene_state.chosen.append(result.id)
		_set_flag(FieldRules.flag_for(scene, result.id), true)
	_merge_flags(result.get("set_flags", {}))
	_apply_effects(result.get("effects", {}))
	# Les éléments obtenus vont directement dans le carnet.
	var noted: Array = []
	for fact_id in result.get("note", []):
		note_fact(scene.case_id, fact_id)
		noted.append(CaseLibrary.get_fact(CaseLibrary.get_case(scene.case_id), fact_id).get("label", fact_id))
	if result.get("ends", false) or FieldRules.turns_left(scene, scene_state) == 0:
		scene_state.finished = true
	state_changed.emit()
	return {"text": result.get("text", ""), "noted": noted, "finished": scene_state.finished}


# --- Soirées -----------------------------------------------------------------

## Soirée prévue ce soir, ou {} s'il n'y en a pas.
func get_evening() -> Dictionary:
	return EveningRules.evening_for_day(day_index)


## Vrai si une soirée est prévue ce soir et n'a pas encore eu lieu.
func has_evening_pending() -> bool:
	return not get_evening().is_empty() and not evenings.has(str(day_index))


func get_evening_actions() -> Array:
	return EveningRules.available_actions(get_evening(), get_condition_state())


## Passe la soirée à l'action donnée. Renvoie {text, effects, set_flags},
## ou {} si l'action n'est pas proposée ce soir.
func choose_evening_action(action_id: String) -> Dictionary:
	if not has_evening_pending() or is_overtime_today():
		return {}
	var evening := get_evening()
	var action := EveningRules.get_action(evening, action_id)
	if action.is_empty() or not get_evening_actions().any(func(a: Dictionary) -> bool: return a.id == action_id):
		return {}
	_merge_flags(evening.get("set_flags", {}))
	var result := EveningRules.resolve(action, get_condition_state())
	_apply_effects(result.effects)
	_merge_flags(result.set_flags)
	evenings[str(day_index)] = {"action": action_id, "kind": action.get("kind", "")}
	state_changed.emit()
	return result


## Soirée perdue après des heures supplémentaires. Renvoie le texte à afficher.
func lose_evening() -> String:
	if not has_evening_pending():
		return ""
	var overtime: Dictionary = EveningRules.get_data().get("overtime", {})
	_merge_flags(get_evening().get("set_flags", {}))
	_merge_flags(overtime.get("set_flags", {}))
	evenings[str(day_index)] = {"action": "", "kind": ""}
	state_changed.emit()
	return overtime.get("text", "")


func _apply_effects(effects: Dictionary) -> void:
	for indicator in effects:
		indicators[indicator] = clampi(indicators.get(indicator, 0) + int(effects[indicator]),
				INDICATOR_MIN, INDICATOR_MAX)


# --- Fin d'acte ---------------------------------------------------------------

## Revue du dernier soir d'un acte : archive des sujets et commission
## d'avancement. Renvoie {} si ce soir n'est pas une fin d'acte à examiner.
func get_act_review() -> Dictionary:
	var act := FictionalCalendar.act_for_day(day_index)
	if act.is_empty() or FictionalCalendar.act_for_day(day_index + 1).get("number") == act.number:
		return {}
	var rules := Career.act_rules(int(act.number))
	if rules.is_empty() or flags.get("act%d.reviewed" % int(act.number)) == true:
		return {}
	var subjects := []
	for case_id in rules.cases:
		var case_data := CaseLibrary.get_case(case_id)
		var decision_id: String = cases.get(case_id, {}).get("decision", "")
		var entry := {"case_id": case_id, "name": case_data.get("subject_name", case_id),
				"decision": "Sans conclusion", "text": "Dossier réattribué à un autre inspecteur."}
		for decision in case_data.get("decisions", []):
			if decision.id == decision_id:
				entry.decision = decision.label
				entry.text = decision.get("archive", "")
				var truth: Dictionary = decision.get("archive_truth", {})
				if not truth.is_empty() and EventRules.are_conditions_met(truth, get_condition_state()):
					entry.text += " " + truth.text
		subjects.append(entry)
	var evaluation := Career.evaluate(rules, {"indicators": indicators, "flags": flags, "cases": cases})
	var letter: String = rules.denied
	if evaluation.eligible:
		letter = rules.offer_bought if evaluation.bought else rules.offer
	return {"act": int(act.number), "title": act.title, "subjects": subjects, "evaluation": evaluation,
			"letter": letter, "target_rank": Career.rank_title(int(rules.to_rank)),
			"unlocks": rules.get("unlocks", "")}


func has_act_review_pending() -> bool:
	return not get_act_review().is_empty()


## Clôt la revue de fin d'acte. accept : le joueur accepte la promotion
## proposée (ignoré si elle ne l'est pas). Renvoie le texte de conclusion.
func complete_act_review(accept: bool) -> String:
	var review := get_act_review()
	if review.is_empty():
		return ""
	var rules := Career.act_rules(review.act)
	var prefix := "career.act%d" % review.act
	_set_flag("act%d.reviewed" % review.act, true)
	var text := ""
	if not review.evaluation.eligible:
		_set_flag(prefix + "_denied", true)
	elif accept:
		player["rank"] = int(rules.to_rank)
		_set_flag(prefix + "_promoted", true)
		if review.evaluation.bought:
			_set_flag("career.promotion_bought", true)
		text = rules.accepted
	else:
		_set_flag(prefix + "_refused", true)
		_set_flag("career.refused_promotion", true)
		text = rules.refused
	state_changed.emit()
	return text


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
	hours_used = 0
	var fired := EventRules.due_events(get_condition_state())
	for event in fired:
		for case_id in event.get("assign_cases", []):
			assign_case(case_id)
		for indicator in event.get("effects", {}):
			indicators[indicator] = clampi(indicators.get(indicator, 0) + int(event.effects[indicator]),
					INDICATOR_MIN, INDICATOR_MAX)
		_merge_flags(event.get("set_flags", {}))
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

## Pose un drapeau et, s'il est suivi, enrichit la mémoire institutionnelle.
func _set_flag(key: String, value: Variant) -> void:
	flags[key] = value
	if value == true:
		_record_ministry(key)


## Fusionne des drapeaux (écrase les existants) et met à jour la mémoire.
func _merge_flags(new_flags: Dictionary) -> void:
	flags.merge(new_flags, true)
	for key in new_flags:
		if new_flags[key] == true:
			_record_ministry(key)


## Ajoute une entrée à la mémoire institutionnelle si ce drapeau y est associé et
## que le fait n'a pas déjà été consigné (un même "tag" n'est noté qu'une fois).
func _record_ministry(flag: String) -> void:
	var rule := MinistryRecord.rule_for(flag)
	if rule.is_empty():
		return
	var tag: String = rule.get("tag", flag)
	for entry in ministry_record:
		if entry.get("tag", "") == tag:
			return
	ministry_record.append({"day": day_index, "tag": tag, "reading": rule.get("reading", "")})


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
		"hours_used": hours_used,
		"overtime_days": overtime_days.duplicate(),
		"evenings": evenings.duplicate(true),
		"field_scenes": field_scenes.duplicate(true),
		"ministry_record": ministry_record.duplicate(true),
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
	# Un dossier de départ ajouté au jeu après la sauvegarde doit quand même apparaître.
	for case_id in CaseLibrary.get_starting_case_ids():
		if not cases.has(case_id):
			cases[case_id] = _new_case_state()
	messages = data.get("messages", [])
	decisions = data.get("decisions", [])
	flags = data.get("flags", {})
	fired_events = data.get("fired_events", [])
	hours_used = int(data.get("hours_used", 0))
	overtime_days = data.get("overtime_days", []).map(func(day) -> int: return int(day))
	evenings = data.get("evenings", {})
	field_scenes = data.get("field_scenes", {})
	for scene_state: Dictionary in field_scenes.values():
		scene_state["turns_used"] = int(scene_state.get("turns_used", 0))
	ministry_record = data.get("ministry_record", [])
	for entry: Dictionary in ministry_record:
		entry["day"] = int(entry.get("day", 0))
	state_changed.emit()


func _new_case_state() -> Dictionary:
	return {"status": CASE_OPEN, "viewed_documents": [], "noted_facts": [],
			"contradictions_found": [], "decision": "", "requested_documents": {}, "consulted": false}
