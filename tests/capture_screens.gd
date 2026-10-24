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

	var desk: Node = load("res://scenes/desk/desk.tscn").instantiate()
	get_tree().root.add_child(desk)
	await _wait(1.5)
	desk.terminal.submit_command("aide")
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
	await _snap("14_fin_de_service", 0.8)
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
	get_tree().quit()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _snap(file_name: String, delay := 0.4) -> void:
	await _wait(delay)
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png("%s/%s.png" % [_out_dir, file_name])
	print("capture : %s" % file_name)
