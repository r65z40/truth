extends Node
## Traduction du jeu. Le français est la langue source : les clés de traduction
## sont les textes français eux-mêmes. Une chaîne sans traduction s'affiche donc
## en français, ce qui permet de traduire progressivement.
##
## Interface : les textes des scènes (Label, Button...) sont traduits
## automatiquement par Godot via TranslationServer, à partir de data/locale/<lang>.json ;
## les textes construits en code passent par tr().
## Contenu (dossiers, événements, soirées, journal, terrain, fins...) : les
## fichiers data/locale/<lang>/**/*.json associent chaque texte français à sa
## traduction ; DataLoader remplace les textes à la lecture des données.

signal locale_changed

const SOURCE_LOCALE := "fr"
const LOCALES := ["fr", "en"]
const LOCALE_LABELS := {"fr": "Français", "en": "English"}
const UI_PATH := "res://data/locale/%s.json"
const CONTENT_DIR := "res://data/locale/%s"

var locale := SOURCE_LOCALE


func _ready() -> void:
	# Charge les traductions d'interface des langues autres que la source.
	for code in LOCALES:
		if code == SOURCE_LOCALE:
			continue
		_register_ui_translation(code)
	set_locale(Settings.language if Settings.get("language") != null else SOURCE_LOCALE)


## Change la langue courante et prévient l'interface.
func set_locale(code: String) -> void:
	if not code in LOCALES:
		code = SOURCE_LOCALE
	locale = code
	TranslationServer.set_locale(code)
	DataLoader.translations = {} if code == SOURCE_LOCALE else load_content_translations(code)
	_reset_data_caches()
	locale_changed.emit()


## Vrai si la langue courante n'est pas la langue source (français).
func is_translated() -> bool:
	return locale != SOURCE_LOCALE


## Traduction d'un texte de contenu déjà en mémoire (par exemple un message
## reçu avant un changement de langue) ; inchangé s'il n'a pas de traduction.
func text(source: String) -> String:
	return DataLoader.translations.get(source, source)


## Tous les textes de contenu traduits d'une langue : fusion des fichiers
## data/locale/<code>/**/*.json (les clés commençant par « _ » sont des notes).
static func load_content_translations(code: String) -> Dictionary:
	var result := {}
	for path in _json_files(CONTENT_DIR % code):
		var entries := DataLoader.load_json(path)
		for source in entries:
			if not str(source).begins_with("_"):
				result[source] = entries[source]
	return result


static func _json_files(dir: String) -> Array:
	var files: Array = []
	for file_name in DirAccess.get_files_at(dir):
		if file_name.get_extension() == "json":
			files.append(dir.path_join(file_name))
	for sub in DirAccess.get_directories_at(dir):
		files.append_array(_json_files(dir.path_join(sub)))
	return files


## Les données gardées en mémoire ont été lues dans l'ancienne langue : on les
## oublie pour qu'elles soient relues traduites.
func _reset_data_caches() -> void:
	CaseLibrary._cache = {}
	FictionalCalendar._calendar = {}
	Veritas._params = {}
	NewsRules._data = {}
	MinistryRecord._entries = []
	SoundRules._data = {}
	ImageSlots._data = {}


func _register_ui_translation(code: String) -> void:
	var entries := DataLoader.load_json(UI_PATH % code)
	if entries.is_empty():
		return
	var translation := Translation.new()
	translation.locale = code
	for source in entries:
		translation.add_message(source, str(entries[source]))
	TranslationServer.add_translation(translation)
