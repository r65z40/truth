extends Node
## Tests automatiques du projet, exécutables sans interface :
##   godot --headless --path . res://tests/test_runner.tscn
## (scène plutôt que script -s, pour que les autoloads soient chargés).
## Code de sortie : 0 si tout passe, 1 sinon.
##
## Couvre la logique (données, état, sauvegarde, commandes) et un test de fumée
## des scènes (instanciation + interactions simulées). Ne remplace pas un test
## manuel du ressenti de jeu.

const TEST_SAVE_PATH := "user://test_savegame.json"

var _passed := 0
var _failed := 0
var _current := ""


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var tests := [
		"test_case_index_and_loading",
		"test_case_40921_structure",
		"test_case_40921_has_contradiction",
		"test_document_rendering_escapes_bbcode",
		"test_calendar",
		"test_new_game_defaults",
		"test_indicators_are_clamped",
		"test_document_and_message_tracking",
		"test_save_roundtrip",
		"test_save_rejects_bad_files",
		"test_save_migration_from_v1",
		"test_case_validation_detects_problems",
		"test_fact_confrontation",
		"test_decision_rules",
		"test_apply_decision",
		"test_events_file_is_valid",
		"test_event_conditions",
		"test_end_day_without_decision",
		"test_delayed_consequences",
		"test_save_migration_from_v2",
		"test_save_migration_from_v3",
		"test_work_time",
		"test_request_and_consultation",
		"test_veritas",
		"test_veritas_model",
		"test_case_51307_depends_on_first_case",
		"test_case_51307_contradictions_and_veritas",
		"test_case_51307_consequences",
		"test_case_52044_structure",
		"test_case_52044_decisions",
		"test_case_52044_consequences",
		"test_case_52310_structure",
		"test_case_52310_consequences",
		"test_assessment",
		"test_guidance_steps",
		"test_terminal_command_parsing",
		"test_main_menu_scene",
		"test_desk_scene_flow",
		"test_full_session_flow",
		"test_investigation_and_conclusion_flow",
		"test_end_day_in_desk",
		"test_friendly_desk",
		"test_time_in_desk",
	]
	# Ne jamais toucher à la vraie sauvegarde du joueur.
	SaveManager.save_path = TEST_SAVE_PATH
	for test_name in tests:
		_current = test_name
		GameState.new_game()
		await call(test_name)
	SaveManager.delete_save(TEST_SAVE_PATH)
	SaveManager.save_path = SaveManager.DEFAULT_PATH
	GameState.new_game()
	print("")
	print("RÉSULTAT : %d vérification(s) réussie(s), %d échec(s)." % [_passed, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


func check(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
		print("  ok   %s : %s" % [_current, description])
	else:
		_failed += 1
		printerr("  ÉCHEC %s : %s" % [_current, description])


# --- Données -----------------------------------------------------------------

func test_case_index_and_loading() -> void:
	var ids := CaseLibrary.get_case_ids()
	check(ids.size() >= 1, "index.json liste au moins un dossier")
	for case_id in ids:
		var case_data := CaseLibrary.get_case(case_id)
		check(not case_data.is_empty(), "le dossier %s se charge" % case_id)
		check(CaseLibrary.validate_case(case_data).is_empty(),
				"le dossier %s est valide %s" % [case_id, CaseLibrary.validate_case(case_data)])
	print("  (le message ERROR qui suit est attendu)")
	check(CaseLibrary.get_case("inexistant").is_empty(), "un dossier inconnu renvoie {}")


func test_case_40921_structure() -> void:
	var case_data := CaseLibrary.get_case("40921")
	var types := {}
	for document in case_data.documents:
		types[document.type] = true
	for required in ["identity", "report", "intercept", "travel_log"]:
		check(types.has(required), "pièce de type %s présente" % required)
	var identity := CaseLibrary.get_document(case_data, "identity")
	var labels := []
	for field in identity.fields:
		labels.append(field[0])
	for required in ["Nom", "Profession", "Adresse"]:
		check(required in labels, "fiche d'identité : champ %s" % required)
	var decision_ids := []
	for decision in case_data.decisions:
		decision_ids.append(decision.id)
	check(decision_ids == ["arrest", "close", "investigate"], "les trois décisions sont définies")


func test_case_40921_has_contradiction() -> void:
	var contradictions := CaseLibrary.find_contradictions(CaseLibrary.get_case("40921"))
	var keys := contradictions.map(func(c: Dictionary) -> String: return c.key)
	check("sedlar.location.1986-10-21" in keys, "le rapport de présence contredit le registre de déplacements")
	check(not ("sedlar.work_card" in keys), "deux valeurs identiques ne sont pas une contradiction")


func test_document_rendering_escapes_bbcode() -> void:
	var dossiers_script := load("res://scenes/ui/windows/dossiers_window.gd")
	var intercept := CaseLibrary.get_document(CaseLibrary.get_case("40921"), "intercept")
	var bbcode: String = dossiers_script.render_document_bbcode(intercept)
	check(bbcode.contains("[lb]Fin de l'appel]"), "les crochets du texte sont échappés")
	var log := CaseLibrary.get_document(CaseLibrary.get_case("40921"), "travel_log")
	check(dossiers_script.render_document_bbcode(log).contains("[table=5]"), "le registre est rendu en tableau")


func test_calendar() -> void:
	check(FictionalCalendar.format_long(0) == "LUNDI 3 NOVEMBRE 1986", "jour 0 : %s" % FictionalCalendar.format_long(0))
	check(FictionalCalendar.service_days().size() == 20, "20 journées de service")
	check(FictionalCalendar.format_long(4) == "VENDREDI 7 NOVEMBRE 1986", "journée 4 : %s" % FictionalCalendar.format_long(4))
	check(FictionalCalendar.format_long(5) == "LUNDI 10 NOVEMBRE 1986", "le dimanche est sauté : %s" % FictionalCalendar.format_long(5))
	check(FictionalCalendar.format_long(19) == "SAMEDI 6 DÉCEMBRE 1986", "dernière journée : %s" % FictionalCalendar.format_long(19))
	check(FictionalCalendar.format_short(20) == "07.12.1986", "au-delà, jour par jour : %s" % FictionalCalendar.format_short(20))
	check(FictionalCalendar.days_since_previous(1) == 1 and FictionalCalendar.days_since_previous(5) == 3
			and FictionalCalendar.days_since_previous(15) == 11, "écarts entre journées (ellipses)")
	check(FictionalCalendar.act_for_day(0).number == 1 and FictionalCalendar.act_for_day(4).number == 1
			and FictionalCalendar.act_for_day(5).number == 2 and FictionalCalendar.act_for_day(19).title == "MIROIR", "actes")


# --- État de la partie -------------------------------------------------------

func test_new_game_defaults() -> void:
	check(GameState.indicators == GameState.INITIAL_INDICATORS, "indicateurs initiaux")
	check(GameState.get_rank_title() == "Inspecteur de 3e classe", "grade initial")
	check(GameState.cases.has("40921"), "le dossier 40921 est assigné")
	check(not GameState.cases.has("51307"), "le dossier 51307 n'arrive pas dès le premier jour")
	check(GameState.get_case_state("40921").status == GameState.CASE_OPEN, "le dossier est ouvert")
	check(GameState.get_unread_count() == 2, "deux messages non lus au départ")
	check(GameState.day_index == 0 and GameState.decisions.is_empty(), "jour 0, aucune décision")


func test_indicators_are_clamped() -> void:
	GameState.adjust_indicator("loyalty", 500)
	check(GameState.get_indicator("loyalty") == 100, "plafond à 100")
	GameState.adjust_indicator("suspicion", -500)
	check(GameState.get_indicator("suspicion") == 0, "plancher à 0")
	GameState.adjust_indicator("influence", 7)
	check(GameState.get_indicator("influence") == 17, "variation simple")


func test_document_and_message_tracking() -> void:
	var emitted := [0]
	var on_change := func() -> void: emitted[0] += 1
	GameState.state_changed.connect(on_change)
	GameState.mark_document_viewed("40921", "intercept")
	GameState.mark_document_viewed("40921", "intercept")
	check(GameState.get_case_state("40921").viewed_documents == ["intercept"], "consultation enregistrée une seule fois")
	check(emitted[0] == 1, "state_changed émis une seule fois")
	GameState.mark_message_read("welcome_mazur")
	check(GameState.get_unread_count() == 1, "message marqué comme lu")
	GameState.state_changed.disconnect(on_change)


func test_save_roundtrip() -> void:
	GameState.adjust_indicator("loyalty", 12)
	GameState.mark_document_viewed("40921", "travel_log")
	GameState.mark_message_read("welcome_mazur")
	GameState.day_index = 4
	GameState.flags["test_flag"] = true
	var expected := GameState.to_dict()
	check(SaveManager.save_game(GameState, TEST_SAVE_PATH) == OK, "écriture de la sauvegarde")
	check(SaveManager.has_save(TEST_SAVE_PATH), "le fichier existe")
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TEST_SAVE_PATH))
	check(int(raw.save_version) == SaveManager.SAVE_VERSION, "la sauvegarde porte son numéro de version")
	GameState.new_game()
	check(GameState.get_indicator("loyalty") == 50, "nouvelle partie remise à zéro")
	check(SaveManager.load_game(GameState, TEST_SAVE_PATH) == OK, "lecture de la sauvegarde")
	check(GameState.get_indicator("loyalty") == 62, "indicateur restauré")
	check(typeof(GameState.indicators.loyalty) == TYPE_INT, "les indicateurs restent des entiers")
	check(GameState.day_index == 4, "date restaurée")
	check(GameState.is_document_viewed("40921", "travel_log"), "pièces consultées restaurées")
	check(GameState.get_unread_count() == 1, "messages lus restaurés")
	check(GameState.flags.get("test_flag") == true, "drapeaux restaurés")
	check(JSON.stringify(GameState.to_dict()) == JSON.stringify(expected), "état identique après rechargement")


func test_save_rejects_bad_files() -> void:
	print("  (les messages ERROR qui suivent sont attendus)")
	GameState.adjust_indicator("loyalty", 5)
	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	file.store_string("{ pas du json")
	file.close()
	check(SaveManager.load_game(GameState, TEST_SAVE_PATH) == ERR_PARSE_ERROR, "fichier corrompu refusé")
	file = FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"save_version": SaveManager.SAVE_VERSION + 1, "state": {}}))
	file.close()
	check(SaveManager.load_game(GameState, TEST_SAVE_PATH) == ERR_INVALID_DATA, "version future refusée")
	check(GameState.get_indicator("loyalty") == 55, "l'état n'est pas modifié après un échec")
	check(SaveManager.load_game(GameState, "user://absent.json") == ERR_FILE_NOT_FOUND, "fichier absent signalé")


