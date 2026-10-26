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
		"test_evenings_file_is_valid",
		"test_evenings",
		"test_career_evaluation",
		"test_field_scenes_are_valid",
		"test_field_background_image",
		"test_field_interrogation",
		"test_field_search",
		"test_field_rooms",
		"test_field_bakery_visit",
		"test_field_benes_search",
		"test_field_chorale",
		"test_fate_card",
		"test_comparison",
		"test_field_stages_are_valid",
		"test_field_stage_3d",
		"test_act_review",
		"test_veritas",
		"test_veritas_model",
		"test_veritas_acte2",
		"test_ministry_record",
		"test_case_53118",
		"test_case_53402",
		"test_case_53517",
		"test_case_briefings",
		"test_scene_gallery",
		"test_document_field_icons",
		"test_tutorial_bubble_fades",
		"test_coach_bubble_can_be_closed",
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
		"test_act_end_in_desk",
		"test_field_in_desk",
		"test_failed_confrontation_feedback",
		"test_friendly_desk",
		"test_desktop_windows",
		"test_pixel_icons",
		"test_document_windows",
		"test_document_passages",
		"test_desk_apps",
		"test_news",
		"test_localization",
		"test_music_rules",
		"test_music_player",
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


## Passages à noter : chaque citation existe dans le texte de sa pièce, balisée une fois.
func test_localization() -> void:
	# Le français est la langue source : clé = texte français.
	Localization.set_locale("en")
	check(TranslationServer.translate("NOUVELLE PARTIE") == "NEW GAME", "l'interface se traduit en anglais")
	check(TranslationServer.translate("Texte sans traduction") == "Texte sans traduction", "une chaîne non traduite reste en français")
	# Surcouche de dossier : fusion par id, repli sur le français.
	var base := {"id": "x", "title": "Titre FR", "summary": "Résumé FR",
			"documents": [{"id": "d1", "title": "Pièce FR", "facts": [{"id": "f1", "label": "FR"}]}]}
	var overlay := {"title": "Title EN", "documents": [{"id": "d1", "facts": [{"id": "f1", "label": "EN"}]}]}
	var merged: Dictionary = Localization._merge(base.duplicate(true), overlay)
	check(merged.title == "Title EN" and merged.summary == "Résumé FR", "le titre est traduit, le résumé reste en français")
	check(merged.documents[0].title == "Pièce FR" and merged.documents[0].facts[0].label == "EN",
			"la fusion apparie les pièces et les éléments par id")
	# Sans surcouche livrée, un dossier reste en français même en anglais.
	check(CaseLibrary.get_case("40921").title == "Citoyen n° 40921", "sans surcouche, le dossier reste en français")
	Localization.set_locale("fr")
	check(CaseLibrary.get_case("40921").title == "Citoyen n° 40921" and not Localization.is_translated(),
			"retour au français : langue source")


func test_news() -> void:
	var state := NewsWindow.current_state()
	var first := NewsRules.edition(state)
	check(first.articles.size() == NewsRules.MAX_ARTICLES, "une édition compte 3 articles")
	check(first.articles[0].id == "d0_centrale_plan" and first.number == 311, "lundi : la une sur la Centrale n° 3, numéro 311")
	check(NewsRules.edition(state).articles == first.articles, "le choix des articles est déterministe")
	# Décision prise la veille : elle fait la une, à la manière du régime.
	var decided := {"day_index": 1, "flags": {}, "cases": {}, "decisions": [{"case_id": "40921", "decision_id": "arrest", "day_index": 0}]}
	var titles: Array = NewsRules.edition(decided).articles.map(func(a: Dictionary) -> String: return a.id)
	check(titles[0] == "d1_40921_arrest", "l'arrestation de SEDLAR fait la une le lendemain")
	decided.day_index = 2
	titles = NewsRules.edition(decided).articles.map(func(a: Dictionary) -> String: return a.id)
	check(not "d1_40921_arrest" in titles and "d2_horvat" in titles, "la nouvelle ne revient pas le surlendemain ; l'indice HORVAT paraît mercredi")
	decided.decisions[0].decision_id = "close"
	decided.day_index = 1
	titles = NewsRules.edition(decided).articles.map(func(a: Dictionary) -> String: return a.id)
	check(not "d1_40921_arrest" in titles and not "d1_40921_investigate" in titles, "dossier classé : le journal se tait")
	check(NewsRules.are_conditions_met({"after_decision": {"case": "40921"}}, decided), "sans liste : n'importe quelle décision")
	check(NewsRules.edition({"day_index": 30, "flags": {}, "cases": {}}).articles.size() == 2, "un jour sans actualité : les articles par défaut")
	# Les dossiers de l'acte 2 ont aussi leur conséquence au journal, en langue officielle.
	var choir := {"day_index": 7, "flags": {}, "cases": {}, "decisions": [{"case_id": "53118", "decision_id": "arrest_all", "day_index": 6}]}
	check("d_53118_arrest" in NewsRules.edition(choir).articles.map(func(a: Dictionary) -> String: return a.id),
			"la déportation de la chorale fait la une, en version officielle")
	var ids := {}
	for article in NewsRules.data().articles:
		check(not ids.has(article.id) and article.get("headline", "") != "" and article.get("body", "") != "", "article %s complet et unique" % article.id)
		ids[article.id] = true

	var desk: Control = load("res://scenes/desk/desk.tscn").instantiate()
	get_tree().root.add_child(desk)
	await get_tree().process_frame
	check(desk.get_node("%NewsButton").badge == 1, "nouvelle édition : pastille sur le journal")
	var hours := GameState.hours_used
	desk.get_node("%NewsButton").pressed.emit()
	check(desk.get_open_app() == "news" and desk.get_node("%NewsButton").badge == 0, "le journal s'ouvre et la pastille disparaît")
	check(desk.windows.news.get_node("%Articles").get_node_or_null("Article_d0_centrale_plan") != null, "la une est affichée")
	var emblem := desk.windows.news._masthead.get_parent().get_node_or_null("Emblem") as TextureRect
	check(emblem != null and emblem.texture == PixelIcons.get_icon("news", 4), "le journal affiche son emblème au-dessus du bandeau")
	check(GameState.hours_used == hours, "lire le journal ne coûte pas d'heures")
	desk.queue_free()
	await get_tree().process_frame


func test_desk_apps() -> void:
	# VERITAS (logique pure) : rapport incomplet tant que des pièces restent à lire.
	var view := GameState.get_case_view("40921")
	var report := Veritas.case_report(view, GameState.get_case_state("40921"))
	check(report.unread == view.documents.size() and not report.advice.is_empty(), "VERITAS compte les pièces non lues")
	var text := VeritasWindow.report_bbcode(report)
	check(text.begins_with("ANALYSE INCOMPLÈTE : %d pièce(s)" % report.unread) and text.contains("RECOMMANDATION :"),
			"rapport incomplet : avertissement puis recommandation")
	check(VeritasWindow.report_bbcode({"unread": 0, "advice": {}, "factors": []}).contains("ne formule pas"),
			"sans facteur : pas de recommandation")
	check(Veritas.analysis_steps().size() >= 3, "étapes du calcul lues dans data/veritas.json")
	for icon in ["veritas", "mail_open", "lock"]:
		check(PixelIcons.has_icon(icon), "icône %s dessinée" % icon)

	var desk: Control = load("res://scenes/desk/desk.tscn").instantiate()
	get_tree().root.add_child(desk)
	await get_tree().process_frame
	var veritas: VeritasWindow = desk.windows.veritas
	desk.get_node("%VeritasButton").pressed.emit()
	check(desk.get_open_app() == "veritas", "l'icône VERITAS ouvre le programme")
	check(veritas.get_node("%RunButton").disabled, "aucun dossier choisi : analyse impossible")
	var list: VBoxContainer = veritas.get_node("%VeritasCaseList")
	check(list.get_node_or_null("Case_40921") != null, "les dossiers en attente sont proposés")
	list.get_node("Case_40921").pressed.emit()
	check(not veritas.get_node("%RunButton").disabled, "dossier choisi : on peut lancer l'analyse")
	var hours := GameState.hours_used
	veritas.analysis_time = 0.2
	veritas.get_node("%RunButton").pressed.emit()
	check(veritas.is_running and veritas.get_node("%RunButton").disabled, "le calcul prend un instant")
	await get_tree().create_timer(0.4).timeout
	check(not veritas.is_running and veritas.get_node("%AnalysisLog").get_parsed_text().contains("ANALYSE INCOMPLÈTE"),
			"le verdict s'affiche à la fin du calcul")
	check(GameState.hours_used == hours, "VERITAS ne coûte pas d'heures")

	# Courrier : enveloppes fermées pour les plis non lus.
	desk.get_node("%MessagesButton").pressed.emit()
	await get_tree().process_frame
	var mail_list: VBoxContainer = desk.windows.messages.get_node("%MessageList")
	var unread_buttons := mail_list.get_children().filter(func(b: Node) -> bool: return b.get_meta("unread", false))
	check(unread_buttons.size() == GameState.get_unread_count(), "un pli non lu par message non lu")
	check(desk.windows.messages.get_node("%ListTitle").text.contains("non lu") == (GameState.get_unread_count() > 0),
			"le titre de la liste compte les plis non lus")
	check(desk.windows.messages.get_guide_target("") == (unread_buttons[0] if not unread_buttons.is_empty() else null),
			"la bulle d'aide pointe le premier pli non lu")

	# Archives vides en début de partie, fonds historique verrouillé.
	desk.get_node("%ArchivesButton").pressed.emit()
	check(desk.windows.archives.get_node("%ArchiveEmpty").visible and ArchivesWindow.archived_cases().is_empty(),
			"aucun rapport aux archives au départ")
	check(desk.windows.archives.get_node("%ClearanceLabel").text.contains("NIVEAU 3"), "le fonds historique est verrouillé")
	desk.queue_free()
	await get_tree().process_frame


func test_document_passages() -> void:
	var all_found := true
	for case_id in CaseLibrary.get_case_ids():
		for document in CaseLibrary.get_case(case_id).documents:
			var bbcode := DossiersWindow.render_document_bbcode(document, {"noted": [], "link": "8e1f1f", "highlight": "edc76b"})
			for fact in DossiersWindow.quoted_facts(document):
				var found: bool = bbcode.count("[url=fact:%s]" % fact.id) == 1
				if not found:
					print("  citation introuvable : %s/%s/%s" % [case_id, document.id, fact.id])
				all_found = all_found and found
	check(all_found, "chaque citation se trouve une fois dans le texte de sa pièce")
	var intercept := CaseLibrary.get_document(CaseLibrary.get_case("40921"), "intercept")
	var plain := DossiersWindow.render_document_bbcode(intercept)
	check(not plain.contains("[url="), "sans réglage : texte simple, sans lien")
	var marked := DossiersWindow.render_document_bbcode(intercept, {"noted": ["f_intercept_papers"], "link": "8e1f1f", "highlight": "edc76b"})
	check(marked.contains("[url=fact:f_intercept_papers][bgcolor=#edc76b]Apporte les papiers de maman. Tous.[/bgcolor][/url]"),
			"élément noté : passage surligné")
	check(marked.contains("[url=fact:f_intercept_chief][color=#8e1f1f][u]"), "élément à noter : passage souligné")
	check(marked.contains("[lb]Fin de l'appel]"), "le texte autour des passages reste échappé")
	var quoted := 0
	for case_id in CaseLibrary.get_case_ids():
		for document in CaseLibrary.get_case(case_id).documents:
			quoted += DossiersWindow.quoted_facts(document).size()
	check(quoted >= 50, "les dossiers de l'acte 1 ont des passages à noter (%d)" % quoted)


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
	# Les gens reviennent (levier 2) : la décision sur la chorale a des échos.
	var choir_ids: Array = EventRules.due_events(
			{"day_index": 11, "flags": {"53118.choir_arrested": true}, "cases": {}, "fired_events": []}
			).map(func(e: Dictionary) -> String: return e.id)
	check("53118_kolb_recidive" in choir_ids, "KOLB récidive après l'arrestation de la chorale sur sa parole")
	check(not "53118_cleared_denounced" in choir_ids, "classer ne s'applique pas quand on a arrêté")
	var cleared_ids: Array = EventRules.due_events(
			{"day_index": 11, "flags": {"53118.choir_cleared": true}, "cases": {}, "fired_events": []}
			).map(func(e: Dictionary) -> String: return e.id)
	check("53118_cleared_denounced" in cleared_ids, "classer la chorale expose l'inspecteur (KOLB le dénonce)")


