extends Node
## Traduction du jeu. Le français est la langue source : les clés de traduction
## sont les textes français eux-mêmes. Une chaîne sans traduction s'affiche donc
## en français, ce qui permet de traduire progressivement.
##
## Interface : les textes des scènes (Label, Button...) sont traduits
## automatiquement par Godot via TranslationServer, à partir de data/locale/<lang>.json.
## Contenu des dossiers : surcouches dans data/locale/<lang>/case_<id>.json, fusionnées
## par CaseLibrary ; un champ non traduit reste en français.

signal locale_changed

const SOURCE_LOCALE := "fr"
const LOCALES := ["fr", "en"]
const LOCALE_LABELS := {"fr": "Français", "en": "English"}
const UI_PATH := "res://data/locale/%s.json"
const CASE_OVERLAY_PATH := "res://data/locale/%s/case_%s.json"

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
	locale_changed.emit()


## Vrai si la langue courante n'est pas la langue source (français).
func is_translated() -> bool:
	return locale != SOURCE_LOCALE


## Dossier localisé : fusionne la surcouche de la langue courante sur le dossier
## français. Sans surcouche, renvoie le dossier français inchangé.
func localize_case(case_data: Dictionary) -> Dictionary:
	if not is_translated() or case_data.is_empty():
		return case_data
	var overlay := DataLoader.load_json(CASE_OVERLAY_PATH % [locale, case_data.get("id", "")])
	if overlay.is_empty():
		return case_data
	return _merge(case_data.duplicate(true), overlay)


func _register_ui_translation(code: String) -> void:
	var entries := DataLoader.load_json(UI_PATH % code)
	if entries.is_empty():
		return
	var translation := Translation.new()
	translation.locale = code
	for source in entries:
		translation.add_message(source, str(entries[source]))
	TranslationServer.add_translation(translation)


## Fusionne récursivement la surcouche « over » sur « base ». Les tableaux d'objets
## sont appariés par « id » ; les autres valeurs de la surcouche remplacent la base.
static func _merge(base: Variant, over: Variant) -> Variant:
	if base is Dictionary and over is Dictionary:
		for key in over:
			base[key] = _merge(base.get(key), over[key]) if base.has(key) else over[key]
		return base
	if base is Array and over is Array:
		var by_id := {}
		for item in base:
			if item is Dictionary and item.has("id"):
				by_id[item.id] = item
		for item in over:
			if item is Dictionary and item.has("id") and by_id.has(item.id):
				_merge(by_id[item.id], item)
		return base
	return over
