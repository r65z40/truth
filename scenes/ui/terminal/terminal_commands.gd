class_name TerminalCommands
extends RefCounted
## Interprétation des commandes du terminal. Logique pure, sans interface,
## pour pouvoir être testée et réutilisée (clavier, boutons tactiles, futur VERITAS).

enum Action { NONE, HELP, OPEN_APP, CLEAR, DATE, IDENT, SAVE, END_DAY, MENU, VERITAS, DEBUG_STATE, UNKNOWN }

## Mot-clé normalisé -> [action, cible]
const COMMANDS := {
	"AIDE": [Action.HELP, ""],
	"HELP": [Action.HELP, ""],
	"?": [Action.HELP, ""],
	"DOSSIERS": [Action.OPEN_APP, "dossiers"],
	"DOSSIER": [Action.OPEN_APP, "dossiers"],
	"DOS": [Action.OPEN_APP, "dossiers"],
	"MESSAGES": [Action.OPEN_APP, "messages"],
	"MESSAGE": [Action.OPEN_APP, "messages"],
	"MSG": [Action.OPEN_APP, "messages"],
	"COURRIER": [Action.OPEN_APP, "messages"],
	"ARCHIVES": [Action.OPEN_APP, "archives"],
	"ARCHIVE": [Action.OPEN_APP, "archives"],
	"ARC": [Action.OPEN_APP, "archives"],
	"PROFIL": [Action.OPEN_APP, "personnel"],
	"PERSONNEL": [Action.OPEN_APP, "personnel"],
	"EVALUATION": [Action.OPEN_APP, "personnel"],
	"EFFACER": [Action.CLEAR, ""],
	"CLS": [Action.CLEAR, ""],
	"CLEAR": [Action.CLEAR, ""],
	"DATE": [Action.DATE, ""],
	"HEURE": [Action.DATE, ""],
	"IDENT": [Action.IDENT, ""],
	"AGENT": [Action.IDENT, ""],
	"STATUT": [Action.IDENT, ""],
	"SAUVER": [Action.SAVE, ""],
	"SAUVEGARDER": [Action.SAVE, ""],
	"FIN": [Action.END_DAY, ""],
	"FINSERVICE": [Action.END_DAY, ""],
	"MENU": [Action.MENU, ""],
	"DECONNEXION": [Action.MENU, ""],
	"QUITTER": [Action.MENU, ""],
	"VERITAS": [Action.VERITAS, ""],
	# Réservé au développement : affiche les indicateurs internes (versions debug uniquement).
	"ETAT": [Action.DEBUG_STATE, ""],
	# Mots-clés anglais (version traduite du jeu).
	"FILES": [Action.OPEN_APP, "dossiers"],
	"FILE": [Action.OPEN_APP, "dossiers"],
	"MAIL": [Action.OPEN_APP, "messages"],
	"INBOX": [Action.OPEN_APP, "messages"],
	"PROFILE": [Action.OPEN_APP, "personnel"],
	"TIME": [Action.DATE, ""],
	"STATUS": [Action.IDENT, ""],
	"SAVE": [Action.SAVE, ""],
	"END": [Action.END_DAY, ""],
	"LOGOUT": [Action.MENU, ""],
	"QUIT": [Action.MENU, ""],
}

const HELP_LINES := [
	"COMMANDES DISPONIBLES :",
	"  DOSSIERS   ouvrir les dossiers assignés",
	"  MESSAGES   consulter la messagerie interne",
	"  ARCHIVES   accéder aux archives",
	"  PROFIL     consulter votre dossier personnel",
	"  IDENT      afficher l'identité de l'agent",
	"  DATE       afficher la date et l'heure de service",
	"  VERITAS    consulter le système d'analyse (VERITAS POURQUOI : détail)",
	"  FIN        terminer la journée de service",
	"  SAUVER     enregistrer la session",
	"  EFFACER    effacer l'écran",
	"  MENU       se déconnecter (menu principal)",
]

const _ACCENTS := {"É": "E", "È": "E", "Ê": "E", "Ë": "E", "À": "A", "Â": "A",
		"Î": "I", "Ï": "I", "Ô": "O", "Ù": "U", "Û": "U", "Ü": "U", "Ç": "C"}


## Met une saisie au format des mots-clés : majuscules, sans accents ni espaces superflus.
static func normalize(raw: String) -> String:
	var text := raw.strip_edges().to_upper()
	for accent in _ACCENTS:
		text = text.replace(accent, _ACCENTS[accent])
	return text


## Analyse une saisie. Renvoie {action: Action, target: String, args: PackedStringArray, input: String}.
static func parse(raw: String) -> Dictionary:
	var input := normalize(raw)
	var words := input.split(" ", false)
	if words.is_empty():
		return {"action": Action.NONE, "target": "", "args": PackedStringArray(), "input": input}
	var keyword := words[0]
	var args := words.slice(1)
	if not COMMANDS.has(keyword):
		return {"action": Action.UNKNOWN, "target": "", "args": args, "input": input}
	var command: Array = COMMANDS[keyword]
	return {"action": command[0], "target": command[1], "args": args, "input": input}