func test_end_day_without_decision() -> void:
	var days := []
	var on_day := func(day: int, _events: Array) -> void: days.append(day)
	GameState.day_started.connect(on_day)
	var unread := GameState.get_unread_count()
	var fired := GameState.end_day()
	var fired_ids := fired.map(func(e: Dictionary) -> String: return e.id)
	check(GameState.day_index == 1 and GameState.get_date_long() == "MARDI 4 NOVEMBRE 1986", "on passe au mardi 4 novembre")
	check(fired_ids == ["assign_51307", "features_day_2", "51307_milice_plea", "40921_reminder", "daily_bulletin_1"],
			"nouveau dossier, habilitations, pression de la Milice, rappel et bulletin : %s" % [fired_ids])
	check(GameState.cases.has("51307"), "le dossier 51307 est attribué")
	check(GameState.get_indicator("suspicion") == 23, "le retard éveille la suspicion")
	check(GameState.get_unread_count() == unread + 5, "cinq nouveaux messages")
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
	check(ids == ["assign_51307", "features_day_2", "51307_milice_plea", "daily_bulletin_1"], "enquête sans fondement : pas de suite propre au 40921")
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
	check(not GameState.request_document("40921", "medical_halvek") and not GameState.consult_superior("40921"),
			"premier jour : ni demande ni consultation")
	GameState.end_day()
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


func test_evenings_file_is_valid() -> void:
	var data := EveningRules.get_data()
	check(not data.get("overtime", {}).get("text", "").is_empty(), "texte de soirée perdue")
	var days := []
	for evening in data.evenings:
		days.append(int(evening.day))
		check(evening.get("intro", "") != "" and evening.actions.size() >= 2, "soirée %d : introduction et au moins 2 actions" % evening.day)
		var unconditional := 0
		for action in evening.actions:
			check(action.has("id") and action.has("label") and action.has("kind") and not action.get("results", []).is_empty(),
					"soirée %d, action %s complète" % [evening.day, action.get("id", "?")])
			if not action.has("conditions"):
				unconditional += 1
			var last: Dictionary = action.results[-1]
			check(not last.has("conditions"), "%s : la dernière variante est sans condition" % action.id)
		check(unconditional >= 2, "soirée %d : au moins 2 actions toujours possibles" % evening.day)
	check(days == [0, 1, 2, 3, 4], "une soirée par jour de l'acte 1 : %s" % [days])


func test_evenings() -> void:
	GameState.new_game()
	check(GameState.has_evening_pending(), "une soirée est prévue le premier soir")
	check(GameState.choose_evening_action("benes_visit").is_empty(), "action d'un autre soir refusée")
	var result := GameState.choose_evening_action("lena_answer")
	check(result.text.contains("brouillons"), "texte du résultat")
	check(GameState.flags.get("lena.letter_answered") == true and GameState.flags.get("lena.asked_permit") == true,
			"drapeaux de l'action et de la soirée")
	check(not GameState.has_evening_pending() and GameState.choose_evening_action("radio_0").is_empty(), "une seule action par soir")
	GameState.end_day()
	check(not "sedlar_visit" in GameState.get_evening_actions().map(func(a: Dictionary) -> String: return a.id),
			"pas de visite de Vera SEDLAR sans arrestation")
	result = GameState.choose_evening_action("lena_call")
	check(result.text.contains("Merci pour l'autorisation"), "la variante dépend de la lettre envoyée")
	# La radio écoutée deux fois sans ménager le gardien : signalement.
	GameState.new_game()
	GameState.choose_evening_action("radio_0")
	GameState.end_day()
	var suspicion := GameState.get_indicator("suspicion")
	result = GameState.choose_evening_action("radio_1")
	check(GameState.flags.get("adler.reported_radio") == true and result.text.contains("porte du gardien"), "deuxième écoute : ADLER signale")
	check(GameState.get_indicator("suspicion") == suspicion + 3, "le signalement coûte de la suspicion")
	var ids := GameState.end_day().map(func(e: Dictionary) -> String: return e.id)
	check("evening_radio_reported" in ids, "note de Mazur le lendemain")
	# Avec ADLER ménagé, pas de signalement.
	GameState.new_game()
	GameState.choose_evening_action("adler_0")
	GameState.end_day()
	GameState.choose_evening_action("radio_1")
	GameState.end_day()
	GameState.choose_evening_action("radio_2")
	check(GameState.flags.get("adler.reported_radio") != true, "le gardien ménagé ne signale pas")
	# Heures supplémentaires : soirée perdue.
	GameState.new_game()
	GameState.hours_used = 9
	GameState.overtime_days = [0]
	check(GameState.choose_evening_action("lena_answer").is_empty(), "pas d'action après des heures supplémentaires")
	check(GameState.lose_evening().contains("vingt heures") and not GameState.has_evening_pending(), "soirée perdue")
	check(GameState.flags.get("lena.asked_permit") == true, "la lettre de Lena est quand même arrivée")
	# Autorisation de stage pour Lena : conséquence vendredi et lundi.
	GameState.new_game()
	for day in 3:
		GameState.end_day()
	GameState.choose_evening_action("lena_permit_call")
	GameState.end_day()
	check(GameState.choose_evening_action("lena_news").text.contains("Avis favorable"), "Lena obtient son stage")
	ids = GameState.end_day().map(func(e: Dictionary) -> String: return e.id)
	check("evening_lena_permit_noted" in ids and GameState.flags.get("lena.leverage") == true, "la recommandation est notée au dossier")
	# Sauvegarde.
	var saved := GameState.to_dict()
	GameState.new_game()
	GameState.from_dict(JSON.parse_string(JSON.stringify(saved)))
	check(GameState.evenings.size() == 2 and GameState.evenings["3"].action == "lena_permit_call", "soirées sauvegardées")
	GameState.new_game()


func test_field_scenes_are_valid() -> void:
	for case_id in ["40921", "51307", "52044", "52310", "53118", "53402", "53517"]:
		var case_data := CaseLibrary.get_case(case_id)
		var scene := FieldRules.scene_for_case(case_data)
		check(scene.case_id == case_id and int(scene.turns) > 0 and scene.has("intro") and scene.has("outro"), "%s : scène de terrain" % scene.id)
		check(WorkTime.cost(scene.time_action) == 2, "%s : 2 heures" % scene.id)
		if scene.has("image"):
			check(scene.image is String and (scene.image as String).begins_with("res://"), "%s : chemin d'image valide" % scene.id)
		var room_ids: Array = scene.get("rooms", []).map(func(r: Dictionary) -> String: return r.get("id", ""))
		for room: Dictionary in scene.get("rooms", []):
			check(room.get("image", "").begins_with("res://"), "%s : pièce %s avec image" % [scene.id, room.get("id", "")])
			for door: Dictionary in room.get("doors", []):
				check(door.get("to", "") in room_ids, "%s : la porte de %s mène à une pièce connue" % [scene.id, room.get("id", "")])
				check(_spot_in_bounds(door.get("spot", [0, 0, 0, 0])), "%s : porte de %s dans le cadre" % [scene.id, room.get("id", "")])
		for result in FieldRules.all_options(scene) + scene.get("presentations", []):
			for fact_id in result.get("note", []):
				var fact := CaseLibrary.get_fact(case_data, fact_id)
				check(fact.get("conditions", {}).get("requires_flags", []) == [FieldRules.flag_for(scene, result.id)],
						"%s : l'élément %s dépend du choix %s" % [scene.id, fact_id, result.id])
			for fact_id in result.get("facts", []):
				check(not CaseLibrary.get_fact(case_data, fact_id).is_empty(), "%s : élément présenté %s existant" % [scene.id, fact_id])
			if result.has("spot"):
				check(_spot_in_bounds(result.spot), "%s : zone %s dans le cadre" % [scene.id, result.id])
		check(CaseLibrary.validate_case(case_data).is_empty(), "%s : dossier toujours valide" % case_id)


func test_field_background_image() -> void:
	var art := FieldArt.new()
	# Un fichier présent sert d'image de fond de la scène de terrain...
	art.image_path = "res://ui/icons/f_person.png"
	check(art.has_image(), "une image existante devient le fond de la scène")
	# ...un fichier absent retombe sur le décor dessiné, sans casser la scène.
	art.image_path = "res://assets/field/inexistante.webp"
	check(not art.has_image(), "une image manquante retombe sur le dessin")
	art.image_path = ""
	check(not art.has_image(), "pas d'image de fond par défaut")
	# Les zones en fractions se calent sur l'image affichée, quelle que soit la taille.
	check(FieldArt.is_fractional([0.1, 0.2, 0.3, 0.4]) and not FieldArt.is_fractional([40, 150, 120, 50]),
			"une zone est reconnue comme fraction ou comme pixels")
	art.image_path = "res://ui/icons/f_person.png"
	art.size = Vector2(640, 360)
	var img := art.image_rect()
	var r := art.to_local_rect([0.25, 0.5, 0.5, 0.25])
	check(is_equal_approx(r.position.x, img.position.x + img.size.x * 0.25) and is_equal_approx(r.size.x, img.size.x * 0.5),
			"une zone en fractions tombe exactement sur l'image")
	# En mode vidéo, FieldArt est transparent et les zones couvrent tout le cadre 16:9.
	art.video_mode = true
	check(art.image_rect() == Rect2(Vector2.ZERO, art.size), "en mode vidéo, les zones couvrent tout le cadre")
	art.video_mode = false
	art.free()


## Une zone est-elle dans le cadre (fractions 0..1, ou pixels du repère 640 x 300) ?
func _spot_in_bounds(area: Array) -> bool:
	if FieldArt.is_fractional(area):
		return area[0] >= 0.0 and area[1] >= 0.0 and area[0] + area[2] <= 1.0 and area[1] + area[3] <= 1.0
	return area[0] >= 0 and area[1] >= 0 and area[0] + area[2] <= FieldArt.CANVAS.x and area[1] + area[3] <= FieldArt.CANVAS.y


func test_field_interrogation() -> void:
	GameState.new_game()
	check(not GameState.can_start_field("40921"), "pas de terrain le premier jour")
	GameState.end_day()
	check(GameState.can_start_field("51307"), "audition d'ORLIK possible le deuxième jour")
	var before := _visible_document_ids("51307")
	check(not "orlik_audition" in before, "pas de procès-verbal avant l'audition")
	check(not GameState.start_field("51307").is_empty() and GameState.hours_used == 2, "l'audition coûte 2 heures")
	check(not GameState.can_start_field("51307"), "une seule audition")
	check(GameState.flags.get("milice.orlik_questioned") == true, "la Milice saura")
	var ids := func() -> Array: return GameState.get_field_options("audition_51307").map(func(o: Dictionary) -> String: return o.id)
	check(not "q_petras" in ids.call(), "pas de question sur PETRAS sans élément noté")
	var result := GameState.field_choose("audition_51307", "q_certificates")
	check(result.text.contains("L'horloge tombe en panne") and "f_aud_clock" in GameState.get_case_state("51307").noted_facts,
			"réponse notée dans le carnet")
	var view := GameState.get_case_view("51307")
	var audition := CaseLibrary.get_document(view, "orlik_audition")
	check(audition.facts.map(func(f: Dictionary) -> String: return f.id) == ["f_aud_clock"], "le procès-verbal ne contient que ce qui a été dit")
	check(GameState.field_present("audition_51307", "f_clock_ok").is_empty(), "on ne présente que des éléments notés")
	GameState.note_fact("51307", "f_clock_ok")
	result = GameState.field_present("audition_51307", "f_clock_ok")
	check(result.text.contains("paquet de café") and GameState.flags.get("51307.orlik_admitted") == true, "le relevé fait céder ORLIK")
	check(GameState.confront_facts("51307", "f_aud_clock", "f_clock_ok") == "clock.status.october", "sa première version se contredit")
	result = GameState.field_present("audition_51307", "f_clock_ok")
	check(result.text.contains("Je ne vois pas le rapport"), "une présentation ne marche qu'une fois")
	GameState.note_fact("51307", "f_cert_petras")
	check("q_petras" in ids.call(), "élément sur PETRAS noté : question possible")
	result = GameState.field_choose("audition_51307", "q_petras")
	check(not result.finished, "quatre tours sur cinq")
	result = GameState.field_choose("audition_51307", "q_sedlar")
	check(result.finished and GameState.get_field_options("audition_51307").is_empty(), "cinq tours, puis l'audition s'arrête")
	check(GameState.confront_facts("51307", "f_aud_petras_once", "f_cert_petras") == "petras.days", "« une fois » contre deux certificats")
	var fired := GameState.end_day().map(func(e: Dictionary) -> String: return e.id)
	check("field_51307_brother" in fired, "le frère d'ORLIK écrit le lendemain")
	# Le nom de code met fin à l'audition.
	GameState.new_game()
	GameState.end_day()
	GameState.start_field("51307")
	GameState.get_case_state("51307").noted_facts.append("f_kremer_informant")
	var suspicion := GameState.get_indicator("suspicion")
	result = GameState.field_present("audition_51307", "f_kremer_informant")
	check(result.finished and GameState.get_indicator("suspicion") == suspicion + 2, "CHAUDRON : audition interrompue, suspicion")
	var saved := GameState.to_dict()
	GameState.new_game()
	GameState.from_dict(JSON.parse_string(JSON.stringify(saved)))
	check(GameState.get_field_state("audition_51307").finished and GameState.get_field_state("audition_51307").turns_used == 1,
			"état du terrain sauvegardé")
	GameState.new_game()


