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
	desk.terminal.submit_command("messages")
	await _snap("09_messages")
	desk.terminal.submit_command("archives")
	await _snap("10_archives")
	get_tree().quit()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _snap(file_name: String, delay := 0.4) -> void:
	await _wait(delay)
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png("%s/%s.png" % [_out_dir, file_name])
	print("capture : %s" % file_name)
