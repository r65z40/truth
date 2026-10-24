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
		"test_terminal_command_parsing",
		"test_main_menu_scene",
		"test_desk_scene_flow",
		"test_full_session_flow",
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
