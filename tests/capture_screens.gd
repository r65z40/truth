extends Node
## Capture d'écran des scènes principales, pour vérifier l'aspect visuel sans éditeur.
## Nécessite un affichage (pas --headless). Exemple sous Linux sans écran :
##   xvfb-run -s "-screen 0 1280x720x24" godot --path . res://tests/capture_screens.tscn -- <dossier_sortie>
## Les images sont écrites dans <dossier_sortie> (par défaut user://screenshots).

var _out_dir := "user://screenshots"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		_out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(_out_dir)
	_capture_all.call_deferred()


func _capture_all() -> void:
	GameState.new_game()
	var menu: Node = load("res://scenes/main_menu/main_menu.tscn").instantiate()
	get_tree().root.add_child(menu)
	await _snap("01_menu_principal")
	menu.get_node("%SettingsButton").pressed.emit()
	await _snap("02_parametres")
	menu.queue_free()
	var intro: Node = load("res://scenes/intro/intro.tscn").instantiate()
	get_tree().root.add_child(intro)
	for page in intro.pages.size():
		await _snap("02%s_introduction" % "abcd"[page])
		if page < intro.pages.size() - 1:
			intro.next_page()
	intro.queue_free()

	var desk: Node = load("res://scenes/desk/desk.tscn").instantiate()
	get_tree().root.add_child(desk)
	await _wait(1.5)
	await _snap("03_bureau", 1.0)
	desk.terminal.submit_command("dossiers")
	await _snap("04_dossiers_liste")
	desk.windows.dossiers.select_case("40921")
	await _snap("05_dossier_identite")
	desk.windows.dossiers.select_document("work_report")
	await _snap("06_dossier_rapport")
	desk.windows.dossiers.select_document("intercept")
	await _snap("07_dossier_interception")
	desk.windows.dossiers.select_document("travel_log")
	await _snap("08_dossier_registre")
	var dossiers = desk.windows.dossiers
	dossiers.note_fact("f_log_trip")
	dossiers.select_document("work_report")
	dossiers.note_fact("f_report_presence")
	dossiers.note_fact("f_report_author")
	dossiers.toggle_fact_selection("f_report_author")
	dossiers.toggle_fact_selection("f_log_trip")
	dossiers.confront_selected()
	await _snap("09a_confrontation_ratee")
	dossiers.toggle_fact_selection("f_report_presence")
	dossiers.toggle_fact_selection("f_log_trip")
	await _snap("09_carnet_selection")
	dossiers.confront_selected()
	await _snap("10_contradiction_etablie")
	dossiers.open_conclusion()
	dossiers.get_node("%ConclusionPanel").get_node("%Choices").get_child(0).button_pressed = true
	dossiers.get_node("%ConclusionPanel").select_decision("arrest")
	await _snap("11_conclusion")
	dossiers.get_node("%ConclusionPanel").get_node("%SignButton").pressed.emit()
	await _snap("12_reponse_superieur")
	desk.terminal.submit_command("archives")
	await _snap("13_archives")
	desk.end_day()
	await _snap("14a_soiree")
	desk.evening_screen.choose("lena_answer")
	await _snap("14b_soiree_resultat")
	desk.evening_screen.get_node("%ContinueButton").pressed.emit()
	await _snap("14c_fin_de_service", 0.8)
	await _wait(2.5)
	desk.terminal.submit_command("messages")
	desk.windows.messages.select_message(GameState.messages[-2].id)
	await _snap("15_lettre_famille")
	for message in GameState.messages:
		if message.subject == "Au sujet de mon frère":
			desk.windows.messages.select_message(message.id)
	await _snap("16_pression_milice")
	desk.terminal.submit_command("dossiers")
	desk.windows.dossiers.select_case("51307")
	desk.windows.dossiers.select_document("sedlar_interrogation")
	await _snap("17_dossier_51307_interrogatoire")
	desk.windows.dossiers.select_document("clock_log")
	await _snap("18_dossier_51307_horloge")
	desk.terminal.submit_command("profil")
	await _snap("19_dossier_personnel")
	desk.windows.personnel.hide()
	GameState.end_day()
	GameState.end_day()
	desk.terminal.submit_command("dossiers")
	desk.windows.dossiers.select_case("52044")
	desk.windows.dossiers.select_document("death_register")
	await _snap("20_dossier_52044_deces")
	desk.windows.dossiers.select_case("52310")
	desk.windows.dossiers.select_document("reader_card")
	await _snap("21_dossier_52310_fiche_1979")
	desk.windows.dossiers.select_document("poem_1979")
	await _snap("22_dossier_52310_poeme")
	desk.windows.dossiers.open_conclusion()
	await _snap("23_dossier_52310_veritas")
	desk.windows.dossiers.close()
	# Fin de l'acte 1 : dossiers conclus avec contradictions, promotion proposée.
	for case_id in ["51307", "52044", "52310"]:
		if GameState.can_decide(case_id):
			GameState.get_case_state(case_id).contradictions_found.append("capture")
			GameState.apply_decision(case_id, CaseLibrary.get_case(case_id).decisions[1].id)
	GameState.indicators.loyalty = 60
	GameState.indicators.suspicion = 30
	GameState.end_day()
	desk.end_day()
	desk.evening_screen.choose("lena_news")
	await _snap("24_soiree_vendredi")
	desk.evening_screen.get_node("%ContinueButton").pressed.emit()
	await _snap("25_fin_acte_1")
	desk.act_review_screen.decide(true)
	await _snap("26_promotion")
	desk.act_review_screen.get_node("%ContinueButton").pressed.emit()
	await _wait(2.5)
	# Terrain : audition d'ORLIK, perquisition chez SEDLAR.
	GameState.new_game()
	GameState.apply_decision("40921", "arrest")
	GameState.end_day()
	GameState.note_fact("51307", "f_clock_ok")
	desk.open_field("51307")
	await _snap("27_audition")
	desk.field_screen.choose("q_certificates")
	desk.field_screen.present("f_clock_ok")
	await _snap("28_audition_aveu")
	desk.field_screen.get_node("%LeaveButton").pressed.emit()
	desk.field_screen.get_node("%LeaveButton").pressed.emit()
	await _snap("29_proces_verbal")
	desk.windows.dossiers.close()
	desk.open_field("40921")
	await _snap("30_perquisition")
	desk.field_screen.choose("stove")
	await _snap("31_perquisition_poele")
	desk.field_screen.get_node("%LeaveButton").pressed.emit()
	desk.field_screen.get_node("%LeaveButton").pressed.emit()
	desk.windows.dossiers.close()
	GameState.end_day()
	GameState.end_day()
	desk.open_field("52044")
	desk.field_screen.choose("cash_box")
	await _snap("32_boulangerie")
	desk.field_screen.get_node("%LeaveButton").pressed.emit()
	desk.field_screen.get_node("%LeaveButton").pressed.emit()
	desk.windows.dossiers.close()
	GameState.end_day()
	desk.open_field("52310")
	desk.field_screen.choose("floorboard")
	await _snap("33_perquisition_benes")
	get_tree().quit()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _snap(file_name: String, delay := 0.4) -> void:
	await _wait(delay)
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png("%s/%s.png" % [_out_dir, file_name])
	print("capture : %s" % file_name)