func test_field_search() -> void:
	GameState.new_game()
	GameState.apply_decision("40921", "close")
	GameState.end_day()
	check(not GameState.can_start_field("40921"), "dossier clos sans arrestation : pas de perquisition")
	GameState.new_game()
	GameState.apply_decision("40921", "arrest")
	GameState.end_day()
	check(GameState.can_start_field("40921"), "après l'arrestation : perquisition d'usage")
	var loyalty := GameState.get_indicator("loyalty")
	GameState.start_field("40921")
	check(GameState.get_indicator("loyalty") == loyalty + 1 and GameState.flags.get("40921.home_searched") == true, "le zèle est noté")
	check(GameState.field_choose("40921_inconnu", "drawer").is_empty(), "scène inconnue refusée")
	GameState.field_choose("search_40921", "stove")
	check(GameState.flags.get("heure_juste.sign_stove") == true, "indice de L'HEURE JUSTE trouvé")
	GameState.field_choose("search_40921", "child_bed")
	check(GameState.flags.get("40921.family_humiliated") == true, "fouiller le lit de l'enfant humilie la famille")
	check(GameState.field_leave("search_40921").contains("judas"), "on peut partir avant la fin")
	check(GameState.get_field_options("search_40921").is_empty(), "plus rien à fouiller")
	var found: Array = CaseLibrary.get_document(GameState.get_case_view("40921"), "search_report").facts.map(func(f: Dictionary) -> String: return f.id)
	check(found == ["f_srch_clock_sign", "f_srch_drawing"], "procès-verbal : ce qui a été trouvé")
	var fired := GameState.end_day().map(func(e: Dictionary) -> String: return e.id)
	check("field_40921_neighbours" in fired, "Vera SEDLAR écrit")
	GameState.new_game()


func test_field_rooms() -> void:
	# Logique pure : deux pièces, options à plat, appartenance des endroits.
	var scene := FieldRules.get_scene("search_40921")
	check(FieldRules.has_rooms(scene), "le 40921 est une perquisition à pièces")
	check(FieldRules.all_options(scene).size() == 6, "six endroits au total, toutes pièces confondues")
	check(FieldRules.start_room(scene).id == "salon", "on arrive dans le salon")
	check(FieldRules.room_of_option(scene, "stove") == "salon" and FieldRules.room_of_option(scene, "mattress") == "chambre",
			"chaque endroit appartient à une pièce")
	# Écran : on ne voit que la pièce courante, l'image suit, le budget est commun.
	GameState.new_game()
	Settings.field_3d = false
	var screen: FieldScreen = load("res://scenes/field/field_screen.tscn").instantiate()
	get_tree().root.add_child(screen)
	check(screen.preview("40921"), "aperçu de la perquisition")
	# Une vidéo absente ne se joue pas : la scène retombe sur l'image (puis le dessin).
	check(not screen._set_video("res://assets/field/inexistante.ogv") and not screen._set_video(""),
			"vidéo manquante : pas de lecture")
	var salon := screen.get_choice_ids()
	check("stove" in salon and not "mattress" in salon, "le salon ne propose que ses propres endroits")
	check(not screen.is_3d() and screen.get_node("%Art").visible \
			and (screen.get_node("%Art").image_path as String).ends_with("salon.webp"), "l'image du salon est affichée")
	check(screen._current_view().doors.size() == 1, "une porte mène à la chambre")
	screen._go_to_room("chambre")
	var chambre := screen.get_choice_ids()
	check("mattress" in chambre and not "stove" in chambre, "la chambre propose ses propres endroits")
	check((screen.get_node("%Art").image_path as String).ends_with("chambre.webp"), "l'image change avec la pièce")
	# Fouiller dans une pièce entame le budget partagé des deux.
	screen.choose("mattress")
	screen._go_to_room("salon")
	check(FieldRules.turns_left(scene, GameState.get_field_state("search_40921")) == 3,
			"une fouille entame le budget commun aux deux pièces")
	screen.queue_free()
	await get_tree().process_frame
	GameState.new_game()


## Fait passer les journées jusqu'à l'attribution du dossier.
func _advance_until_assigned(case_id: String) -> void:
	for i in 6:
		if GameState.cases.has(case_id):
			return
		GameState.end_day()


func test_field_bakery_visit() -> void:
	GameState.new_game()
	_advance_until_assigned("52044")
	check(GameState.can_start_field("52044"), "visite de la boulangerie possible")
	GameState.start_field("52044")
	check(GameState.flags.get("52044.bakery_visited") == true, "la visite est connue")
	GameState.field_choose("visit_52044", "cash_box")
	GameState.field_choose("visit_52044", "back_room")
	check(GameState.flags.get("52044.kovac_bread") == true, "le pain mis de côté est relevé")
	var notebook: Array = GameState.get_case_state("52044").noted_facts
	check("f_vis_horvat_ticket" in notebook and "f_vis_bread" in notebook, "trouvailles notées dans le carnet")
	check(GameState.confront_facts("52044", "f_vis_horvat_ticket", "f_death_horvat") == "horvat.status",
			"le ticket d'un mort contredit le registre des décès")
	GameState.apply_decision("52044", "report_bureau")
	check(GameState.flags.get("52044.drazek_exposed") == true, "la visite suffit à mettre en cause le Bureau")
	var fired := GameState.end_day().map(func(e: Dictionary) -> String: return e.id)
	check(not "field_52044_drazek" in fired, "DRAZEK n'écrit plus une fois mis en cause")
	GameState.new_game()
	_advance_until_assigned("52044")
	GameState.start_field("52044")
	GameState.field_choose("visit_52044", "son_letter")
	check(GameState.flags.get("52044.family_humiliated") == true, "lire la lettre du fils humilie la gérante")
	fired = GameState.end_day().map(func(e: Dictionary) -> String: return e.id)
	check("field_52044_drazek" in fired and GameState.flags.get("52044.drazek_alerted") == true, "DRAZEK est prévenu de la visite")
	GameState.new_game()


func test_field_benes_search() -> void:
	GameState.new_game()
	_advance_until_assigned("52310")
	check(GameState.can_start_field("52310"), "perquisition quai des Tanneurs possible")
	var suspicion := GameState.get_indicator("suspicion")
	GameState.start_field("52310")
	GameState.field_choose("search_52310", "desk")
	GameState.field_choose("search_52310", "floorboard")
	check(GameState.flags.get("52310.manuscript_found") == true, "le manuscrit de VARGA est trouvé")
	var found: Array = CaseLibrary.get_document(GameState.get_case_view("52310"), "search_report").facts.map(func(f: Dictionary) -> String: return f.id)
	check(found == ["f_bns_lease", "f_bns_manuscript"], "procès-verbal : le bail et le manuscrit")
	check(GameState.confront_facts("52310", "f_var_address", "f_bns_lease") == "apt40.occupant",
			"le bail contredit le domicile déclaré")
	check(GameState.confront_facts("52310", "f_bns_manuscript", "f_cen_acrostic") == "poem.acrostic",
			"le manuscrit contredit l'analyse de la censure")
	GameState.apply_decision("52310", "identity_error")
	check(GameState.flags.get("52310.identity_questioned") == true and GameState.flags.get("kremer.contact") == true,
			"le bail suffit à prouver l'erreur d'identité")
	var fired := GameState.end_day().map(func(e: Dictionary) -> String: return e.id)
	check("field_52310_section7" in fired and GameState.get_indicator("suspicion") >= suspicion + 2, "la Section 7 sait")
	GameState.new_game()


func test_field_chorale() -> void:
	GameState.new_game()
	for i in 12:
		if GameState.cases.has("53118"):
			break
		GameState.end_day()
	check(GameState.cases.has("53118"), "le dossier de la chorale est attribué (acte 2, jour 5)")
	check(GameState.can_start_field("53118"), "la visite de la salle de la chorale est possible")
	GameState.start_field("53118")
	check(GameState.flags.get("53118.parish_visited") == true, "la visite de la paroisse est connue")
	check(GameState.flags.get("field.visit_53118.started") == true, "le drapeau de départ de la scène est posé")
	# Quatre endroits examinés : budget de tours exact (4).
	GameState.field_choose("visit_53118", "organ")
	GameState.field_choose("visit_53118", "entrance_book")
	GameState.field_choose("visit_53118", "board")
	GameState.field_choose("visit_53118", "vestry")
	var noted: Array = GameState.get_case_state("53118").noted_facts
	for fact_id in ["f_cho_vigil", "f_cho_register", "f_cho_permit", "f_cho_absent", "f_cho_kolb"]:
		check(fact_id in noted, "relevé sur place versé au carnet : %s" % fact_id)
	# Le compte rendu de visite n'existe qu'une fois la scène commencée.
	check(not CaseLibrary.get_document(GameState.get_case_view("53118"), "visit_report").is_empty(),
			"le compte rendu de visite apparaît après la visite")
	# Les relevés contredisent le signalement de l'informateur.
	check(GameState.confront_facts("53118", "f_cho_register", "f_sig_count") == "choir.list",
			"sept émargements contredisent les onze noms dénoncés")
	check(GameState.confront_facts("53118", "f_cho_permit", "f_sig_curfew") == "choir.curfew",
			"le permis de veillée contredit le rassemblement non autorisé")
	check(GameState.confront_facts("53118", "f_cho_kolb", "f_sig_single") == "choir.source",
			"le rival écarté du poste d'organiste éclaire la source unique")
	GameState.apply_decision("53118", "clear")
	check(GameState.flags.get("53118.choir_cleared") == true and GameState.flags.get("kremer.contact") == true,
			"la visite seule suffit à classer la veillée comme autorisée")
	GameState.new_game()


func test_fate_card() -> void:
	# Clore le dossier de départ : le sujet est relaxé, la carte reprend l'archive.
	GameState.new_game()
	_advance_until_assigned("40921")
	GameState.apply_decision("40921", "close")
	var fate := FateRules.fate_for(CaseLibrary.get_case("40921"), GameState.get_case_state("40921"))
	check(not fate.is_empty(), "une carte de destin existe après la signature")
	check(fate.subject_name == "SEDLAR, Anton Pavel", "nom du sujet repris du dossier")
	check(fate.stamp == "RELAXÉ", "clore le dossier : sujet relaxé")
	check(fate.line.begins_with("Dossier clos"), "ligne de conséquence = archive de la décision")
	check(not fate.photo.is_empty(), "photo d'identité du sujet réutilisée")
	check(fate.quote == "", "pas de citation sur ce dénouement")
	# Arrestation : sujet transféré, et une phrase de la famille accompagne le destin.
	GameState.new_game()
	_advance_until_assigned("40921")
	GameState.apply_decision("40921", "arrest")
	var harsh := FateRules.fate_for(CaseLibrary.get_case("40921"), GameState.get_case_state("40921"))
	check(harsh.stamp == "TRANSFÉRÉ", "arrestation : sujet transféré")
	check(harsh.quote != "", "une phrase de la famille accompagne l'arrestation")
	# Les dénouements les plus durs montrent la réalité crue (camp, mort), pas l'archive polie.
	var choir := FateRules.fate_for(CaseLibrary.get_case("53118"),
			{"decision": "arrest_all", "contradictions_found": []})
	check(choir.stamp == "DÉPORTÉS", "arrêter la chorale : déportation")
	check(choir.line.contains("camp de Dolenz") and choir.line.contains("meurt"),
			"la carte dit le camp et la mort, pas l'euphémisme officiel")
	# Sans décision, aucune carte.
	GameState.new_game()
	_advance_until_assigned("40921")
	check(FateRules.fate_for(CaseLibrary.get_case("40921"), GameState.get_case_state("40921")).is_empty(),
			"aucune carte tant que le dossier n'est pas signé")
	GameState.new_game()