func test_save_migration_from_v1() -> void:
	# Sauvegarde du prototype 0.1 : pas de carnet d'enquête dans les dossiers.
	var v1 := {"save_version": 1, "game_version": "0.1.0", "saved_at": "", "state": {
		"player": {"name": "A. VOSK", "badge": "INS-7734", "rank": 0}, "day_index": 2,
		"indicators": {"loyalty": 40, "suspicion": 30, "influence": 10},
		"cases": {"40921": {"status": "open", "viewed_documents": ["identity"], "decision": ""}},
		"messages": [], "decisions": [], "flags": {}}}
	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(v1))
	file.close()
	check(SaveManager.load_game(GameState, TEST_SAVE_PATH) == OK, "une sauvegarde v1 se charge")
	var case_state := GameState.get_case_state("40921")
	check(case_state.noted_facts == [] and case_state.contradictions_found == [], "champs du carnet ajoutés")
	check(case_state.viewed_documents == ["identity"] and GameState.day_index == 2, "données v1 conservées")


func test_case_validation_detects_problems() -> void:
	var broken := {"id": "x", "title": "x", "subject_name": "x", "documents": [
		{"id": "d1", "type": "report", "title": "t", "source": "s", "reliability": "A",
			"facts": [{"id": "f1", "key": "k"}]}],
		"decisions": [{"id": "dec", "outcomes": [{"when": "contradiction_found", "response": "absente"}]}],
		"responses": {}}
	var problems := CaseLibrary.validate_case(broken)
	check(problems.size() >= 3, "élément incomplet, issue par défaut manquante, réponse absente : %d problème(s)" % problems.size())


func test_fact_confrontation() -> void:
	var case_data := CaseLibrary.get_case("40921")
	check(CaseLibrary.get_fact(case_data, "f_log_trip").document_id == "travel_log", "un élément connaît sa pièce")
	check(CaseLibrary.confront(case_data, "f_report_presence", "f_log_trip") == "sedlar.location.1986-10-21",
			"présence au poste contre train pour Halvek : contradiction")
	check(CaseLibrary.confront(case_data, "f_log_trip", "f_report_presence") != "", "l'ordre n'a pas d'importance")
	check(CaseLibrary.confront(case_data, "f_identity_card", "f_log_card") == "", "même carte : pas de contradiction")
	check(CaseLibrary.confront(case_data, "f_intercept_trip", "f_report_presence") == "", "sujets différents : pas de contradiction")
	check(CaseLibrary.confront(case_data, "f_log_trip", "f_log_trip") == "", "un élément ne se contredit pas lui-même")
	check(GameState.confront_facts("40921", "f_report_presence", "f_log_trip") != "", "GameState enregistre la contradiction")
	GameState.confront_facts("40921", "f_log_trip", "f_report_presence")
	check(GameState.get_case_state("40921").contradictions_found.size() == 1, "pas de doublon")


func test_decision_rules() -> void:
	var case_data := CaseLibrary.get_case("40921")
	var without := GameState.get_case_state("40921").duplicate(true)
	var with_found := without.duplicate(true)
	with_found.contradictions_found = ["sedlar.location.1986-10-21"]
	var expected := {
		"arrest": ["arrest_found", "arrest_unfounded", "closed"],
		"close": ["close_despite_evidence", "close_unchecked", "closed"],
		"investigate": ["investigate_found", "investigate_unfounded", "under_investigation"],
	}
	for decision_id in expected:
		var found := DecisionRules.resolve(case_data, with_found, decision_id)
		var unfound := DecisionRules.resolve(case_data, without, decision_id)
		check(found.response_id == expected[decision_id][0], "%s avec contradiction : %s" % [decision_id, found.response_id])
		check(unfound.response_id == expected[decision_id][1], "%s sans contradiction : %s" % [decision_id, unfound.response_id])
		check(found.status_after == expected[decision_id][2], "%s : statut %s" % [decision_id, found.status_after])
		check(not found.response.is_empty() and found.response.body.length() > 50, "%s : message du supérieur rédigé" % decision_id)
		check(found.effects != unfound.effects, "%s : les effets dépendent de l'instruction" % decision_id)
	# Arrêter sur des faits établis est mieux vu que d'arrêter sans preuve.
	var arrest_found := DecisionRules.resolve(case_data, with_found, "arrest")
	var arrest_unfound := DecisionRules.resolve(case_data, without, "arrest")
	check(arrest_found.effects.suspicion < arrest_unfound.effects.suspicion, "arrestation sans preuve : plus de suspicion")
	var close_found := DecisionRules.resolve(case_data, with_found, "close")
	check(close_found.effects.suspicion > 10, "classer malgré une contradiction établie éveille la suspicion")
	check(DecisionRules.resolve(case_data, without, "inexistante").is_empty(), "décision inconnue : résultat vide")


