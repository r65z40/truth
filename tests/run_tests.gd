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
		"test_veritas",
		"test_terminal_command_parsing",
		"test_main_menu_scene",
		"test_desk_scene_flow",
		"test_full_session_flow",
		"test_investigation_and_conclusion_flow",
		"test_end_day_in_desk",
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
	check(FictionalCalendar.format_short(29) == "02.12.1986", "jour 29 : %s" % FictionalCalendar.format_short(29))


# --- État de la partie -------------------------------------------------------

func test_new_game_defaults() -> void:
	check(GameState.indicators == GameState.INITIAL_INDICATORS, "indicateurs initiaux")
	check(GameState.get_rank_title() == "Inspecteur de 3e classe", "grade initial")
	check(GameState.cases.has("40921"), "le dossier 40921 est assigné")
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
	check(fired_ids == ["40921_reminder", "daily_bulletin_1"], "rappel et bulletin : %s" % [fired_ids])
	check(GameState.get_indicator("suspicion") == 23, "le retard éveille la suspicion")
	check(GameState.get_unread_count() == unread + 2, "deux nouveaux messages")
	check(GameState.messages[-1].date_label == "04.11.1986", "messages datés du jour")
	check(days == [1], "signal day_started émis")
	check(GameState.end_day().is_empty(), "les événements ne se répètent pas le lendemain")
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
	check(ids == ["daily_bulletin_1"], "enquête sans fondement : seulement le bulletin")
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


func test_veritas() -> void:
	var case_data := CaseLibrary.get_case("40921")
	for document in case_data.documents:
		check(Veritas.document_remark(document) != "", "VERITAS commente la pièce %s" % document.id)
	var advice := Veritas.recommendation(case_data)
	check(advice.decision_id == "arrest" and advice.confidence == 87, "VERITAS recommande l'arrestation à 87 %")
	check(Veritas.terminal_reply(GameState.cases).contains("4 pièce(s) non consultée(s)"), "VERITAS signale les pièces non lues")
	for document in case_data.documents:
		GameState.mark_document_viewed("40921", document.id)
	check(Veritas.terminal_reply(GameState.cases).contains("Indice de confiance : 87"), "puis donne sa recommandation")
	GameState.apply_decision("40921", "arrest")
	check(Veritas.terminal_reply(GameState.cases).begins_with("Aucun dossier"), "rien à signaler une fois le dossier traité")
	check(GameState.decisions[0].veritas_agreed == true, "accord avec VERITAS mémorisé")


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
	check(desk.get_node("%DateLabel").text == "LUNDI 3 NOVEMBRE 1986", "date affichée dans l'en-tête")
	check(desk.get_node("%RankLabel").text == "INSPECTEUR DE 3E CLASSE", "grade affiché")
	check(desk.get_node("%MessagesButton").text.contains("(2)"), "compteur de messages non lus")
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
	check(desk.get_node("%MessagesButton").text.contains("(1)"), "le compteur se met à jour")
	desk.terminal.submit_command("archives")
	check(desk.get_open_app() == "archives", "une seule fenêtre ouverte à la fois")

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
	desk.get_node("%MenuButton").pressed.emit()
	await _wait_for_scene("MainMenu")
	menu = get_tree().current_scene
	check(menu.name == "MainMenu", "DÉCONNEXION ramène au menu")
	check(not menu.get_node("%ContinueButton").disabled, "« Continuer » est actif après sauvegarde")
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
	dossiers.select_document("work_report")
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
	check(conclusion.get_node("%VeritasAdvice").text.contains("87 %"), "le formulaire affiche l'avis de VERITAS")
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
	check(desk.get_node("%DateLabel").text == "MARDI 4 NOVEMBRE 1986", "la date de l'en-tête avance")
	check(SaveManager.has_save(), "sauvegarde automatique en fin de journée")
	check(desk.terminal.get_log_text().contains("MARDI 4 NOVEMBRE 1986"), "le terminal ouvre une nouvelle session")
	check(desk.get_node("%DayTransition").visible, "l'écran de transition s'affiche")
	desk.terminal.submit_command("veritas")
	check(desk.terminal.get_log_text().contains("VERITAS : Dossier 40921"), "VERITAS répond au terminal")
	desk.queue_free()
	await get_tree().process_frame