func test_comparison() -> void:
	var case_data := CaseLibrary.get_case("52310")
	var comparison := ComparisonRules.get_comparison(case_data)
	check(not comparison.is_empty(), "VARGA propose une comparaison de pièces")
	var left := ComparisonRules.photo_of(case_data, comparison.left.photo_document)
	var right := ComparisonRules.photo_of(case_data, comparison.right.photo_document)
	check(not left.is_empty() and not right.is_empty(), "les deux clichés désignés existent")
	# Le trait décisif est le signe particulier : cicatrice en 1979, néant en 1986.
	var decisive := {}
	for point in comparison.points:
		if point.get("decisive", false):
			decisive = point
	check(decisive.get("field", "") == "mark", "le trait décisif est le signe particulier")
	var compared := ComparisonRules.compare_point(decisive, left, right)
	check(compared.differs and compared.decisive, "le signe particulier diffère entre les deux pièces")
	check(compared.left.contains("Cicatrice") and compared.right == "Néant", "les mentions exactes sont affichées")
	# Les mentions explicites priment sur le trait de photo.
	check(not ComparisonRules.compare_point({"detail_left": "X", "detail_right": "X"}, {}, {}).differs,
			"deux mentions identiques : aucune différence")
	# Notation : le joueur juge chaque trait. Tout juste = avantage ; une erreur = refus.
	var right_verdicts := {}
	for point in comparison.points:
		right_verdicts[point.id] = ComparisonRules.compare_point(point, left, right).differs
	check(ComparisonRules.grade(comparison, left, right, right_verdicts).all_ok, "jugement entièrement correct : validé")
	var missed := right_verdicts.duplicate()
	missed[decisive.id] = false
	var bad := ComparisonRules.grade(comparison, left, right, missed)
	check(not bad.all_ok and not bad.decisive_ok and bad.wrong == 1, "rater le trait décisif : refusé")
	var invented := right_verdicts.duplicate()
	invented["name"] = true
	check(ComparisonRules.grade(comparison, left, right, invented).wrong == 1,
			"inventer une différence sur un trait identique : erreur")
	var incomplete := right_verdicts.duplicate()
	incomplete.erase(decisive.id)
	check(not ComparisonRules.grade(comparison, left, right, incomplete).all_ok, "trait non jugé : incomplet")
	# Appliquer la comparaison établit la contradiction et verse les faits au carnet.
	GameState.new_game()
	var advantage := GameState.apply_comparison("52310")
	check(advantage.get("established", "") == "varga.mark", "comparer établit la contradiction varga.mark")
	var case_state := GameState.get_case_state("52310")
	check("varga.mark" in case_state.contradictions_found, "la contradiction est enregistrée")
	check("f_rc_mark" in case_state.noted_facts and "f_var_mark" in case_state.noted_facts,
			"les deux faits comparés sont versés au carnet")
	# L'avantage est concret : conclure à l'erreur d'identité est désormais « prouvé ».
	var proved := DecisionRules.resolve(case_data, case_state, "identity_error")
	check(proved.response_id == "identity_proved", "la comparaison débloque la conclusion prouvée")
	# Idempotent : réappliquer ne double rien et ne redonne pas d'avantage.
	check(GameState.apply_comparison("52310").is_empty(), "l'avantage ne s'acquiert qu'une fois")
	check(case_state.contradictions_found.count("varga.mark") == 1, "pas de doublon de contradiction")
	check(GameState.flags.get("52310.identity_compared") == true, "drapeau de comparaison posé")
	# Deuxième dossier : la chorale (53118), sans photo, contradiction exculpatoire.
	var choir_case := CaseLibrary.get_case("53118")
	var choir := ComparisonRules.get_comparison(choir_case)
	check(not choir.is_empty() and choir.establishes == "choir.curfew", "la chorale propose une comparaison exculpatoire")
	check(not choir.left.has("photo_document"), "comparaison de pièces sans portrait")
	var choir_verdicts := {}
	for point in choir.points:
		choir_verdicts[point.id] = ComparisonRules.compare_point(point, {}, {}).differs
	check(ComparisonRules.grade(choir, {}, {}, choir_verdicts).all_ok, "jugement correct de la chorale")
	var choir_advantage := GameState.apply_comparison("53118")
	check(choir_advantage.established == "choir.curfew", "la comparaison établit choir.curfew")
	var choir_state := GameState.get_case_state("53118")
	check("f_arc_permit" in choir_state.noted_facts and "f_arc_register" in choir_state.noted_facts,
			"permis et registre versés au carnet")
	check(DecisionRules.resolve(choir_case, choir_state, "clear").response_id == "clear_proved",
			"la comparaison débloque la relaxe prouvée de la chorale")
	GameState.new_game()


func test_career_evaluation() -> void:
	var rules := Career.act_rules(1)
	check(rules.cases == ["40921", "51307", "52044", "52310"] and int(rules.to_rank) == Career.Rank.INSPECTOR_2ND, "règle de l'acte 1")
	check(Career.act_rules(4).is_empty(), "pas encore de règle pour l'acte 4")
	var cases := {}
	for case_id in rules.cases:
		cases[case_id] = {"decision": "x", "contradictions_found": []}
	cases["40921"].contradictions_found = ["a"]
	cases["52310"].contradictions_found = ["b"]
	var state := {"indicators": {"loyalty": 50, "suspicion": 30}, "flags": {}, "cases": cases}
	check(Career.evaluate(rules, state).eligible, "4 dossiers conclus, 2 appuyés, loyal, peu surveillé : promotion")
	state.indicators.suspicion = 50
	check(not Career.evaluate(rules, state).eligible, "surveillance renforcée : pas de promotion")
	state.indicators.suspicion = 30
	state.indicators.loyalty = 44
	check(not Career.evaluate(rules, state).eligible, "loyauté à confirmer : pas de promotion")
	state.indicators.loyalty = 50
	cases["52310"].contradictions_found = []
	var result := Career.evaluate(rules, state)
	check(not result.eligible and not result.criteria[1].ok, "une seule conclusion appuyée : pas de promotion")
	state.flags["milice.favor_owed"] = true
	result = Career.evaluate(rules, state)
	check(result.eligible and result.bought, "la faveur de la Milice achète la promotion")
	cases["51307"].decision = ""
	check(not Career.evaluate(rules, state).eligible, "un dossier sans conclusion : pas de promotion")


func test_act_review() -> void:
	GameState.new_game()
	check(not GameState.has_act_review_pending(), "pas de revue le premier soir")
	for day in 4:
		GameState.end_day()
	var review := GameState.get_act_review()
	check(review.act == 1 and review.title == "LE ZÈLE" and review.subjects.size() == 4, "vendredi soir : revue de l'acte 1")
	check(review.subjects[0].decision == "Sans conclusion" and not review.evaluation.eligible, "sans conclusion, pas de promotion")
	check(review.letter.contains("maintenu"), "lettre de maintien au grade")
	check(GameState.complete_act_review(true) == "" and GameState.player.rank == Career.Rank.INSPECTOR, "accepter n'a pas d'effet sans proposition")
	check(GameState.flags.get("career.act1_denied") == true and not GameState.has_act_review_pending(), "revue close")
	# Acte bien mené : promotion acceptée.
	GameState.new_game()
	GameState.confront_facts("40921", "f_report_presence", "f_log_trip")
	GameState.apply_decision("40921", "arrest")
	for day in 4:
		GameState.end_day()
	for case_id in ["51307", "52044", "52310"]:
		GameState.get_case_state(case_id).contradictions_found.append("test")
		GameState.apply_decision(case_id, CaseLibrary.get_case(case_id).decisions[0].id)
	GameState.indicators.loyalty = 60
	GameState.indicators.suspicion = 30
	review = GameState.get_act_review()
	check(review.evaluation.eligible and review.letter.contains("2e classe"), "promotion proposée")
	check(review.subjects[0].text.contains("Arrêté le 4.11.1986"), "le sort du sujet est archivé")
	var with_truth: bool = GameState.flags.get("52310.truth_known") == true
	check(review.subjects[3].text.contains("Karel BENES") == with_truth, "la vérité sur VARGA n'apparaît que si elle est connue")
	check(GameState.complete_act_review(true).contains("Nomination"), "promotion acceptée")
	check(GameState.get_rank_title() == "Inspecteur de 2e classe", "nouveau grade")
	var saved := GameState.to_dict()
	GameState.from_dict(JSON.parse_string(JSON.stringify(saved)))
	check(GameState.player.rank == Career.Rank.INSPECTOR_2ND, "grade sauvegardé")
	# Promotion déclinée.
	GameState.flags.erase("act1.reviewed")
	GameState.player.rank = Career.Rank.INSPECTOR
	check(GameState.complete_act_review(false).contains("KREMER"), "promotion déclinée")
	check(GameState.flags.get("career.refused_promotion") == true and GameState.player.rank == Career.Rank.INSPECTOR,
			"on reste en 3e classe, le refus est mémorisé")
	GameState.new_game()


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


func test_veritas_acte2() -> void:
	# Socle de l'acte 2 : catégorie « donnée raccordée », décret 86-31, facteurs contestables.
	var case_data := {
		"decisions": [{"id": "arrest", "label": "Arrêter"}, {"id": "release", "label": "Libérer"}],
		"veritas": {
			"recommendation": "arrest",
			"rationale": "test",
			"factors": [
				{"id": "border1", "label": "Proximité frontalière", "category": "border", "weight": 10, "decision": "arrest"},
				{"id": "link1", "label": "Raccordement voyageurs", "category": "linked", "weight": 5, "decision": "arrest", "contestable": true},
				{"id": "risk1", "label": "Risque individuel", "category": "risk", "weight": 4, "decision": "arrest"},
			],
		},
	}
	# Base 40 + frontière 10x2 + raccordement 5x2 + risque 4x1 = 74.
	var base_scores := Veritas.scores(case_data)
	check(base_scores.arrest.score == 74, "indice de base avec une donnée raccordée (x2)")
	check(base_scores.release.score == 40, "l'autre décision reste au score de base")
	var link := _factor_by_id(base_scores.arrest.factors, "link1")
	check(link.multiplier == 2.0 and link.contribution == 10.0, "la donnée raccordée pèse x2")
	# Décret 86-31 : la frontière passe de x2 à x3, l'indice monte à 84.
	var decret := Veritas.scores(case_data, {}, {"decret_86_31": true})
	check(decret.arrest.score == 84, "le décret 86-31 durcit la frontière (x3)")
	check(_factor_by_id(decret.arrest.factors, "border1").multiplier == 3.0, "le multiplicateur frontalier override vaut 3")
	check(Veritas.recommendation(case_data, {}, {"decret_86_31": true}).confidence == 84, "la recommandation reflète le décret")
	# Contestation : un facteur contestable écarté tombe à zéro (74 - 10 = 64).
	var contested := Veritas.scores(case_data, {"contested_factors": ["link1"]})
	check(contested.arrest.score == 64, "contester la donnée raccordée l'écarte du calcul")
	var contested_link := _factor_by_id(contested.arrest.factors, "link1")
	check(contested_link.contested and contested_link.contribution == 0.0, "le facteur contesté est marqué et neutralisé")
	# Un facteur non contestable ne bouge pas même s'il est listé comme contesté.
	var not_contestable := Veritas.scores(case_data, {"contested_factors": ["risk1"]})
	check(not_contestable.arrest.score == 74 and not _factor_by_id(not_contestable.arrest.factors, "risk1").contested,
			"un facteur non contestable résiste à la contestation")