func test_apply_decision() -> void:
	var received := []
	var on_applied := func(case_id: String, decision_id: String, message_id: String) -> void:
		received.append([case_id, decision_id, message_id])
	GameState.decision_applied.connect(on_applied)
	GameState.confront_facts("40921", "f_report_presence", "f_log_trip")
	var unread_before := GameState.get_unread_count()
	var result := GameState.apply_decision("40921", "arrest")
	check(not result.is_empty(), "la décision s'applique")
	check(GameState.get_indicator("loyalty") == 60 and GameState.get_indicator("suspicion") == 15
			and GameState.get_indicator("influence") == 15, "indicateurs : %s" % GameState.indicators)
	var case_state := GameState.get_case_state("40921")
	check(case_state.status == GameState.CASE_CLOSED and case_state.decision == "arrest", "dossier clos, décision enregistrée")
	check(GameState.flags.get("40921.sedlar_arrested") == true, "conséquence persistante enregistrée")
	check(GameState.decisions.size() == 1 and GameState.decisions[0].outcome == "arrest_found", "historique des décisions")
	check(GameState.get_unread_count() == unread_before + 1, "le supérieur envoie un message")
	check(GameState.messages[-1].id == "40921.arrest_found" and GameState.messages[-1].date_label == "03.11.1986",
			"message identifié et daté")
	check(received == [["40921", "arrest", "40921.arrest_found"]], "signal decision_applied émis")
	check(not GameState.can_decide("40921"), "une seule décision par dossier")
	print("  (l'avertissement qui suit est attendu)")
	check(GameState.apply_decision("40921", "close").is_empty(), "une seconde décision est refusée")
	check(GameState.get_indicator("loyalty") == 60, "la seconde décision n'a aucun effet")
	GameState.decision_applied.disconnect(on_applied)


# --- Journées et événements -------------------------------------------------

func test_events_file_is_valid() -> void:
	var events := EventRules.get_events()
	check(events.size() >= 5, "%d événements définis" % events.size())
	var ids := {}
	for event in events:
		check(event.has("id") and not ids.has(event.id), "identifiant unique : %s" % event.get("id", "?"))
		ids[event.get("id", "")] = true
		if event.has("message"):
			check(event.message.has("from") and event.message.has("subject") and event.message.has("body"),
					"%s : message complet" % event.id)
		for indicator in event.get("effects", {}):
			check(GameState.INITIAL_INDICATORS.has(indicator), "%s : indicateur connu %s" % [event.id, indicator])


func test_event_conditions() -> void:
	var state := {"day_index": 1, "flags": {"a": true}, "cases": {"1": {"decision": ""}, "2": {"decision": "x"}}}
	check(EventRules.are_conditions_met({}, state), "aucune condition : vrai")
	check(not EventRules.are_conditions_met({"min_day": 2}, state), "jour minimal respecté")
	check(EventRules.are_conditions_met({"requires_flags": ["a"]}, state), "drapeau requis présent")
	check(not EventRules.are_conditions_met({"requires_flags": ["b"]}, state), "drapeau requis absent")
	check(not EventRules.are_conditions_met({"forbidden_flags": ["a"]}, state), "drapeau interdit présent")
	check(EventRules.are_conditions_met({"undecided_cases": ["1"]}, state), "dossier sans décision")
	check(not EventRules.are_conditions_met({"undecided_cases": ["2"]}, state), "dossier déjà décidé")
	var events := [{"id": "once"}, {"id": "again", "repeatable": true}]
	state["fired_events"] = ["once", "again"]
	var due := EventRules.due_events(state, events)
	check(due.size() == 1 and due[0].id == "again", "un événement ne se répète que s'il est repeatable")


func test_end_day_without_decision() -> void:
	var days := []
	var on_day := func(day: int, _events: Array) -> void: days.append(day)
	GameState.day_started.connect(on_day)
	var unread := GameState.get_unread_count()
	var fired := GameState.end_day()
	var fired_ids := fired.map(func(e: Dictionary) -> String: return e.id)
	check(GameState.day_index == 1 and GameState.get_date_long() == "MARDI 4 NOVEMBRE 1986", "on passe au mardi 4 novembre")
	check(fired_ids == ["assign_51307", "51307_milice_plea", "40921_reminder", "daily_bulletin_1"],
			"nouveau dossier, pression de la Milice, rappel et bulletin : %s" % [fired_ids])
	check(GameState.cases.has("51307"), "le dossier 51307 est attribué")
	check(GameState.get_indicator("suspicion") == 23, "le retard éveille la suspicion")
	check(GameState.get_unread_count() == unread + 4, "quatre nouveaux messages")
	check(GameState.messages[-1].date_label == "04.11.1986", "messages datés du jour")
	check(days == [1], "signal day_started émis")
	var next_ids := GameState.end_day().map(func(e: Dictionary) -> String: return e.id)
	check(next_ids == ["51307_reminder", "assign_52044", "daily_bulletin_2"],
			"le lendemain : rappel, dossier 52044 et bulletin : %s" % [next_ids])
	GameState.day_started.disconnect(on_day)


func test_delayed_consequences() -> void:
	# decision, contradiction établie ?, événement attendu le lendemain
	var scenarios := [
		["arrest", true, "40921_family_letter"],
		["arrest", false, "40921_family_letter"],
		["close", true, "40921_reprimand"],
		["close", false, "40921_reassigned"],
		["investigate", true, "40921_orlik_hearing"],
	]
	for scenario in scenarios:
		GameState.new_game()
		if scenario[1]:
			GameState.confront_facts("40921", "f_report_presence", "f_log_trip")
		GameState.apply_decision("40921", scenario[0])
		var ids := GameState.end_day().map(func(e: Dictionary) -> String: return e.id)
		check(scenario[2] in ids, "%s (contradiction : %s) > %s" % [scenario[0], scenario[1], scenario[2]])
		check(not "40921_reminder" in ids, "%s : pas de rappel une fois la décision prise" % scenario[0])
	check(GameState.flags.get("40921.orlik_confessed") == true, "l'audition d'ORLIK pose un drapeau persistant")
	GameState.new_game()
	GameState.apply_decision("40921", "investigate")
	var ids := GameState.end_day().map(func(e: Dictionary) -> String: return e.id)
	check(ids == ["assign_51307", "51307_milice_plea", "daily_bulletin_1"], "enquête sans fondement : pas de suite propre au 40921")
	check(GameState.decisions[0].veritas_agreed == false, "désaccord avec VERITAS mémorisé")


func test_save_migration_from_v2() -> void:
	GameState.end_day()
	var data := GameState.to_dict()
	data.erase("fired_events")
	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"save_version": 2, "state": data}))
	file.close()
	check(SaveManager.load_game(GameState, TEST_SAVE_PATH) == OK, "une sauvegarde v2 se charge")
	check(GameState.fired_events == [], "liste des événements ajoutée")
	check(GameState.day_index == 1, "jour conservé")


func test_save_migration_from_v3() -> void:
	var data := GameState.to_dict()
	data.erase("hours_used")
	data.erase("overtime_days")
	for case_state in data.cases.values():
		case_state.erase("requested_documents")
		case_state.erase("consulted")
	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"save_version": 3, "state": data}))
	file.close()
	check(SaveManager.load_game(GameState, TEST_SAVE_PATH) == OK, "une sauvegarde v3 se charge")
	check(GameState.hours_used == 0 and GameState.overtime_days == [], "horloge ajoutée")
	check(GameState.get_case_state("40921").requested_documents == {} and GameState.get_case_state("40921").consulted == false,
			"champs de demande ajoutés aux dossiers")
	GameState.spend_time("request_document")
	GameState.get_case_state("40921").requested_documents["medical_halvek"] = 0
	SaveManager.save_game(GameState, TEST_SAVE_PATH)
	GameState.new_game()
	SaveManager.load_game(GameState, TEST_SAVE_PATH)
	check(GameState.hours_used == 1 and GameState.get_case_state("40921").requested_documents.has("medical_halvek"),
			"horloge et demandes sauvegardées")


