class_name DataLoader
extends RefCounted
## Lecture des fichiers de données JSON du dossier res://data.
## Point unique d'accès disque pour le contenu du jeu (pas pour les sauvegardes).


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
	return json.data