func test_ministry_record() -> void:
	# Règles de données : correspondance exacte, par suffixe, et absence.
	check(MinistryRecord.rule_for("heure_juste.sign_stove").get("tag", "") == "indice_heure_juste",
			"un drapeau suivi renvoie sa règle")
	check(MinistryRecord.rule_for("53118.consulted_superior").get("tag", "") == "sollicite_hierarchie",
			"un drapeau par dossier correspond par suffixe")
	check(MinistryRecord.rule_for("drapeau.inconnu").is_empty(), "un drapeau non suivi ne renvoie rien")
	# Intégration : poser un drapeau suivi alimente la mémoire institutionnelle.
	GameState.new_game()
	check(GameState.ministry_record.is_empty(), "la mémoire institutionnelle démarre vide")
	GameState._merge_flags({"heure_juste.sign_stove": true, "drapeau.inconnu": true})
	check(GameState.ministry_record.size() == 1, "seul un drapeau suivi est consigné")
	var entry: Dictionary = GameState.ministry_record[0]
	check(entry.tag == "indice_heure_juste" and entry.reading != "" and entry.day == GameState.day_index,
			"l'entrée porte le fait, la lecture biaisée et le jour")
	# Un même fait (tag) n'est consigné qu'une fois, même via un autre drapeau.
	GameState._merge_flags({"heure_juste.sign_stairs": true})
	check(GameState.ministry_record.size() == 1, "un même fait n'est pas consigné deux fois")
	GameState._set_flag("53118.consulted_superior", true)
	check(GameState.ministry_record.size() == 2, "un nouveau fait ajoute une entrée")
	# Un drapeau posé à false ne consigne rien.
	GameState._set_flag("career.refused_promotion", false)
	check(GameState.ministry_record.size() == 2, "un drapeau à false ne consigne rien")
	# Sauvegarde : la mémoire survit à to_dict/from_dict (jour en entier).
	var snapshot := GameState.to_dict()
	GameState.new_game()
	check(GameState.ministry_record.is_empty(), "nouvelle partie : mémoire réinitialisée")
	GameState.from_dict(snapshot)
	check(GameState.ministry_record.size() == 2 and typeof(GameState.ministry_record[0].day) == TYPE_INT,
			"la mémoire est restaurée, le jour reconverti en entier")
	# Rechargement d'une sauvegarde sans mémoire (ancien format) : liste vide.
	var old := snapshot.duplicate(true)
	old.erase("ministry_record")
	GameState.from_dict(old)
	check(GameState.ministry_record.is_empty(), "une sauvegarde sans mémoire repart sur une liste vide")


func test_case_53118() -> void:
	var case_data := CaseLibrary.get_case("53118")
	check(CaseLibrary.validate_case(case_data).is_empty(),
			"le dossier 53118 est valide %s" % CaseLibrary.validate_case(case_data))
	# VERITAS pousse l'arrestation collective des onze.
	var advice := Veritas.recommendation(case_data)
	check(advice.decision_id == "arrest_all" and advice.confidence == 93,
			"VERITAS recommande les onze (indice %d)" % advice.confidence)
	check(advice.decision_id == case_data.veritas.recommendation, "recommandation déclarée = indice le plus fort")
	# RACCORDEMENT : le facteur « donnée raccordée » est contestable et écartable.
	var link := _factor_by_id(Veritas.scores(case_data).arrest_all.factors, "network")
	check(link.category == "linked" and link.get("contestable", false), "le raccordement est une donnée raccordée contestable")
	check(Veritas.scores(case_data, {"contested_factors": ["network"]}).arrest_all.score == 79,
			"contester le raccordement baisse l'indice de 14")
	check(Veritas.recommendation(case_data, {"contested_factors": ["network"]}).decision_id == "arrest_all",
			"même contesté, VERITAS maintient l'arrestation (biais institutionnel)")
	# L'archive contredit l'officiel sur le couvre-feu et sur le nombre.
	var keys: Array = CaseLibrary.find_contradictions(case_data).map(func(c: Dictionary) -> String: return c.key)
	check("choir.curfew" in keys and "choir.list" in keys, "l'archive contredit le couvre-feu et le nombre")
	# L'archive paroissiale n'existe qu'une fois demandée et livrée.
	var state := GameState.get_condition_state()
	state.cases = {"53118": {"requested_documents": {}}}
	var visible: Array = CaseLibrary.filter_case(case_data, state).documents.map(func(d: Dictionary) -> String: return d.id)
	check(not "archive_parish" in visible, "l'archive paroissiale est invisible avant la demande")
	# Issues de décision selon les contradictions établies grâce à l'archive.
	var with_permit := {"contradictions_found": ["choir.curfew"]}
	var with_roster := {"contradictions_found": ["choir.list"]}
	var blind := {"contradictions_found": []}
	check(DecisionRules.resolve(case_data, with_permit, "clear").response_id == "clear_proved",
			"classement justifié par le permis de veillée")
	check(DecisionRules.resolve(case_data, blind, "clear").response_id == "clear_unfounded",
			"classement sans preuve mal vu")
	check(DecisionRules.resolve(case_data, with_roster, "restrict").response_id == "restrict_proved",
			"liste réduite justifiée par le registre")
	var knowing := DecisionRules.resolve(case_data, with_permit, "arrest_all")
	check(knowing.response_id == "arrest_all_knowing" and knowing.flags.get("53118.innocents_condemned", false),
			"arrêter malgré le permis condamne sciemment des innocents")


func test_case_53402() -> void:
	var case_data := CaseLibrary.get_case("53402")
	check(CaseLibrary.validate_case(case_data).is_empty(),
			"le dossier 53402 est valide %s" % CaseLibrary.validate_case(case_data))
	# Sans le décret, VERITAS penche déjà vers la transmission.
	var advice := Veritas.recommendation(case_data)
	check(advice.decision_id == "arrest" and advice.confidence == 70,
			"VERITAS recommande la frontière (indice %d)" % advice.confidence)
	check(advice.decision_id == case_data.veritas.recommendation, "recommandation déclarée = indice le plus fort")
	# Le décret 86-31 durcit l'exposition frontalière (x2 -> x3).
	var decree := {"decret_86_31": true}
	check(Veritas.scores(case_data, {}, decree).arrest.score == 79,
			"le décret fait monter l'indice d'arrestation à 79")
	var frontier := _factor_by_id(Veritas.scores(case_data, {}, decree).arrest.factors, "frontier")
	check(frontier.category == "border" and frontier.multiplier == 3.0, "sous le décret, la frontière pèse x3")
	# Raccordement contestable : l'écarter ne suffit pas à renverser le décret.
	var link := _factor_by_id(Veritas.scores(case_data, {}, decree).arrest.factors, "network")
	check(link.category == "linked" and link.get("contestable", false), "le raccordement est une donnée raccordée contestable")
	check(Veritas.recommendation(case_data, {"contested_factors": ["network"]}, decree).decision_id == "arrest",
			"même sans le raccordement, le décret maintient la transmission")
	# Les pièces établies par l'agent disculpent, mais pèsent peu face au décret.
	check(Veritas.scores(case_data, {"contradictions_found": ["train.delays.october", "halvek.movements"]}, decree).arrest.score == 90,
			"faux au registre + voyageurs identifiés : l'indice d'arrestation reste écrasant")
	# Deux contradictions : le relevé central et le relevé des voyageurs.
	var keys: Array = CaseLibrary.find_contradictions(case_data).map(func(c: Dictionary) -> String: return c.key)
	check("train.delays.october" in keys and "halvek.movements" in keys,
			"le relevé central et le manifeste contredisent le dossier")
	# Le manifeste n'existe qu'une fois demandé.
	var state := GameState.get_condition_state()
	state.cases = {"53402": {"requested_documents": {}}}
	var visible: Array = CaseLibrary.filter_case(case_data, state).documents.map(func(d: Dictionary) -> String: return d.id)
	check(not "manifest" in visible, "le relevé des voyageurs est invisible avant la demande")
	# Issues de décision selon la contradiction établie grâce au manifeste.
	var proved := {"contradictions_found": ["halvek.movements"]}
	var blind := {"contradictions_found": []}
	check(DecisionRules.resolve(case_data, proved, "arrest").response_id == "arrest_found",
			"transmettre en connaissant les permis familiaux")
	check(DecisionRules.resolve(case_data, blind, "arrest").response_id == "arrest_unfounded",
			"transmettre sans avoir vérifié qui voyageait")
	check(DecisionRules.resolve(case_data, proved, "clear").flags.get("halm.defied", false),
			"classer une affaire de frontière sous le décret défie HALM")


func test_case_53517() -> void:
	var case_data := CaseLibrary.get_case("53517")
	check(CaseLibrary.validate_case(case_data).is_empty(),
			"le dossier 53517 est valide %s" % CaseLibrary.validate_case(case_data))
	# VERITAS présume l'informateur fiable et pousse la transmission.
	var advice := Veritas.recommendation(case_data)
	check(advice.decision_id == "transmit" and advice.confidence == 72,
			"VERITAS recommande la transmission (indice %d)" % advice.confidence)
	check(advice.decision_id == case_data.veritas.recommendation, "recommandation déclarée = indice le plus fort")
	# Raccordement contestable : l'écarter ne renverse pas la recommandation.
	var link := _factor_by_id(Veritas.scores(case_data).transmit.factors, "network")
	check(link.category == "linked" and link.get("contestable", false), "le raccordement est une donnée raccordée contestable")
	check(Veritas.recommendation(case_data, {"contested_factors": ["network"]}).decision_id == "transmit",
			"même sans le raccordement, VERITAS maintient la transmission")
	# La perquisition disculpe (file du marché noir), mais pèse peu dans l'indice.
	check(Veritas.scores(case_data, {"contradictions_found": ["petras.thursdays"]}).dismiss.score == 53,
			"la perquisition fait monter le classement à 53, sous la transmission")
	# Contradiction : le signalement contre le procès-verbal de perquisition.
	var keys: Array = CaseLibrary.find_contradictions(case_data).map(func(c: Dictionary) -> String: return c.key)
	check("petras.thursdays" in keys, "le signalement et la perquisition se contredisent sur les jeudis")
	# La fiche de l'informateur (CHAUDRON = ORLIK) n'existe qu'une fois demandée.
	var state := GameState.get_condition_state()
	state.cases = {"53517": {"requested_documents": {}}}
	var visible: Array = CaseLibrary.filter_case(case_data, state).documents.map(func(d: Dictionary) -> String: return d.id)
	check(not "informer_file" in visible, "la fiche de l'informateur est invisible avant la demande")
	# Issues de décision selon la contradiction établie par la perquisition.
	var proved := {"contradictions_found": ["petras.thursdays"]}
	var blind := {"contradictions_found": []}
	check(DecisionRules.resolve(case_data, blind, "transmit").response_id == "transmit_blind",
			"transmettre sur la seule parole de l'informateur")
	var knowing := DecisionRules.resolve(case_data, proved, "transmit")
	check(knowing.response_id == "transmit_knowing" and knowing.flags.get("53517.innocent_condemned", false),
			"transmettre malgré la perquisition condamne sciemment un innocent")
	var turned := DecisionRules.resolve(case_data, proved, "turn")
	check(turned.flags.get("53517.informer_reported", false) and turned.flags.get("milice.hostile", false),
			"retourner le signalement vise l'informateur et fâche la Milice")


## Chaque dossier doit expliquer ce qu'on cherche (OBJET) et pourquoi il est là.
## Les bulles tuto s'affichent au début, puis s'estompent une fois des dossiers conclus.
func test_tutorial_bubble_fades() -> void:
	GameState.new_game()
	Settings.guidance = true
	var desk: Control = load("res://scenes/desk/desk.tscn").instantiate()
	get_tree().root.add_child(desk)
	await get_tree().process_frame
	desk._refresh_objective()
	check(GameState.concluded_case_count() == 0 and desk.coach.visible, "aide affichée au début (aucun dossier conclu)")
	GameState.confront_facts("40921", "f_report_presence", "f_log_trip")
	GameState.apply_decision("40921", CaseLibrary.get_case("40921").decisions[0].id)
	GameState.end_day()
	GameState.apply_decision("51307", CaseLibrary.get_case("51307").decisions[0].id)
	check(GameState.concluded_case_count() == 2, "deux dossiers conclus")
	desk._refresh_objective()
	check(not desk.coach.visible, "la bulle d'aide s'estompe une fois le joueur rodé")
	desk.queue_free()
	GameState.new_game()
	await get_tree().process_frame