func test_work_time() -> void:
	check(GameState.get_clock_text() == "08h00", "la journée commence à 08h00")
	check(WorkTime.cost("request_document") == 1 and WorkTime.cost("verify_archive") == 2, "coûts lus dans les données")
	check(WorkTime.cost("lire") == 0, "une action inconnue est gratuite")
	for i in 8:
		check(GameState.spend_time("consult_superior"), "heure %d disponible" % (i + 1))
	check(GameState.get_clock_text() == "16h00" and not GameState.is_overtime_today(), "16h00 : fin de la journée normale")
	check(GameState.spend_time("request_document") and GameState.is_overtime_today(), "heures supplémentaires notées")
	check(GameState.spend_time("request_document"), "deuxième heure supplémentaire")
	check(not GameState.spend_time("request_document"), "au-delà de 18h00, plus d'action payante")
	check(GameState.hours_used == 10, "10 heures au plus")
	GameState.apply_decision("40921", "investigate")
	check(GameState.get_case_state("40921").decision == "investigate", "signer reste possible sans heure disponible")
	GameState.end_day()
	check(GameState.get_clock_text() == "08h00" and GameState.overtime_days == [0], "le lendemain, l'horloge repart ; la soirée perdue reste notée")


func test_request_and_consultation() -> void:
	check(GameState.get_requestable_documents("40921").map(func(d: Dictionary) -> String: return d.id) == ["medical_halvek"],
			"une pièce à demander dans le 40921")
	check(not "medical_halvek" in _visible_document_ids("40921"), "la pièce n'existe pas avant la demande")
	check(GameState.request_document("40921", "medical_halvek") and GameState.hours_used == 1, "demande : 1 heure")
	check(not GameState.request_document("40921", "medical_halvek"), "on ne demande pas deux fois")
	check(not GameState.request_document("40921", "identity"), "une pièce ordinaire ne se demande pas")
	check(GameState.get_requestable_documents("40921").is_empty(), "plus rien à demander")
	check(not "medical_halvek" in _visible_document_ids("40921"), "la pièce n'arrive pas le jour même")
	GameState.end_day()
	check("medical_halvek" in _visible_document_ids("40921"), "la pièce arrive le lendemain")
	var unread := GameState.get_unread_count()
	check(GameState.consult_superior("40921") and GameState.hours_used == 1, "consulter Mazur : 1 heure")
	check(GameState.get_unread_count() == unread + 1 and GameState.messages[-1].id == "40921.consultation", "Mazur répond par message")
	check(GameState.flags.get("40921.consulted_superior") == true, "la consultation est mémorisée")
	check(not GameState.consult_superior("40921"), "une seule consultation par dossier")
	# Une demande trop curieuse se paie.
	_reach_case_52310()
	var suspicion := GameState.get_indicator("suspicion")
	check(GameState.request_document("52310", "detention_file"), "demande du dossier de détention")
	check(GameState.flags.get("52310.archive_requested") == true and GameState.get_indicator("suspicion") == suspicion + 2,
			"la demande est signalée à la Section 7")
	for case_id in ["40921", "51307", "52044", "52310"]:
		var case_data := CaseLibrary.get_case(case_id)
		check(CaseLibrary.validate_case(case_data).is_empty() and case_data.has("consultation"), "%s : consultation et pièce à demander" % case_id)


func test_veritas() -> void:
	var case_data := CaseLibrary.get_case("40921")
	for document in case_data.documents:
		check(Veritas.document_remark(document) != "", "VERITAS commente la pièce %s" % document.id)
	var advice := Veritas.recommendation(case_data)
	check(advice.decision_id == "arrest" and advice.confidence == 87, "VERITAS recommande l'arrestation à 87 %")
	check(Veritas.terminal_reply(GameState.get_condition_state()).contains("4 pièce(s) non consultée(s)"), "VERITAS signale les pièces non lues")
	for document in case_data.documents:
		GameState.mark_document_viewed("40921", document.id)
	check(Veritas.terminal_reply(GameState.get_condition_state()).contains("Indice de conformité : 87"), "puis donne sa recommandation")
	GameState.apply_decision("40921", "arrest")
	check(Veritas.terminal_reply(GameState.get_condition_state()).begins_with("Aucun dossier"), "rien à signaler une fois le dossier traité")
	check(GameState.decisions[0].veritas_agreed == true, "accord avec VERITAS mémorisé")


# --- Dossier 51307 (ORLIK) ---------------------------------------------------

## Joue le dossier 40921 avec une décision donnée, puis passe au lendemain.
func test_veritas_model() -> void:
	var expected := {"40921": ["arrest", 87], "51307": ["close", 71], "52044": ["arrest_baker", 83], "52310": ["arrest", 91]}
	for case_id in expected:
		var case_data := CaseLibrary.get_case(case_id)
		var advice := Veritas.recommendation(case_data)
		check(advice.decision_id == expected[case_id][0] and advice.confidence == expected[case_id][1],
				"%s : indice calculé %s %d (obtenu %s %s)" % [case_id, expected[case_id][0], expected[case_id][1], advice.decision_id, advice.confidence])
		check(advice.decision_id == case_data.veritas.recommendation, "%s : recommandation déclarée = indice le plus fort" % case_id)
	var c52044 := CaseLibrary.get_case("52044")
	var before: Dictionary = Veritas.scores(c52044)
	var after: Dictionary = Veritas.scores(c52044, {"contradictions_found": ["horvat.status"]})
	check(after.report_bureau.score == before.report_bureau.score + 20, "un fait établi par l'agent compte pour VERITAS")
	check(Veritas.recommendation(c52044, {"contradictions_found": ["horvat.status", "lenska.status"]}).decision_id == "arrest_baker",
			"VERITAS maintient son avis malgré les faits (biais de la source d'État)")
	var c52310 := CaseLibrary.get_case("52310")
	var halina: Dictionary = Veritas.scores(c52310, {"contradictions_found": ["poem.acrostic"]})
	check(halina.no_code.score == 40 and halina.no_code.factors.size() == 1 and halina.no_code.factors[0].contribution == 0.0,
			"un document hors période pèse zéro (multiplicateur caché)")
	var hidden := c52044.duplicate(true)
	hidden.documents = hidden.documents.filter(func(d: Dictionary) -> bool: return d.id != "issue_register")
	check(Veritas.scores(hidden).arrest_baker.score == 62, "un facteur dont la pièce est absente ne compte pas")
	var plain := Veritas.explain(CaseLibrary.get_case("40921"))
	check(plain.size() == 3 and plain[0].begins_with("Déplacement non déclaré") and not plain[0].contains(" x "),
			"VERITAS POURQUOI : 3 facteurs, sans multiplicateur (%s)" % [plain])
	var detailed := Veritas.explain(CaseLibrary.get_case("40921"), {}, true)
	check(detailed[0].contains("poids 8 x 2 = 16"), "avec les paramètres connus, le multiplicateur apparaît (%s)" % detailed[0])
	for document_id in ["identity", "work_report", "intercept", "travel_log"]:
		GameState.mark_document_viewed("40921", document_id)
	var reply := Veritas.terminal_reply(GameState.get_condition_state(), PackedStringArray(["POURQUOI"]))
	check(reply.contains("Facteurs principaux") and reply.contains("Famille résidant à Halvek"), "commande VERITAS POURQUOI")


func _play_first_case(decision_id: String, establish_contradiction: bool) -> void:
	GameState.new_game()
	if establish_contradiction:
		GameState.confront_facts("40921", "f_report_presence", "f_log_trip")
	if decision_id != "":
		GameState.apply_decision("40921", decision_id)
	GameState.end_day()


func _visible_document_ids(case_id: String) -> Array:
	return GameState.get_case_view(case_id).documents.map(func(d: Dictionary) -> String: return d.id)


