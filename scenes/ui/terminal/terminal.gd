class_name Terminal
extends PanelContainer
## Terminal gouvernemental : affiche un journal en vert phosphore et accepte des
## commandes au clavier ou via les boutons rapides (utilisables au tactile).
##
## Le terminal n'ouvre pas lui-même les fenêtres : il émet des signaux que le
## bureau traite. Les commandes sont interprétées par TerminalCommands.

signal app_requested(app_name: String)
signal save_requested
signal end_day_requested
signal menu_requested

const COLOR_DIM := "#1f6b3f"
const COLOR_ALERT := "#d04a3a"
const COLOR_TEXT := "#e8e4d8"
const CHARS_PER_SECOND := 400.0

const QUICK_COMMANDS := ["AIDE", "DOSSIERS", "MESSAGES", "VERITAS", "IDENT", "EFFACER"]
## Raccourcis masqués tant que la fonction « terminal_advanced » n'est pas débloquée.
const ADVANCED_COMMANDS := ["VERITAS", "IDENT", "EFFACER"]
const QUICK_TOOLTIPS := {
	"AIDE": "Liste des commandes du terminal.",
	"DOSSIERS": "Ouvrir les dossiers qui vous sont assignés.",
	"MESSAGES": "Consulter la messagerie interne.",
	"VERITAS": "Demander l'avis du système d'analyse VERITAS.",
	"IDENT": "Afficher votre identité d'agent.",
	"EFFACER": "Effacer l'écran du terminal.",
}

var _typing_tween: Tween

@onready var _output: RichTextLabel = %Output
@onready var _input: LineEdit = %Input
@onready var _quick_bar: HFlowContainer = %QuickBar


func _ready() -> void:
	_input.text_submitted.connect(_on_input_submitted)
	for command in QUICK_COMMANDS:
		var button := Button.new()
		button.text = command
		button.tooltip_text = QUICK_TOOLTIPS.get(command, "")
		button.custom_minimum_size = Vector2(0, 44)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(submit_command.bind(command))
		button.set_meta("command", command)
		_quick_bar.add_child(button)
	_output.text = ""


## Affiche ou masque les raccourcis avancés (première journée simplifiée).
func set_advanced_visible(show_advanced: bool) -> void:
	for button in _quick_bar.get_children():
		if button.get_meta("command", "") in ADVANCED_COMMANDS:
			button.visible = show_advanced


## Séquence d'ouverture de session affichée à l'arrivée au bureau.
func boot(agent_name: String, date_label: String, unread: int) -> void:
	clear()
	print_line("SYSTÈME CENTRAL DU MINISTÈRE  //  TERMINAL T-4/112", COLOR_DIM)
	print_line("Module d'analyse VERITAS v0.9 ........ [color=#3ce07a]EN LIGNE[/color]", COLOR_DIM)
	print_line("Liaison sécurisée .................... [color=#3ce07a]ÉTABLIE[/color]", COLOR_DIM)
	print_line("")
	print_line("SESSION OUVERTE : %s" % agent_name)
	print_line("DATE : %s" % date_label)
	if unread > 0:
		print_line("%d message(s) non lu(s). Tapez MESSAGES." % unread, COLOR_ALERT)
	print_line("Tapez AIDE pour la liste des commandes.", COLOR_DIM)


## Exécute une commande comme si elle avait été tapée.
func submit_command(raw: String) -> void:
	if raw.strip_edges().is_empty():
		return
	print_line("> " + raw.strip_edges().to_upper(), COLOR_TEXT)
	var command := TerminalCommands.parse(raw)
	match command.action:
		TerminalCommands.Action.HELP:
			for line in TerminalCommands.HELP_LINES:
				print_line(line)
		TerminalCommands.Action.OPEN_APP:
			print_line("Ouverture du module %s..." % command.target.to_upper(), COLOR_DIM)
			app_requested.emit(command.target)
		TerminalCommands.Action.CLEAR:
			clear()
		TerminalCommands.Action.DATE:
			print_line("%s  //  %s" % [GameState.get_date_long(), GameState.get_clock_text()])
		TerminalCommands.Action.IDENT:
			print_line("AGENT : %s   MATRICULE : %s" % [GameState.player.name, GameState.player.badge])
			print_line("GRADE : %s   AFFECTATION : Section 4" % GameState.get_rank_title())
		TerminalCommands.Action.SAVE:
			save_requested.emit()
		TerminalCommands.Action.END_DAY:
			end_day_requested.emit()
		TerminalCommands.Action.MENU:
			menu_requested.emit()
		TerminalCommands.Action.VERITAS:
			print_line("%s : %s" % [Veritas.NAME, Veritas.terminal_reply(GameState.get_condition_state(), command.args)])
		TerminalCommands.Action.DEBUG_STATE:
			if OS.is_debug_build():
				print_line("[DEV] Loyauté %d  Suspicion %d  Influence %d" % [GameState.get_indicator("loyalty"),
						GameState.get_indicator("suspicion"), GameState.get_indicator("influence")], COLOR_DIM)
			else:
				print_line("COMMANDE INCONNUE : %s. Tapez AIDE." % command.input, COLOR_ALERT)
		TerminalCommands.Action.UNKNOWN:
			print_line("COMMANDE INCONNUE : %s. Tapez AIDE." % command.input, COLOR_ALERT)


## Ajoute une ligne au journal, avec un effet de frappe.
## Le texte peut contenir du BBCode ; color est une couleur hexadécimale optionnelle.
func print_line(text: String, color := "") -> void:
	var line := text if color.is_empty() else "[color=%s]%s[/color]" % [color, text]
	var previous_count := _output.get_total_character_count()
	if _output.visible_characters == -1:
		_output.visible_characters = previous_count
	_output.append_text(line + "\n")
	_animate_typing()


func clear() -> void:
	if _typing_tween:
		_typing_tween.kill()
	_output.clear()
	_output.visible_characters = -1


## Texte brut actuellement dans le journal (utile pour les tests).
func get_log_text() -> String:
	return _output.get_parsed_text()


func focus_input() -> void:
	_input.grab_focus()


func _animate_typing() -> void:
	if _typing_tween:
		_typing_tween.kill()
	var target := _output.get_total_character_count()
	Sound.play("typewriter")
	var duration := maxf((target - _output.visible_characters) / CHARS_PER_SECOND, 0.01)
	_typing_tween = create_tween()
	_typing_tween.tween_property(_output, "visible_characters", target, duration)
	_typing_tween.tween_callback(func() -> void: _output.visible_characters = -1)


func _on_input_submitted(text: String) -> void:
	_input.clear()
	submit_command(text)
	_input.grab_focus()