func test_coach_bubble_can_be_closed() -> void:
	GameState.new_game()
	Settings.guidance = true
	var desk: Control = load("res://scenes/desk/desk.tscn").instantiate()
	get_tree().root.add_child(desk)
	await get_tree().process_frame
	desk._refresh_objective()
	check(desk.coach.visible, "bulle d'astuce affichée au départ")
	check(desk.coach.get_node("%CloseButton") != null, "la bulle a un bouton de fermeture")
	desk.coach.dismissed.emit()
	check(not desk.coach.visible, "la bulle se masque quand on la ferme")
	# Elle réapparaît dès que l'étape conseillée change.
	desk._coach_dismissed_step = "autre|etape|x"
	desk._refresh_objective()
	check(desk.coach.visible, "la bulle revient à l'étape conseillée suivante")
	desk.queue_free()
	GameState.new_game()
	await get_tree().process_frame


func test_scene_gallery() -> void:
	var menu: Control = load("res://scenes/main_menu/main_menu.tscn").instantiate()
	get_tree().root.add_child(menu)
	await get_tree().process_frame
	check(menu.get_node_or_null("%GalleryButton") != null, "le menu principal propose la visite des scènes")
	menu.queue_free()
	var gallery: Control = load("res://scenes/debug/scene_gallery.tscn").instantiate()
	get_tree().root.add_child(gallery)
	await get_tree().process_frame
	await get_tree().process_frame
	check(gallery._list != null and gallery._list.get_child_count() > 0, "la galerie construit sa liste d'entrées")
	gallery.queue_free()
	# Aperçu d'une scène de terrain sans conditions ni coût en heures.
	GameState.new_game()
	var desk: Control = load("res://scenes/desk/desk.tscn").instantiate()
	get_tree().root.add_child(desk)
	await get_tree().process_frame
	check(desk.field_screen.preview("51307"), "aperçu de terrain ouvert hors conditions de jeu")
	desk.queue_free()
	await get_tree().process_frame


func test_document_field_icons() -> void:
	check(DossiersWindow._field_icon_tag("Nom").contains("f_person.png"), "le champ Nom porte l'icône personne")
	check(DossiersWindow._field_icon_tag("Né le").contains("f_date.png"), "le champ Né le porte l'icône date")
	check(DossiersWindow._field_icon_tag("Adresse").contains("f_home.png"), "le champ Adresse porte l'icône domicile")
	check(DossiersWindow._field_icon_tag("Famille hors district").contains("f_family.png"), "Famille passe avant district")
	check(DossiersWindow._field_icon_tag("Antécédents").contains("f_warn.png"), "les antécédents portent l'icône d'alerte")
	check(DossiersWindow._field_icon_tag("Observations diverses") == "", "un libellé inconnu n'a pas d'icône")
	for entry in DossiersWindow.FIELD_ICONS:
		check(ResourceLoader.exists("res://ui/icons/%s.png" % entry[0]), "le pictogramme %s existe" % entry[0])


func test_case_briefings() -> void:
	for case_id in CaseLibrary.get_case_ids():
		var briefing: Dictionary = CaseLibrary.get_case(case_id).get("briefing", {})
		check(briefing.get("objective", "") != "", "le dossier %s a un objet d'enquête" % case_id)
		check(briefing.get("context", "") != "", "le dossier %s explique pourquoi il est là" % case_id)


func _factor_by_id(factors: Array, id: String) -> Dictionary:
	for factor in factors:
		if factor.get("id", "") == id:
			return factor
	return {}


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
	check(CaseLibrary.get_case("51307").documents.size() == 9, "le dossier complet garde ses 9 pièces")


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
	check(keys.size() == 3 and "poem.acrostic" in keys and "varga.mark" in keys and "apt40.occupant" in keys,
			"52310 : 3 contradictions, dont le bail trouvé en perquisition (%s)" % [keys])
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
	check(desk.get_node("%DateLabel").text == "LUN. 03.11.1986  08h00",
			"date et heure dans la barre des tâches : %s" % desk.get_node("%DateLabel").text)
	check(desk.get_node("%HoursLabel").text == "8 h restantes", "heures de service dans la barre des tâches")
	check(desk.get_node("%RankLabel").text == "INSPECTEUR DE 3E CLASSE", "grade affiché dans le menu MINISTÈRE")
	check(desk.get_node("%MessagesButton").badge == 2, "pastille du courrier : 2 non lus")
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
	check(desk.get_node("%MessagesButton").badge == 1, "la pastille se met à jour")
	desk.terminal.submit_command("archives")
	check(desk.get_open_app() == "archives" and desk.is_app_open("messages"),
			"la dernière fenêtre ouverte passe devant, l'autre reste ouverte")

	desk.get_node("%PersonnelButton").pressed.emit()
	check(desk.get_open_app() == "personnel", "le bouton Dossier personnel ouvre l'évaluation")
	var personnel_text: String = desk.windows.personnel.get_node("%PersonnelText").get_parsed_text()
	check(personnel_text.contains("LOYAUTÉ ENVERS LE RÉGIME : conforme"), "l'évaluation est rédigée en mots")
	check(personnel_text.contains("ÉTAT CIVIL") and personnel_text.contains("horloger") and personnel_text.contains("1971"),
			"l'état civil évoque le père horloger et 1971")
	check(personnel_text.contains("SCELLÉ"), "le dossier familial est marqué scellé : on sent que quelque chose est caché")
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
	await _wait_for_scene("Intro")
	var intro := get_tree().current_scene
	check(intro.name == "Intro" and intro.get_node("%PageLabel").text == "1 / 5", "« Nouvelle partie » ouvre l'introduction")
	intro.next_page()
	check(intro.get_node("%TitleLabel").text == "VOUS ÊTES A. VOSK", "page suivante")
	intro.get_node("%SkipButton").pressed.emit()
	await _wait_for_scene("Desk")
	var desk := get_tree().current_scene
	check(desk.name == "Desk", "PASSER mène au bureau")
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
	var doc_body: RichTextLabel = dossiers.get_node("%DocBody")
	check(doc_body.text.contains("[url=fact:f_report_presence]") and doc_body.text.contains("[url=fact:f_report_author]"),
			"le rapport présente 2 passages soulignés")
	check(dossiers.get_node("%VeritasStrip").visible and dossiers.get_node("%VeritasRemark").text.begins_with("VERITAS >"),
			"VERITAS commente la pièce affichée")
	doc_body.meta_clicked.emit("fact:f_report_presence")
	check(GameState.get_case_state("40921").noted_facts == ["f_report_presence"], "un clic sur le passage note l'élément")
	check(doc_body.text.contains("[url=fact:f_report_presence][bgcolor="), "le passage noté est surligné")
	doc_body.meta_clicked.emit("fact:f_report_presence")
	check(GameState.get_case_state("40921").noted_facts.size() == 1, "un élément noté ne peut plus être noté")
	dossiers.select_document("travel_log")
	doc_body.meta_clicked.emit("fact:f_log_trip")
	doc_body.meta_clicked.emit("fact:f_log_card")
	var notebook: Node = dossiers.get_node("%NotebookList")
	check(notebook.get_child_count() == 3, "trois éléments au carnet")
	notebook.get_node("Noted_f_log_card").pressed.emit()
	notebook = dossiers.get_node("%NotebookList")
	notebook.get_node("Noted_f_report_presence").pressed.emit()
	check(not dossiers.get_node("%ConfrontButton").disabled, "deux éléments sélectionnés : on peut confronter")
	check(dossiers._can_drop_note(Vector2.ZERO, {"note": "f_log_card"}, "f_report_presence")
			and not dossiers._can_drop_note(Vector2.ZERO, {"note": "f_log_card"}, "f_log_card"),
			"on peut glisser une fiche sur une autre, pas sur elle-même")
	dossiers.get_node("%ConfrontButton").pressed.emit()
	check(dossiers.get_node("%ConfrontResult").text.begins_with("PAS DE CONTRADICTION"), "carte et présence : aucune incohérence")
	dossiers.get_node("%NotebookList").get_node("Noted_f_report_presence").pressed.emit()
	dossiers.get_node("%NotebookList").get_node("Noted_f_log_trip").pressed.emit()
	dossiers.get_node("%ConfrontButton").pressed.emit()
	check(dossiers.get_node("%ConfrontResult").text.begins_with("CONTRADICTION"), "présence et train : contradiction établie")
	check(dossiers.get_node("%ProgressLabel").text.contains("1 contradiction établie"), "le compteur de contradictions s'affiche")

	dossiers.get_node("%ConclusionButton").pressed.emit()
	var conclusion: Node = dossiers.get_node("%ConclusionPanel")
	check(conclusion.visible and not dossiers.get_node("%DocumentPanel").visible, "le formulaire remplace la pièce")
	check(conclusion.get_node("%ConclusionSummary").get_parsed_text().contains("Présent à son poste"),
			"le formulaire rappelle la contradiction établie")
	check(conclusion.get_node("%SignButton").disabled, "signature impossible sans choix")
	check(not conclusion.get_node("%VeritasAdvice").text.contains("indice"), "VERITAS n'est plus affiché d'office")
	var veritas: VeritasWindow = desk.windows.veritas
	veritas.analysis_time = 0.0
	conclusion.get_node("%VeritasButton").pressed.emit()
	var veritas_log: String = veritas.get_node("%AnalysisLog").get_parsed_text()
	check(desk.get_open_app() == "veritas" and veritas.current_case_id == "40921", "CONSULTER VERITAS lance le programme sur ce dossier")
	check(veritas_log.contains("INDICE DE CONFORMITÉ : 87") and veritas_log.contains("FACTEURS PRINCIPAUX :\n- Déplacement non déclaré"),
			"VERITAS donne son indice et ses facteurs")
	check(veritas_log.contains("ANALYSE INCOMPLÈTE") == (Veritas.unread_count(GameState.get_case_view("40921"), GameState.get_case_state("40921")) > 0),
			"VERITAS avertit seulement s'il reste des pièces non lues")
	check(dossiers.get_node("%ConclusionPanel").visible, "le formulaire reste ouvert derrière")
	conclusion.get_node("%Choices").get_node("Choice_investigate").pressed.emit()
	conclusion.get_node("%SignButton").pressed.emit()
	await get_tree().process_frame
	# Le destin du sujet s'affiche d'abord, puis la réponse du supérieur.
	check(desk.archive_card.visible, "la carte de destin du sujet s'affiche après la signature")
	check(desk.archive_card.get_node("%StampLabel").text == "EN SURSIS", "maintenu sous surveillance : en sursis")
	check(desk.archive_card.get_node("%SubjectName").text == "SEDLAR, Anton Pavel", "la carte nomme le sujet")
	desk.archive_card.get_node("%ContinueButton").pressed.emit()
	await get_tree().process_frame
	check(not desk.archive_card.visible, "la carte se ferme sur CONTINUER")
	check(desk.get_open_app() == "messages", "la réponse du supérieur s'affiche ensuite")
	check(desk.windows.messages.current_message_id == "40921.investigate_found", "c'est la bonne réponse")
	check(desk.windows.messages.get_node("%MessageSubject").text.contains("enquête complémentaire accordée"),
			"l'objet du message est affiché")
	check(GameState.get_case_state("40921").status == GameState.CASE_UNDER_INVESTIGATION, "dossier en enquête complémentaire")
	desk.terminal.submit_command("dossiers")
	check(dossiers.get_node("%ConclusionButton").disabled, "on ne peut pas conclure deux fois")
	desk.terminal.submit_command("archives")
	var archive: Button = desk.windows.archives.get_node("%ArchiveList").get_node_or_null("Archive_40921")
	check(archive != null and archive.text.contains("en cours d'enquête"), "le rapport figure aux archives")
	if archive:
		archive.pressed.emit()
		check(desk.get_open_app() == "dossiers" and dossiers.current_case_id == "40921", "un clic aux archives rouvre le dossier")
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
	check(GameState.day_index == 0 and desk.evening_screen.visible, "seconde demande : la soirée commence")
	check(desk.evening_screen.get_action_ids() == ["lena_answer", "radio_0", "adler_0"], "trois actions le premier soir")
	desk.evening_screen.choose("radio_0")
	check(desk.evening_screen.get_node("%ResultLabel").text.contains("Radio Aldria"), "le résultat de la soirée s'affiche")
	desk.evening_screen.get_node("%ContinueButton").pressed.emit()
	await get_tree().process_frame
	check(GameState.day_index == 1, "après la soirée, la journée se termine")
	check(desk.get_node("%DateLabel").text == "MAR. 04.11.1986  08h00", "la date de la barre des tâches avance, l'horloge repart")
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