func test_case_51307_depends_on_first_case() -> void:
	var base := ["identity", "certificates", "clock_log", "anonymous"]
	var scenarios := [
		["", false, []],
		["investigate", true, ["orlik_hearing"]],
		["investigate", false, []],
		["arrest", true, ["sedlar_interrogation"]],
		["close", false, ["kremer_note"]],
		["close", true, []],
	]
	for scenario in scenarios:
		_play_first_case(scenario[0], scenario[1])
		var ids := _visible_document_ids("51307")
		var expected: Array = base.duplicate()
		var extra: Array = scenario[2]
		for document_id in ["orlik_hearing", "sedlar_interrogation", "kremer_note"]:
			if document_id in extra:
				expected.append(document_id)
		check(ids == expected, "40921 « %s » (contradiction : %s) > pièces %s" % [scenario[0], scenario[1], ids])
	check(CaseLibrary.get_case("51307").documents.size() == 8, "le dossier complet garde ses 8 pièces")


func test_case_51307_contradictions_and_veritas() -> void:
	var case_data := CaseLibrary.get_case("51307")
	check(CaseLibrary.confront(case_data, "f_cert_reason", "f_clock_ok") == "clock.status.october",
			"« panne de l'horloge » contre relevé technique : contradiction")
	check(CaseLibrary.confront(case_data, "f_hearing_clock", "f_clock_ok") != "", "les déclarations d'ORLIK contredisent le relevé")
	check(CaseLibrary.confront(case_data, "f_hearing_motive", "f_anon_motive") == "orlik.motive",
			"« jamais rien vendu » contre « un paquet de café » : contradiction")
	check(CaseLibrary.confront(case_data, "f_sedlar_motive", "f_anon_motive") == "", "SEDLAR confirme la lettre anonyme")
	check(CaseLibrary.confront(case_data, "f_anon_petras", "f_cert_petras") == "", "les jeudis de PETRAS se recoupent")
	var advice := Veritas.recommendation(case_data)
	check(advice.decision_id == "close" and advice.confidence == 71, "VERITAS recommande le classement à 71 %")


func test_case_51307_consequences() -> void:
	var scenarios := [
		["arrest", "51307_milice_hostile", "milice.enemy"],
		["close", "51307_milice_grateful", "milice.ally"],
		["demote", "51307_demoted", "51307.orlik_demoted"],
	]
	for scenario in scenarios:
		_play_first_case("investigate", true)
		GameState.confront_facts("51307", "f_cert_reason", "f_clock_ok")
		var result := GameState.apply_decision("51307", scenario[0])
		check(result.response_id == scenario[0] + "_found", "51307 %s : réponse %s" % [scenario[0], result.response_id])
		var ids := GameState.end_day().map(func(e: Dictionary) -> String: return e.id)
		check(scenario[1] in ids, "51307 %s > %s le lendemain" % [scenario[0], scenario[1]])
		check(GameState.flags.get(scenario[2]) == true, "drapeau persistant %s" % scenario[2])
		check(not "51307_reminder" in ids, "pas de rappel après la décision")
	_play_first_case("arrest", true)
	var ids := GameState.end_day().map(func(e: Dictionary) -> String: return e.id)
	check("51307_reminder" in ids, "rappel si le dossier 51307 traîne")


## Joue jusqu'au jour 2 (attribution du dossier 52044), après un choix sur le 51307.
func _reach_case_52044(decision_51307: String) -> void:
	_play_first_case("investigate", true)
	if decision_51307 != "":
		GameState.confront_facts("51307", "f_cert_reason", "f_clock_ok")
		GameState.apply_decision("51307", decision_51307)
	GameState.end_day()


func test_case_52044_structure() -> void:
	var case_data := CaseLibrary.get_case("52044")
	check(CaseLibrary.validate_case(case_data).is_empty(), "52044 : dossier valide %s" % [CaseLibrary.validate_case(case_data)])
	var keys := CaseLibrary.find_contradictions(case_data).map(func(c: Dictionary) -> String: return c.key)
	for key in ["sector.books", "horvat.status", "lenska.status"]:
		check(key in keys, "52044 : contradiction possible sur %s" % key)
	check(keys.size() == 3, "52044 : exactement 3 contradictions (%s)" % [keys])
	check(CaseLibrary.confront(case_data, "f_reg_horvat", "f_death_horvat") == "horvat.status", "52044 : carnet délivré à un mort")
	check(CaseLibrary.confront(case_data, "f_rep_expected", "f_reg_total") == "sector.books", "52044 : 1 080 contre 1 412 carnets")
	check(CaseLibrary.confront(case_data, "f_reg_horvat", "f_death_lenska") == "", "52044 : deux personnes différentes ne se contredisent pas")
	check(Veritas.recommendation(case_data).decision_id == "arrest_baker", "52044 : VERITAS accuse la boulangère")
	# Attribution au jour 2 seulement.
	GameState.end_day()
	check(not GameState.cases.has("52044"), "52044 : pas encore attribué le jour 1")
	GameState.end_day()
	check(GameState.cases.has("52044"), "52044 : attribué le jour 2")
	var base := ["identity", "commerce_report", "issue_register", "death_register", "kovac_statement"]
	for scenario in [["", []], ["arrest", ["petras_statement"]], ["close", ["milice_note"]], ["demote", []]]:
		_reach_case_52044(scenario[0])
		if scenario[0] == "close":
			GameState.end_day()
		var expected: Array = base.duplicate()
		expected.append_array(scenario[1])
		var ids := _visible_document_ids("52044")
		check(ids == expected, "51307 « %s » > pièces du 52044 %s" % [scenario[0], ids])


func test_case_52044_decisions() -> void:
	var case_data := CaseLibrary.get_case("52044")
	var scenarios := [
		["report_bureau", [], "bureau_unfounded"],
		["report_bureau", ["sector.books"], "bureau_partial"],
		["report_bureau", ["horvat.status"], "bureau_proved"],
		["report_bureau", ["lenska.status"], "bureau_proved"],
		["report_bureau", ["sector.books", "horvat.status"], "bureau_proved"],
		["arrest_baker", [], "arrest_baker"],
		["arrest_baker", ["sector.books"], "arrest_baker_knowing"],
		["close", [], "close"],
		["close", ["horvat.status"], "close_knowing"],
	]
	for scenario in scenarios:
		var result := DecisionRules.resolve(case_data, {"contradictions_found": scenario[1]}, scenario[0])
		check(result.response_id == scenario[2], "52044 %s %s > %s (obtenu %s)" % [scenario[0], scenario[1], scenario[2], result.get("response_id")])
	check(DecisionRules.is_condition_met("contradiction:horvat.status", {"contradictions_found": ["horvat.status"]}), "condition contradiction:<clé> vraie")
	check(not DecisionRules.is_condition_met("contradiction:horvat.status", {"contradictions_found": ["sector.books"]}), "condition contradiction:<clé> fausse")


func test_case_52044_consequences() -> void:
	var scenarios := [
		["arrest_baker", ["f_rep_expected", "f_reg_total"], "52044_petition", "52044.innocent_condemned"],
		["report_bureau", ["f_reg_horvat", "f_death_horvat"], "52044_bureau_cold", "player.noticed_by_halm"],
		["close", ["f_reg_lenska", "f_death_lenska"], "52044_gift", "player.bribed"],
	]
	for scenario in scenarios:
		_reach_case_52044("demote")
		check(GameState.confront_facts("52044", scenario[1][0], scenario[1][1]) != "", "52044 : contradiction établie pour %s" % scenario[0])
		GameState.apply_decision("52044", scenario[0])
		var ids := GameState.end_day().map(func(e: Dictionary) -> String: return e.id)
		check(scenario[2] in ids, "52044 %s > %s le lendemain (%s)" % [scenario[0], scenario[2], ids])
		check(GameState.flags.get(scenario[3]) == true, "52044 %s : drapeau %s" % [scenario[0], scenario[3]])
		check(not "52044_reminder" in ids, "52044 : pas de rappel après la décision")
	_reach_case_52044("demote")
	GameState.apply_decision("52044", "report_bureau")
	GameState.end_day()
	check(GameState.flags.get("52044.drazek_warned") == true, "52044 : accusation sans preuve > DRAZEK prévenu")
	_reach_case_52044("demote")
	var ids := GameState.end_day().map(func(e: Dictionary) -> String: return e.id)
	check("52044_reminder" in ids, "52044 : rappel si le dossier traîne")


