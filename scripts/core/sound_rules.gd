class_name SoundRules
extends RefCounted
## Bruitages et ambiances (logique pure) : data/sounds.json déclare les sons
## brefs (« effects »), les boucles de fond (« ambiances ») et la règle qui
## choisit l'ambiance de chaque moment du jeu, comme MusicRules pour la musique.

const SOUNDS_PATH := "res://data/sounds.json"

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		_data = DataLoader.load_json(SOUNDS_PATH)
	return _data


## Fiche d'un son bref : {files, volume_db, pitch_variation, usage} ; vide si inconnu.
static func get_effect(effect_id: String) -> Dictionary:
	return data().get("effects", {}).get(effect_id, {})


static func get_effect_ids() -> Array:
	return data().get("effects", {}).keys()


## Variantes du son réellement présentes dans le projet.
static func available_files(effect_id: String) -> Array:
	return get_effect(effect_id).get("files", []).filter(MediaLibrary.exists)


## Fichier à jouer : une variante parmi celles présentes ("" : silence).
## roll (0..1) choisit la variante ; il vient de l'appelant pour rester testable.
static func pick_file(effect_id: String, roll: float) -> String:
	var files := available_files(effect_id)
	if files.is_empty():
		return ""
	return files[clampi(int(roll * files.size()), 0, files.size() - 1)]


static func get_ambiance(ambiance_id: String) -> Dictionary:
	return data().get("ambiances", {}).get(ambiance_id, {})


## Ambiance de ce contexte selon l'état de la partie ("" : aucune).
static func ambiance_for(context: String, state: Dictionary) -> String:
	for rule in data().get("ambiance_rules", []):
		var contexts = rule.get("context", "")
		var matches: bool = context in contexts if contexts is Array else context == contexts
		if matches and MusicRules.are_conditions_met(rule.get("conditions", {}), state):
			return rule.get("ambiance", "")
	return ""


## Son joué automatiquement pour un signal de GameState ({signal: effet}).
static func game_events() -> Dictionary:
	return data().get("game_events", {})