func test_act_end_in_desk() -> void:
	GameState.new_game()
	for day in 4:
		GameState.end_day()
	var desk: Control = load("res://scenes/desk/desk.tscn").instantiate()
	get_tree().root.add_child(desk)
	await get_tree().process_frame
	desk.end_day()
	check(desk.evening_screen.visible, "vendredi : la soirée d'abord")
	desk.evening_screen.choose("adler_4")
	desk.evening_screen.get_node("%ContinueButton").pressed.emit()
	await get_tree().process_frame
	check(desk.act_review_screen.visible and GameState.day_index == 4, "puis la revue de fin d'acte")
	check(desk.act_review_screen.get_node("%TitleLabel").text == "FIN DE L'ACTE 1  //  LE ZÈLE", "titre de l'acte")
	check(desk.act_review_screen.get_node("%SubjectsBox").get_child_count() == 8, "quatre sujets archivés")
	check(desk.act_review_screen.get_node("%ContinueButton").visible and not desk.act_review_screen.get_node("%AcceptButton").visible,
			"sans promotion proposée, seulement CONTINUER")
	desk.act_review_screen.get_node("%ContinueButton").pressed.emit()
	await get_tree().process_frame
	check(GameState.day_index == 5 and GameState.flags.get("act1.reviewed") == true, "lundi 10 novembre, acte 2")
	check(desk.get_node("%DayTransitionLabel").text.contains("3 jours plus tard"), "ellipse du week-end")
	desk.queue_free()
	await get_tree().process_frame
	GameState.new_game()


func test_field_in_desk() -> void:
	GameState.new_game()
	GameState.end_day()
	var desk: Control = load("res://scenes/desk/desk.tscn").instantiate()
	get_tree().root.add_child(desk)
	await get_tree().process_frame
	desk.terminal.submit_command("dossiers")
	desk.windows.dossiers.select_case("51307")
	var field_button: Button = desk.windows.dossiers.get_node("%FieldButton")
	check(field_button.visible and field_button.text == "INTERROGER (2 h)" and not field_button.disabled, "bouton INTERROGER")
	field_button.pressed.emit()
	var screen: FieldScreen = desk.field_screen
	check(screen.visible and screen.get_node("%TurnsLabel").text == "5 question(s) restante(s)", "l'écran d'audition s'ouvre")
	check(screen.get_choice_ids() == ["q_certificates", "q_sedlar", "q_brother", "q_threat", "present"], "questions proposées")
	screen.choose("q_sedlar")
	check(screen.get_node("%LogLabel").text.contains("NOTÉ DANS LE CARNET"), "le compte rendu signale l'élément noté")
	screen.show_presentation_list(true)
	check("f_aud_sedlar" in screen.get_choice_ids(), "le carnet est proposé")
	screen.get_node("%LeaveButton").pressed.emit()
	check(screen.get_node("%LeaveButton").text == "RETOUR AU BUREAU", "partir termine l'audition")
	screen.get_node("%LeaveButton").pressed.emit()
	check(not screen.visible and desk.windows.dossiers.visible and desk.windows.dossiers.current_document_id == "orlik_audition",
			"retour au dossier, sur le procès-verbal")
	check(field_button.text == "INTERROGER : FAIT" and field_button.disabled, "audition faite")
	# Perquisition : les endroits sont des boutons sur le dessin.
	GameState.apply_decision("40921", "investigate")
	desk.windows.dossiers.select_case("40921")
	check(field_button.disabled, "dossier conclu sans arrestation : pas de perquisition")
	desk.queue_free()
	await get_tree().process_frame
	GameState.new_game()


func test_failed_confrontation_feedback() -> void:
	GameState.new_game()
	var desk: Control = load("res://scenes/desk/desk.tscn").instantiate()
	get_tree().root.add_child(desk)
	await get_tree().process_frame
	desk.open_app("dossiers")
	var window = desk.windows.dossiers
	window.select_case("40921")
	for fact_id in ["f_log_card", "f_log_trip", "f_report_presence"]:
		GameState.note_fact("40921", fact_id)
	window.toggle_fact_selection("f_log_card")
	window.toggle_fact_selection("f_log_trip")
	window.confront_selected()
	var result: Label = window.get_node("%ConfrontResult")
	check(window.last_confront_failed and result.text.begins_with("PAS DE CONTRADICTION") and result.theme_type_variation == &"StampLabel",
			"échec de confrontation affiché clairement, en rouge")
	check(window.get_guide_text("notebook", "40921").contains("21 octobre"), "la bulle d'aide donne un conseil précis après un échec")
	check(window.get_guide_text("facts", "40921") == "", "conseil réservé à l'étape du carnet")
	window.toggle_fact_selection("f_report_presence")
	window.toggle_fact_selection("f_log_trip")
	window.confront_selected()
	check(not window.last_confront_failed and result.text.begins_with("CONTRADICTION ÉTABLIE") and window.get_guide_text("notebook", "40921") == "",
			"contradiction établie : retour au conseil normal")
	desk.queue_free()


func test_field_stages_are_valid() -> void:
	for scene_id in ["audition_51307", "search_40921"]:
		var scene := FieldRules.get_scene(scene_id)
		var art: String = "interrogation" if scene.type == "interrogation" else scene.art
		check(FieldStage3D.has_stage(art), "%s : décor 3D %s" % [scene_id, art])
		var stage := DataLoader.load_json(FieldStage3D.stage_path(art))
		var option_ids: Array = FieldRules.all_options(scene).map(func(o: Dictionary) -> String: return o.id)
		var spots := []
		for prop: Dictionary in stage.props:
			check(prop.has("id") and (prop.has("parts") or prop.get("role", "") == "subject"), "%s : objet %s constructible" % [art, prop.get("id", "?")])
			if prop.has("option"):
				spots.append(prop.option)
				check(prop.option in option_ids or (prop.option == "present" and scene.type == "interrogation"),
						"%s : l'objet %s correspond à un choix" % [art, prop.id])
		if scene.type == "search":
			check(spots.size() == option_ids.size(), "%s : chaque endroit a son objet 3D" % art)


func test_field_stage_3d() -> void:
	var stage := FieldStage3D.new()
	stage.size = Vector2(640, 300)
	get_tree().root.add_child(stage)
	var received := []
	stage.spot_pressed.connect(func(id: String) -> void: received.append(id))
	check(not stage.load_stage("inexistant"), "décor inconnu refusé")
	check(stage.load_stage("sedlar_flat"), "décor de l'appartement chargé")
	check(stage.get_spot_ids().size() == 6, "six objets à fouiller")
	await get_tree().process_frame
	stage.set_active_spots(["stove", "drawer"])
	var point := stage.spot_screen_position("stove")
	check(Rect2(Vector2.ZERO, stage.size).has_point(point), "le poêle est dans le champ de la caméra (%s)" % point)
	check(stage.spot_at(point) == "stove", "viser le poêle le désigne")
	check(stage.spot_at(stage.spot_screen_position("satchel")) == "", "un endroit déjà fouillé ne réagit plus")
	stage.press_spot("satchel")
	stage.press_spot("stove")
	check(received == ["stove"], "seul l'endroit encore possible est signalé")
	check(stage.load_stage("interrogation", {"model": "res://assets/models/field/characters/absent.glb"}),
			"modèle absent : formes de secours")
	check(stage.get_spot_ids() == ["present"], "le dossier sur la table sert à présenter un élément")
	stage.queue_free()
	await get_tree().process_frame
	# Dans l'écran de terrain : l'image livrée prime ; sinon la 3D si le réglage est
	# actif ; sinon le dessin. (Aperçu libre pour ne pas dépendre du calendrier.)
	GameState.new_game()
	var screen: FieldScreen = load("res://scenes/field/field_screen.tscn").instantiate()
	get_tree().root.add_child(screen)
	Settings.field_3d = true
	check(screen.preview("40921") and not screen.is_3d() and screen.get_node("%Art").visible \
			and screen.get_node("%Art").has_image(), "une image livrée prime sur la 3D")
	# Scène sans image livrée : la 3D s'affiche si le réglage est actif, sinon le dessin.
	var no_image := FieldRules.get_scene("audition_53402").duplicate(true)
	no_image.erase("image")
	GameState.field_scenes[no_image.id] = {"turns_used": 0, "chosen": [], "finished": false}
	screen._show_scene(no_image)
	check(screen.is_3d() and screen.get_stage().active_spots.size() > 0,
			"sans image, la 3D s'affiche si le réglage est actif")
	Settings.field_3d = false
	screen._show_scene(no_image)
	check(not screen.is_3d() and screen.get_node("%Art").visible, "réglage 2D : décor dessiné")
	screen.queue_free()
	await get_tree().process_frame
	GameState.new_game()


func test_friendly_desk() -> void:
	SaveManager.delete_save()
	var desk: Control = load("res://scenes/desk/desk.tscn").instantiate()
	get_tree().root.add_child(desk)
	await get_tree().process_frame
	check(desk.coach.visible, "la bulle d'aide est affichée")
	check(desk.current_step.text.contains("prise de fonction"), "premier objectif : le message de Mazur")
	check(desk.current_step.target == "messages", "l'icône du courrier est signalée")
	check(desk.get_node("%DossiersButton").badge == 1 and desk.get_node("%DossiersButton").tooltip_text.contains("1 dossier(s) à traiter"),
			"l'icône Dossiers résume la situation")
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
	check(not desk.coach.visible, "l'aide se désactive dans les paramètres")
	Settings.guidance = true
	desk._refresh_objective()
	check(desk.coach_target() == desk.get_node("%MessagesButton") and desk.coach.text.contains("Bienvenue"),
			"la bulle d'aide montre l'icône du courrier")
	desk.get_node("%MessagesButton").pressed.emit()
	check(desk.coach_target() == desk.get_node("%DossiersButton"), "message lu : la bulle montre l'icône Dossiers")
	desk.windows.messages.close()
	check(desk.coach_target() == desk.get_node("%DossiersButton"), "fenêtre fermée : toujours l'icône Dossiers")
	desk.get_node("%DossiersButton").pressed.emit()
	var part: String = desk.current_step.part
	check(part.begins_with("tab:") and desk.coach_target() == desk.windows.dossiers.get_guide_target(part, "40921") \
			and desk.coach_target().get_meta("document_id") == part.substr(4),
			"dans le dossier : l'onglet de la pièce suivante")
	for document_id in ["work_report", "intercept", "travel_log"]:
		desk.windows.dossiers.select_document(document_id)
	check(desk.current_step.part == "facts" and desk.coach_target() == desk.windows.dossiers.get_node("%DocBody") \
			and desk.coach.text.contains("21 octobre"), "noter : la bulle montre le texte de la pièce, conseil propre au premier dossier")
	desk.windows.dossiers.close()
	GameState.new_game()
	desk.queue_free()
	await get_tree().process_frame