## Joue jusqu'au jour 3 (attribution du dossier 52310).
func _reach_case_52310(decision_40921: String = "investigate") -> void:
	_play_first_case(decision_40921, true)
	GameState.end_day()
	GameState.end_day()


func test_case_52310_structure() -> void:
	var case_data := CaseLibrary.get_case("52310")
	check(CaseLibrary.validate_case(case_data).is_empty(), "52310 : dossier valide %s" % [CaseLibrary.validate_case(case_data)])
	var keys := CaseLibrary.find_contradictions(case_data).map(func(c: Dictionary) -> String: return c.key)
	check(keys.size() == 2 and "poem.acrostic" in keys and "varga.mark" in keys, "52310 : 2 contradictions (%s)" % [keys])
	check(CaseLibrary.confront(case_data, "f_p86_acrostic", "f_p79_acrostic") == "poem.acrostic", "52310 : HALVEK contre HALINA")
	check(CaseLibrary.confront(case_data, "f_cen_acrostic", "f_p86_acrostic") == "", "52310 : le rapport et l'édition de 1986 concordent")
	check(CaseLibrary.confront(case_data, "f_var_mark", "f_rc_mark") == "varga.mark", "52310 : la cicatrice a disparu")
	check(CaseLibrary.get_document(case_data, "reader_card").photo.mark == "scar"
			and CaseLibrary.get_document(case_data, "identity").photo.mark == "none", "52310 : les deux photos diffèrent")
	_reach_case_52310()
	check(GameState.cases.has("52310"), "52310 : attribué le jour 3")
	check(not "sedlar_link" in _visible_document_ids("52310"), "52310 : pas d'interrogatoire de SEDLAR s'il est libre")
	_reach_case_52310("arrest")
	check("sedlar_link" in _visible_document_ids("52310"), "52310 : SEDLAR arrêté > on l'interroge sur VARGA")
	var scenarios := [
		["arrest", [], "arrest"], ["arrest", ["varga.mark"], "arrest_knowing"],
		["no_code", [], "no_code_unfounded"], ["no_code", ["poem.acrostic"], "no_code_proved"],
		["no_code", ["varga.mark"], "no_code_unfounded"],
		["identity_error", [], "identity_unfounded"], ["identity_error", ["varga.mark"], "identity_proved"],
		["identity_error", ["poem.acrostic"], "identity_unfounded"],
	]
	for scenario in scenarios:
		var result := DecisionRules.resolve(case_data, {"contradictions_found": scenario[1]}, scenario[0])
		check(result.response_id == scenario[2], "52310 %s %s > %s (obtenu %s)" % [scenario[0], scenario[1], scenario[2], result.get("response_id")])


func test_case_52310_consequences() -> void:
	var scenarios := [
		["arrest", [], ["52310_benes_letter", "act1_kremer_note"], "52310.varga_arrested"],
		["no_code", ["f_p86_acrostic", "f_p79_acrostic"], ["52310_dubek", "act1_kremer_note"], "section7.hostile"],
		["identity_error", ["f_var_mark", "f_rc_mark"], ["act1_kremer_seen"], "52310.truth_known"],
	]
	for scenario in scenarios:
		_reach_case_52310()
		if not scenario[1].is_empty():
			GameState.confront_facts("52310", scenario[1][0], scenario[1][1])
		GameState.apply_decision("52310", scenario[0])
		var ids := GameState.end_day().map(func(e: Dictionary) -> String: return e.id)
		for event_id in scenario[2]:
			check(event_id in ids, "52310 %s > %s (%s)" % [scenario[0], event_id, ids])
		check(not ("act1_kremer_note" in ids and "act1_kremer_seen" in ids), "52310 : une seule note de KREMER")
		check(GameState.flags.get(scenario[3]) == true, "52310 %s : drapeau %s" % [scenario[0], scenario[3]])
		check(GameState.flags.get("kremer.contact") == true, "52310 %s : contact avec KREMER établi" % scenario[0])
		check(not "52310_reminder" in ids, "52310 : pas de rappel après la décision")
	_reach_case_52310()
	var ids := GameState.end_day().map(func(e: Dictionary) -> String: return e.id)
	check("52310_reminder" in ids and not "act1_kremer_note" in ids, "52310 : rappel, et pas de note tant qu'il n'est pas conclu")


func test_guidance_steps() -> void:
	var step := func() -> Dictionary: return Guidance.next_step(GameState.get_condition_state(), GameState.messages)
	check(step.call().target == "messages" and step.call().text.contains("prise de fonction"), "1. lire le message de Mazur")
	GameState.mark_message_read("welcome_mazur")
	check(step.call().text.begins_with("Ouvrir le dossier n° 40921"), "2. ouvrir le dossier")
	GameState.mark_document_viewed("40921", "identity")
	check(step.call().text.contains("(1/4)"), "3. lire toutes les pièces")
	for document_id in ["work_report", "intercept", "travel_log"]:
		GameState.mark_document_viewed("40921", document_id)
	check(step.call().text.begins_with("Noter"), "4. noter des éléments")
	GameState.note_fact("40921", "f_report_presence")
	GameState.note_fact("40921", "f_log_trip")
	check(step.call().text.begins_with("Confronter"), "5. confronter")
	GameState.confront_facts("40921", "f_report_presence", "f_log_trip")
	check(step.call().text.begins_with("Rédiger"), "6. conclure")
	GameState.apply_decision("40921", "investigate")
	check(step.call().text.begins_with("Lire vos nouveaux messages"), "7. lire la réponse")
	for message in GameState.messages:
		GameState.mark_message_read(message.id)
	check(step.call().target == "end_day", "8. terminer la journée")


func test_assessment() -> void:
	var start := Assessment.describe(GameState.indicators, GameState.flags)
	var texts: Array = start.lines.map(func(l: Dictionary) -> String: return l.text)
	check(texts == ["conforme", "observation ordinaire", "agent sans appui"], "évaluation de départ : %s" % [texts])
	check(start.notes.is_empty(), "aucune observation au départ")
	for line in start.lines:
		check(not line.text.is_valid_int(), "aucun chiffre affiché (%s)" % line.label)
	var low := Assessment.describe({"loyalty": 0, "suspicion": 100, "influence": 0}, {})
	check(low.lines[0].text == "douteuse" and low.lines[1].text == "enquête interne envisagée", "paliers extrêmes")
	var high := Assessment.describe({"loyalty": 100, "suspicion": 0, "influence": 100}, {"milice.ally": true})
	check(high.lines[0].text == "exemplaire" and high.lines[2].text == "agent influent", "paliers maximaux")
	check(high.notes.size() == 1 and high.notes[0].contains("Milice"), "les drapeaux ajoutent des observations")
	check(Assessment.level_text([{"below": 10, "text": "a"}, {"below": 101, "text": "b"}], 10) == "b", "borne exclusive")


# --- Terminal ----------------------------------------------------------------

func test_terminal_command_parsing() -> void:
	var c := TerminalCommands.parse("  dossiers ")
	check(c.action == TerminalCommands.Action.OPEN_APP and c.target == "dossiers", "« dossiers » ouvre les dossiers")
	c = TerminalCommands.parse("Déconnexion")
	check(c.action == TerminalCommands.Action.MENU, "accents et casse ignorés")
	c = TerminalCommands.parse("msg")
	check(c.target == "messages", "alias MSG")
	c = TerminalCommands.parse("dossier 40921")
	check(c.target == "dossiers" and Array(c.args) == ["40921"], "arguments conservés")
	check(TerminalCommands.parse("fin").action == TerminalCommands.Action.END_DAY, "FIN termine la journée")
	check(TerminalCommands.parse("xyzzy").action == TerminalCommands.Action.UNKNOWN, "commande inconnue")
	check(TerminalCommands.parse("   ").action == TerminalCommands.Action.NONE, "saisie vide ignorée")


