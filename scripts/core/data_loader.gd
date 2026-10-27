class_name DataLoader
extends RefCounted
## Lecture des fichiers de données JSON du dossier res://data.
## Point unique d'accès disque pour le contenu du jeu (pas pour les sauvegardes).
##
## Traduction : quand une autre langue que le français est active, chaque texte
## lu est remplacé par sa traduction si elle existe (translations, rempli par
## Localization depuis data/locale/<langue>/). Les identifiants, drapeaux et
## chemins ne sont jamais dans ce dictionnaire : ils restent intacts.

const LOCALE_DIR := "res://data/locale/"

## Texte français -> texte traduit, pour la langue active (vide : français).
static var translations: Dictionary = {}


## Charge un fichier JSON et renvoie son contenu sous forme de Dictionary.
## Renvoie un Dictionary vide et affiche une erreur si le fichier est absent ou invalide.
static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("DataLoader: fichier introuvable : %s" % path)
		return {}
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("DataLoader: JSON invalide dans %s (ligne %d) : %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}
	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("DataLoader: %s doit contenir un objet JSON à la racine." % path)
		return {}
	if translations.is_empty() or path.begins_with(LOCALE_DIR):
		return json.data
	return translate(json.data)


## Traduit récursivement les textes d'une donnée (les clés restent intactes).
static func translate(value: Variant) -> Variant:
	if value is String:
		return translations.get(value, value)
	if value is Dictionary:
		for key in value:
			value[key] = translate(value[key])
	elif value is Array:
		for i in value.size():
			value[i] = translate(value[i])
	return value
