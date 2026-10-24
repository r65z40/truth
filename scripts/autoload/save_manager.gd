extends Node
## Sauvegarde locale de la partie, au format JSON versionné.
##
## Format du fichier :
##   { "save_version": int, "game_version": String, "saved_at": String, "state": {...} }
## Quand le format de "state" change : incrémenter SAVE_VERSION et ajouter une
## étape dans _migrate() pour convertir les anciennes sauvegardes.

signal game_saved
signal game_loaded

## Historique des versions :
## 1 : prototype 0.1.
## 2 : carnet d'enquête (noted_facts, contradictions_found) dans chaque dossier.
const SAVE_VERSION := 2
const DEFAULT_PATH := "user://savegame.json"

## Fichier utilisé quand aucun chemin n'est précisé (les tests le redirigent).
var save_path := DEFAULT_PATH


func has_save(path := "") -> bool:
	return FileAccess.file_exists(_resolve(path))


## Écrit l'état de la partie. Renvoie OK ou un code d'erreur Godot.
func save_game(state: Node = null, path := "") -> Error:
	path = _resolve(path)
	if state == null:
		state = GameState
	var payload := {
		"save_version": SAVE_VERSION,
		"game_version": ProjectSettings.get_setting("application/config/version", "0"),
		"saved_at": Time.get_datetime_string_from_system(),
		"state": state.to_dict(),
	}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: impossible d'écrire %s (%s)" % [path, error_string(FileAccess.get_open_error())])
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	game_saved.emit()
	return OK


## Charge une sauvegarde dans l'état de la partie.
## En cas d'erreur, l'état actuel n'est pas modifié.
func load_game(state: Node = null, path := "") -> Error:
	path = _resolve(path)
	if state == null:
		state = GameState
	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or typeof(json.data) != TYPE_DICTIONARY:
		push_error("SaveManager: sauvegarde illisible : %s" % path)
		return ERR_PARSE_ERROR
	var payload: Dictionary = _migrate(json.data)
	if payload.is_empty():
		return ERR_INVALID_DATA
	state.from_dict(payload.state)
	game_loaded.emit()
	return OK


func delete_save(path := "") -> void:
	path = _resolve(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _resolve(path: String) -> String:
	return save_path if path.is_empty() else path


## Met une sauvegarde au format actuel. Renvoie {} si elle est inutilisable.
func _migrate(payload: Dictionary) -> Dictionary:
	var version := int(payload.get("save_version", 0))
	if version > SAVE_VERSION:
		push_error("SaveManager: sauvegarde créée par une version plus récente du jeu (v%d)." % version)
		return {}
	if version < 1 or typeof(payload.get("state")) != TYPE_DICTIONARY:
		push_error("SaveManager: format de sauvegarde inconnu.")
		return {}
	if version == 1:
		for case_state in payload.state.get("cases", {}).values():
			case_state["noted_facts"] = case_state.get("noted_facts", [])
			case_state["contradictions_found"] = case_state.get("contradictions_found", [])
		version = 2
	payload.save_version = version
	return payload