# --- Scènes (tests de fumée) -------------------------------------------------

func test_main_menu_scene() -> void:
	SaveManager.delete_save(TEST_SAVE_PATH)
	var menu: Control = load("res://scenes/main_menu/main_menu.tscn").instantiate()
	get_tree().root.add_child(menu)
	await get_tree().process_frame
	check(menu.get_node("%ContinueButton").disabled == not SaveManager.has_save(),
			"« Continuer » n'est actif que s'il existe une sauvegarde")
	check(ResourceLoader.exists(menu.DESK_SCENE), "la scène du bureau référencée par le menu existe")
	menu.get_node("%SettingsButton").pressed.emit()
	check(menu.get_node("%SettingsWindow").visible, "le bouton Paramètres ouvre la fenêtre")
	menu.get_node("%SettingsWindow").close()
	check(not menu.get_node("%SettingsWindow").visible, "la fenêtre Paramètres se ferme")
	menu.queue_free()
	await get_tree().process_frame


func test_desk_scene_flow() -> void:
	var desk: Control = load("res://scenes/desk/desk.tscn").instantiate()
	get_tree().root.add_child(desk)
	await get_tree().process_frame
	check(ResourceLoader.exists(desk.MAIN_MENU_SCENE), "la scène du menu référencée par le bureau existe")
	check(desk.get_node("%DateLabel").text == "LUNDI 3 NOVEMBRE 1986\n08h00  //  8 h de service restantes",
			"date et horloge dans l'en-tête : %s" % desk.get_node("%DateLabel").text)
	check(desk.get_node("%RankLabel").text == "INSPECTEUR DE 3E CLASSE", "grade affiché")
	check(desk.get_node("%MessagesButton").text.contains("2 non lu(s)"), "compteur de messages non lus")
	check(desk.get_open_app() == "", "aucune fenêtre ouverte au départ")

	desk.terminal.submit_command("dossiers")
	check(desk.get_open_app() == "dossiers", "la commande DOSSIERS ouvre la fenêtre Dossiers")
	var dossiers = desk.windows.dossiers
	check(dossiers.get_node("%CaseList").get_child_count() == 1, "un dossier dans la liste")
	dossiers.select_case("40921")
	check(dossiers.current_document_id == "identity", "la première pièce s'affiche")
	check(dossiers.get_node("%DocBody").get_parsed_text().contains("SEDLAR"), "le contenu de la pièce est affiché")
	dossiers.select_document("travel_log")
	check(GameState.get_case_state("40921").viewed_documents.size() == 2, "deux pièces marquées consultées")
	dossiers.close()
	check(desk.get_open_app() == "", "la fenêtre se ferme")

	desk.get_node("%MessagesButton").pressed.emit()
	check(desk.get_open_app() == "messages", "le bouton Messages ouvre la messagerie")
	await get_tree().process_frame
	check(GameState.get_unread_count() == 1, "le message affiché est marqué lu")
	check(desk.get_node("%MessagesButton").text.contains("1 non lu(s)"), "le compteur se met à jour")
	desk.terminal.submit_command("archives")
	check(desk.get_open_app() == "archives", "une seule fenêtre ouverte à la fois")

	desk.get_node("%PersonnelButton").pressed.emit()
	check(desk.get_open_app() == "personnel", "le bouton Dossier personnel ouvre l'évaluation")
	var personnel_text: String = desk.windows.personnel.get_node("%PersonnelText").get_parsed_text()
	check(personnel_text.contains("LOYAUTÉ ENVERS LE RÉGIME : conforme"), "l'évaluation est rédigée en mots")
	desk.terminal.submit_command("commande_bidon")
	check(desk.terminal.get_log_text().contains("COMMANDE INCONNUE"), "le terminal signale une commande inconnue")
	desk.terminal.submit_command("ident")
	check(desk.terminal.get_log_text().contains("INS-7734"), "IDENT affiche le matricule")
	desk.queue_free()
	await get_tree().process_frame


## Parcours complet avec vrais changements de scène :
## menu > nouvelle partie > bureau > lecture > sauvegarde > menu > continuer.
func test_full_session_flow() -> void:
	SaveManager.delete_save()
	var menu: Node = load("res://scenes/main_menu/main_menu.tscn").instantiate()
	get_tree().root.add_child(menu)
	get_tree().current_scene = menu
	await get_tree().process_frame
	menu.get_node("%NewGameButton").pressed.emit()
	await _wait_for_scene("Desk")
	var desk := get_tree().current_scene
	check(desk.name == "Desk", "« Nouvelle partie » mène au bureau")
	desk.terminal.submit_command("dossiers")
	desk.windows.dossiers.select_case("40921")
	desk.terminal.submit_command("sauver")
	check(SaveManager.has_save(), "SAUVER crée la sauvegarde")
	check(SaveManager.read_summary().get("date") == "LUNDI 3 NOVEMBRE 1986", "la sauvegarde porte un résumé lisible")
	desk.get_node("%MenuButton").pressed.emit()
	await _wait_for_scene("MainMenu")
	menu = get_tree().current_scene
	check(menu.name == "MainMenu", "DÉCONNEXION ramène au menu")
	check(not menu.get_node("%ContinueButton").disabled, "« Continuer » est actif après sauvegarde")
	check(menu.get_node("%ContinueButton").text.contains("LUNDI 3 NOVEMBRE 1986"), "« Continuer » indique la date de la partie")
	GameState.new_game()
	menu.get_node("%ContinueButton").pressed.emit()
	await _wait_for_scene("Desk")
	check(get_tree().current_scene.name == "Desk", "« Continuer » mène au bureau")
	check(GameState.is_document_viewed("40921", "identity"), "l'état sauvegardé est rechargé")
	get_tree().current_scene.queue_free()
	await get_tree().process_frame


func _wait_for_scene(scene_name: String) -> void:
	for i in 30:
		await get_tree().process_frame
		if get_tree().current_scene and get_tree().current_scene.name == scene_name:
			return