## Bureau à fenêtres : plusieurs fenêtres, premier plan, réduction, agrandissement,
## barre des tâches, menu MINISTÈRE, petit écran.
func test_desktop_windows() -> void:
	GameState.new_game()
	var desk: Control = load("res://scenes/desk/desk.tscn").instantiate()
	get_tree().root.add_child(desk)
	await get_tree().process_frame
	var manager: WindowManager = desk.window_manager
	var dossiers: MinistryWindow = desk.windows.dossiers
	var messages: MinistryWindow = desk.windows.messages
	check(desk.get_node("%TaskButtons").get_child_count() == 0, "aucune fenêtre : barre des tâches vide")
	desk.open_app("dossiers")
	desk.open_app("messages")
	await get_tree().process_frame
	check(dossiers.visible and messages.visible and desk.get_open_app() == "messages", "deux fenêtres ouvertes, la dernière devant")
	check(messages.is_active and not dossiers.is_active, "seule la fenêtre au premier plan a sa barre de titre active")
	check(manager.get_child(-1) == messages, "la fenêtre au premier plan est dessinée en dernier")
	check(desk.get_node("%TaskButtons").get_child_count() == 2, "un bouton par fenêtre dans la barre des tâches")
	check(dossiers.get_anchor(SIDE_RIGHT) == 0.0 and Rect2(Vector2.ZERO, manager.size).encloses(dossiers.get_rect()),
			"la fenêtre a une position libre, dans la zone de travail")
	manager.raise_window(dossiers)
	check(desk.get_open_app() == "dossiers" and manager.get_child(-1) == dossiers, "on repasse une fenêtre devant")

	# Réduire puis ressortir depuis la barre des tâches.
	manager.toggle_from_taskbar(dossiers)
	check(not dossiers.visible and dossiers.is_minimized and desk.is_app_open("dossiers"), "réduite : cachée mais ouverte")
	check(desk.get_open_app() == "messages", "la fenêtre suivante passe devant")
	manager.toggle_from_taskbar(dossiers)
	check(dossiers.visible and desk.get_open_app() == "dossiers", "le bouton de la barre des tâches la ressort")
	dossiers.get_node("Layout/TitleBar").find_child("MinimizeButton", true, false).pressed.emit()
	check(dossiers.is_minimized, "le bouton _ réduit la fenêtre")
	desk.open_app("dossiers")
	check(dossiers.visible and not dossiers.is_minimized, "rouvrir une fenêtre réduite la ressort")

	# Agrandir et déplacer.
	var before := dossiers.get_rect()
	dossiers.toggle_maximize()
	check(dossiers.get_rect() == Rect2(Vector2.ZERO, manager.size), "agrandie : toute la zone de travail")
	dossiers.toggle_maximize()
	check(dossiers.get_rect() == before, "rétablie : taille et place d'origine")
	messages.position = Vector2(-5000, 9000)
	messages.clamp_to_parent()
	check(messages.get_rect().end.y <= manager.size.y and messages.position.x + messages.size.x >= MinistryWindow.KEEP_VISIBLE.x,
			"une fenêtre déplacée garde sa barre de titre à portée")

	# Fermer, aide, menu MINISTÈRE.
	messages.get_close_button().pressed.emit()
	check(not desk.is_app_open("messages") and desk.get_node("%TaskButtons").get_child_count() >= 1, "le bouton X ferme la fenêtre")
	desk.get_node("%StartButton").button_pressed = true
	check(desk.get_node("%StartMenu").visible, "le bouton MINISTÈRE ouvre le menu")
	desk.get_node("%StartSettings").pressed.emit()
	check(not desk.get_node("%StartMenu").visible and desk.get_open_app() == "settings", "le menu ouvre les paramètres et se referme")
	desk.get_node("%StartTerminal").pressed.emit()
	check(desk.get_open_app() == "terminal", "le terminal est une fenêtre comme les autres")
	desk.terminal.submit_command("ident")
	check(desk.terminal.get_log_text().contains("INS-7734"), "le terminal fonctionne dans sa fenêtre")

	# Petit écran : chaque fenêtre occupe toute la zone de travail.
	manager.force_compact = true
	check(manager.compact and desk.windows.terminal.get_rect() == Rect2(Vector2.ZERO, manager.size), "petit écran : fenêtres en plein écran")
	manager.force_compact = false
	desk.end_day()
	check(manager.get_open_windows().is_empty(), "fin de service : toutes les fenêtres se ferment")
	desk.queue_free()
	await get_tree().process_frame
	GameState.new_game()


## Icônes en pixels : grilles valides, une icône par type de pièce des dossiers.
func test_pixel_icons() -> void:
	for icon_name in PixelIcons.GRIDS:
		var rows: Array = PixelIcons.GRIDS[icon_name]
		var valid := rows.size() == PixelIcons.SIZE
		for row: String in rows:
			valid = valid and row.length() == PixelIcons.SIZE
			for key in row:
				valid = valid and (key == "." or PixelIcons.COLOR_NAMES.has(key))
		check(valid, "icône %s : 16 x 16, lettres connues" % icon_name)
	var image := PixelIcons.build_image("identity")
	check(image.get_pixel(0, 2).a == 1.0 and image.get_pixel(0, 0).a == 0.0, "les points « . » sont transparents")
	for case_id in CaseLibrary.get_case_ids():
		for document in CaseLibrary.get_case(case_id).documents:
			check(PixelIcons.DOCUMENT_ICONS.has(document.type) and PixelIcons.has_icon(PixelIcons.DOCUMENT_ICONS[document.type]),
					"pièce %s/%s : icône pour le type %s" % [case_id, document.id, document.type])
	check(PixelIcons.document_icon("inconnu") == PixelIcons.get_icon("document"), "type inconnu : page générique")
	check(PixelIcons.get_icon("letter", 3).get_size() == Vector2(48, 48), "icône agrandie trois fois sans lissage")
	var window: Node = load("res://scenes/ui/windows/dossiers_window.tscn").instantiate()
	get_tree().root.add_child(window)
	window.open()
	window.select_case("40921")
	var tab: Button = window.get_node("%DocumentTabs").get_child(0)
	check(tab.icon == PixelIcons.document_icon("identity", 2), "l'onglet de la fiche d'identité porte son icône")
	window.select_document("work_report")
	check(window._doc_icon.texture == PixelIcons.document_icon("report", 4), "l'en-tête de la pièce montre l'icône du rapport")
	window.queue_free()
	await get_tree().process_frame


## Classeur : pièces lues ou à lire, avancement, pièces ouvertes dans leur propre fenêtre.
func test_document_windows() -> void:
	GameState.new_game()
	var desk: Control = load("res://scenes/desk/desk.tscn").instantiate()
	get_tree().root.add_child(desk)
	await get_tree().process_frame
	desk.open_app("dossiers")
	var dossiers: DossiersWindow = desk.windows.dossiers
	dossiers.select_case("40921")
	var tabs: Node = dossiers.get_node("%DocumentTabs")
	check(not tabs.get_node("Tab_identity").text.contains("à lire") and tabs.get_node("Tab_work_report").text.contains("(à lire)"),
			"les pièces non lues sont marquées « à lire »")
	check(tabs.get_node("Tab_work_report").theme_type_variation == &"DocumentTabNew", "pièce à lire mise en avant")
	check(dossiers.get_node("%ProgressLabel").text.contains("1/4 pièces lues") \
			and dossiers.get_node("%ProgressLabel").text.contains("0 contradiction"), "avancement lisible en une ligne")
	check(dossiers.get_node("%ObjectiveLabel").visible \
			and dossiers.get_node("%ObjectiveLabel").text.contains("OBJET DE L'ENQUÊTE"), "le briefing affiche l'objet de l'enquête")
	check(dossiers.get_node("%ActionsHelp").visible \
			and dossiers.get_node("%ActionsHelp").text.contains("confronter"), "les actions possibles sont expliquées sur les premières missions")

	dossiers.select_document("work_report")
	dossiers.open_current_aside()
	await get_tree().process_frame
	var aside: DocumentWindow = desk.window_manager.get_focused()
	check(aside != null and aside.document_id == "work_report" and aside.visible, "la pièce s'ouvre dans sa propre fenêtre, au premier plan")
	check(aside.get_node("%DocBody").get_parsed_text().contains("SEDLAR") and aside.window_title.contains("40921"),
			"la fenêtre montre la pièce et son dossier")
	check(desk.get_node("%TaskButtons").get_child_count() == 2, "la pièce a son bouton dans la barre des tâches")
	aside.get_node("%DocBody").meta_clicked.emit("fact:f_report_presence")
	check("f_report_presence" in GameState.get_case_state("40921").noted_facts, "on note un élément depuis la pièce à part")
	check(dossiers.get_node("%NotebookList").has_node("Noted_f_report_presence"), "le carnet du dossier se met à jour")
	check(aside.get_node("%DocBody").text.contains("[url=fact:f_report_presence][bgcolor="), "le passage noté est surligné dans la pièce à part")
	check(dossiers.get_node("%NotebookList").get_node("Noted_f_report_presence").tooltip_text.contains("Rapport"),
			"le carnet rappelle la pièce d'où vient l'élément")
	check(desk.open_document_window("40921", "work_report") == aside, "rouvrir la même pièce ramène sa fenêtre")
	var second: DocumentWindow = desk.open_document_window("40921", "travel_log")
	check(second != aside and second.position != aside.position, "une deuxième pièce s'ouvre décalée, pour comparer")
	aside.close()
	await get_tree().process_frame
	check(not is_instance_valid(aside) and desk.window_manager.get_focused() != null, "fermer une pièce détruit sa fenêtre")
	desk.end_day()
	await get_tree().process_frame
	check(not is_instance_valid(second), "fin de service : les pièces ouvertes se ferment")
	desk.queue_free()
	await get_tree().process_frame
	GameState.new_game()


## Choix du morceau selon le moment du jeu et l'état de la partie.
func test_music_rules() -> void:
	var state := {"day_index": 0, "flags": {}, "cases": {}, "indicators": {"suspicion": 10}}
	check(MusicRules.track_for("menu", state) == "menu", "menu principal : morceau du menu")
	check(MusicRules.track_for("desk", state) == "act1_desk", "bureau, acte 1")
	state.day_index = 5
	check(MusicRules.track_for("desk", state) == "act2_desk", "bureau, acte 2 (jour 6)")
	state.day_index = 15
	check(MusicRules.track_for("desk", state) == "act4_desk", "bureau, acte 4")
	state.indicators.suspicion = 60
	check(MusicRules.track_for("desk", state) == "desk_tension", "suspicion haute : bureau sous tension")
	check(MusicRules.track_for("evening", state) == "evening", "soirée ordinaire")
	state.flags["40921.sedlar_arrested"] = true
	check(MusicRules.track_for("evening", state) == "evening_grief", "après l'arrestation de SEDLAR : autre soirée")
	check(MusicRules.track_for("field_interrogation", state) == "field_interrogation", "terrain : audition")
	check(MusicRules.track_for("inconnu", state) == "", "contexte inconnu : silence")
	check(MusicRules.are_conditions_met({"max_indicator": {"loyalty": 30}}, {"indicators": {"loyalty": 40}}) == false,
			"condition d'indicateur maximal")
	var valid := true
	for rule in MusicRules.data().rules:
		valid = valid and MusicRules.get_track(rule.track).get("file", "").begins_with("res://assets/music/")
	check(valid, "chaque règle désigne un morceau déclaré dans assets/music/")


## Lecteur : contexte suivi, silence sans erreur si le fichier manque, volume.
func test_music_player() -> void:
	GameState.new_game()
	Music.play_context("desk")
	check(Music.current_context == "desk" and Music.current_track == "act1_desk", "le bureau demande le morceau de l'acte 1")
	check(not Music.is_playing() or ResourceLoader.exists(MusicRules.get_track("act1_desk").file),
			"fichier absent : silence, sans erreur")
	GameState.indicators.suspicion = 70
	GameState.state_changed.emit()
	check(Music.current_track == "desk_tension", "la musique suit l'état de la partie")
	var volume := Settings.music_volume
	Settings.music_volume = 0.0
	Music.apply_volume()
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index(Music.BUS)), "volume à zéro : musique coupée")
	Settings.music_volume = volume
	Music.apply_volume()
	check(not AudioServer.is_bus_mute(AudioServer.get_bus_index(Music.BUS)), "volume rétabli")
	var window: Node = load("res://scenes/ui/windows/settings_window.tscn").instantiate()
	get_tree().root.add_child(window)
	window.open()
	check(window.get_node("%MusicOption").item_count == Settings.MUSIC_LEVELS.size(), "Paramètres : réglage du volume de la musique")
	check(window.get_node("%ResolutionOption").item_count == Settings.WINDOW_SIZES.size(), "Paramètres : choix de la résolution")
	var saved_size: Vector2i = Settings.window_size
	Settings.set_window_size(Vector2i(1600, 900))
	check(Settings.window_size == Vector2i(1600, 900), "la résolution de la fenêtre est réglable")
	Settings.set_window_size(saved_size)
	window.queue_free()
	Music.stop()
	GameState.new_game()
	await get_tree().process_frame


func test_time_in_desk() -> void:
	GameState.new_game()
	var desk: Control = load("res://scenes/desk/desk.tscn").instantiate()
	get_tree().root.add_child(desk)
	await get_tree().process_frame
	check(not desk.get_node("%ArchivesButton").visible and not desk.get_node("%PersonnelButton").visible,
			"premier jour : ni Archives ni Dossier personnel")
	desk.terminal.submit_command("dossiers")
	desk.windows.dossiers.select_case("40921")
	check(not desk.windows.dossiers.get_node("%RequestButton").visible and not desk.windows.dossiers.get_node("%ConsultButton").visible,
			"premier jour : ni DEMANDER ni CONSULTER")
	desk.windows.dossiers.close()
	GameState.end_day()
	check(desk.get_node("%ArchivesButton").visible and desk.get_node("%PersonnelButton").visible, "deuxième jour : tout est débloqué")
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
	check(desk.get_node("%DateLabel").text.ends_with("10h00") and desk.get_node("%HoursLabel").text == "6 h restantes",
			"l'horloge avance")
	desk.queue_free()
	await get_tree().process_frame