## Parcours d'enquête dans l'interface : noter, confronter, conclure, lire la réponse.
func test_investigation_and_conclusion_flow() -> void:
	var desk: Control = load("res://scenes/desk/desk.tscn").instantiate()
	get_tree().root.add_child(desk)
	await get_tree().process_frame
	desk.terminal.submit_command("dossiers")
	var dossiers = desk.windows.dossiers
	dossiers.select_case("40921")
	dossiers.select_document("identity")
	check(dossiers._photo.visible and dossiers._photo.photo.get("facial_hair") == "mustache",
			"la fiche d'identité affiche la photo du sujet")
	dossiers.select_document("work_report")
	check(not dossiers._photo.visible, "pas de photo sur un rapport")
	var facts_list: Node = dossiers.get_node("%FactsList")
	check(facts_list.get_child_count() == 2, "le rapport présente 2 éléments notables")
	check(dossiers.get_node("%VeritasStrip").visible and dossiers.get_node("%VeritasRemark").text.begins_with("VERITAS >"),
			"VERITAS commente la pièce affichée")
	facts_list.get_node("Fact_f_report_presence").pressed.emit()
	check(GameState.get_case_state("40921").noted_facts == ["f_report_presence"], "un clic note l'élément")
	check(facts_list.get_node("Fact_f_report_presence").disabled, "un élément noté ne peut plus être noté")
	dossiers.select_document("travel_log")
	dossiers.get_node("%FactsList").get_node("Fact_f_log_trip").pressed.emit()
	dossiers.get_node("%FactsList").get_node("Fact_f_log_card").pressed.emit()
	var notebook: Node = dossiers.get_node("%NotebookList")
	check(notebook.get_child_count() == 3, "trois éléments au carnet")
	notebook.get_node("Noted_f_log_card").pressed.emit()
	notebook = dossiers.get_node("%NotebookList")
	notebook.get_node("Noted_f_report_presence").pressed.emit()
	check(not dossiers.get_node("%ConfrontButton").disabled, "deux éléments sélectionnés : on peut confronter")
	dossiers.get_node("%ConfrontButton").pressed.emit()
	check(dossiers.get_node("%ConfrontResult").text.begins_with("Aucune"), "carte et présence : aucune incohérence")
	dossiers.get_node("%NotebookList").get_node("Noted_f_report_presence").pressed.emit()
	dossiers.get_node("%NotebookList").get_node("Noted_f_log_trip").pressed.emit()
	dossiers.get_node("%ConfrontButton").pressed.emit()
	check(dossiers.get_node("%ConfrontResult").text.begins_with("CONTRADICTION"), "présence et train : contradiction établie")
	check(dossiers.get_node("%ProgressLabel").text.contains("Contradictions : 1"), "le compteur de contradictions s'affiche")

	dossiers.get_node("%ConclusionButton").pressed.emit()
	var conclusion: Node = dossiers.get_node("%ConclusionPanel")
	check(conclusion.visible and not dossiers.get_node("%DocumentPanel").visible, "le formulaire remplace la pièce")
	check(conclusion.get_node("%ConclusionSummary").get_parsed_text().contains("Présent à son poste"),
			"le formulaire rappelle la contradiction établie")
	check(conclusion.get_node("%SignButton").disabled, "signature impossible sans choix")
	check(conclusion.get_node("%VeritasAdvice").text.contains("indice de conformité 87")
			and conclusion.get_node("%VeritasAdvice").text.contains("Facteurs principaux :\n- Déplacement non déclaré"),
			"le formulaire affiche l'avis de VERITAS et ses facteurs")
	conclusion.get_node("%Choices").get_node("Choice_investigate").pressed.emit()
	conclusion.get_node("%SignButton").pressed.emit()
	await get_tree().process_frame
	check(desk.get_open_app() == "messages", "la réponse du supérieur s'affiche aussitôt")
	check(desk.windows.messages.current_message_id == "40921.investigate_found", "c'est la bonne réponse")
	check(desk.windows.messages.get_node("%MessageHeader").text.contains("enquête complémentaire accordée"),
			"l'objet du message est affiché")
	check(GameState.get_case_state("40921").status == GameState.CASE_UNDER_INVESTIGATION, "dossier en enquête complémentaire")
	desk.terminal.submit_command("dossiers")
	check(dossiers.get_node("%ConclusionButton").disabled, "on ne peut pas conclure deux fois")
	desk.terminal.submit_command("archives")
	check(desk.windows.archives.get_node("%ArchiveText").get_parsed_text().contains("40921"), "le rapport figure aux archives")
	desk.queue_free()
	await get_tree().process_frame


func test_end_day_in_desk() -> void:
	SaveManager.delete_save()
	var desk: Control = load("res://scenes/desk/desk.tscn").instantiate()
	get_tree().root.add_child(desk)
	await get_tree().process_frame
	desk.get_node("%EndDayButton").pressed.emit()
	check(GameState.day_index == 0, "première demande : avertissement, pas de changement de jour")
	check(desk.terminal.get_log_text().contains("sans conclusion : 40921"), "le terminal signale le dossier en attente")
	desk.get_node("%EndDayButton").pressed.emit()
	check(GameState.day_index == 1, "seconde demande : la journée se termine")
	check(desk.get_node("%DateLabel").text.begins_with("MARDI 4 NOVEMBRE 1986\n08h00"), "la date de l'en-tête avance, l'horloge repart")
	check(SaveManager.has_save(), "sauvegarde automatique en fin de journée")
	check(desk.terminal.get_log_text().contains("MARDI 4 NOVEMBRE 1986"), "le terminal ouvre une nouvelle session")
	check(desk.get_node("%DayTransition").visible, "l'écran de transition s'affiche")
	desk.terminal.submit_command("veritas")
	check(desk.terminal.get_log_text().contains("VERITAS : Dossier 40921"), "VERITAS répond au terminal")
	desk.terminal.submit_command("dossiers")
	check(desk.windows.dossiers.get_node("%CaseList").get_child_count() == 2, "le nouveau dossier apparaît dans la liste")
	desk.windows.dossiers.select_case("51307")
	check(desk.windows.dossiers.get_node("%DocumentTabs").get_child_count() == 4, "pièces de base du dossier 51307")
	desk.queue_free()
	await get_tree().process_frame


func test_friendly_desk() -> void:
	SaveManager.delete_save()
	var desk: Control = load("res://scenes/desk/desk.tscn").instantiate()
	get_tree().root.add_child(desk)
	await get_tree().process_frame
	check(desk.get_node("%ObjectiveBar").visible, "la barre d'objectif est affichée")
	check(desk.get_node("%ObjectiveText").text.contains("prise de fonction"), "premier objectif : le message de Mazur")
	check(desk.current_step.target == "messages", "le bouton Messages est signalé")
	check(desk.get_node("%DossiersButton").text.contains("1 dossier(s) à traiter"), "le bouton Dossiers résume la situation")
	check(desk.get_node("%DossiersButton").tooltip_text != "", "les boutons ont une info-bulle")
	check(not desk.has_unsaved_changes, "rien à sauvegarder à l'arrivée")
	desk.terminal.submit_command("dossiers")
	desk.windows.dossiers.select_case("40921")
	desk.windows.dossiers.note_fact("f_identity_card")
	check(desk.get_node("%Toast").visible and desk.get_node("%ToastLabel").text.contains("carnet"), "notification après avoir noté")
	check(desk.windows.dossiers.get_node("%FactsPanel").visible, "les éléments notables restent visibles sous la pièce")
	check(desk.has_unsaved_changes, "des changements non sauvegardés")
	desk.windows.dossiers.close()
	desk.get_node("%MenuButton").pressed.emit()
	await get_tree().process_frame
	check(desk.is_inside_tree() and not desk.terminal.get_log_text().contains("Fermeture de session"), "première déconnexion : on reste au bureau")
	check(desk.terminal.get_log_text().contains("non sauvegardées"), "le terminal prévient de la perte")
	Settings.guidance = false
	desk._refresh_objective()
	check(not desk.get_node("%ObjectiveBar").visible, "l'aide se désactive dans les paramètres")
	Settings.guidance = true
	desk.queue_free()
	await get_tree().process_frame


func test_time_in_desk() -> void:
	var desk: Control = load("res://scenes/desk/desk.tscn").instantiate()
	get_tree().root.add_child(desk)
	await get_tree().process_frame
	desk.terminal.submit_command("dossiers")
	var dossiers_window = desk.windows.dossiers
	dossiers_window.select_case("40921")
	check(dossiers_window.get_node("%RequestButton").text == "DEMANDER (1 h)" and not dossiers_window.get_node("%RequestButton").disabled,
			"bouton de demande de pièce")
	dossiers_window.get_node("%RequestButton").pressed.emit()
	check(dossiers_window.get_node("%RequestButton").text == "DEMANDE EN COURS" and dossiers_window.get_node("%RequestButton").disabled,
			"la demande est en cours")
	dossiers_window.get_node("%ConsultButton").pressed.emit()
	check(dossiers_window.get_node("%ConsultButton").text == "CONSULTÉ" and GameState.hours_used == 2, "consultation : 2 heures employées")
	check(desk.get_node("%DateLabel").text.ends_with("10h00  //  6 h de service restantes"), "l'horloge avance")
	desk.queue_free()
	await get_tree().process_frame
