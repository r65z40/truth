class_name CallRules
extends RefCounted
## Le téléphone (logique pure) : appels courts, deux ou trois réponses, sans
## chronomètre. L'agent décroche quand il veut pendant le service ; un appel non
## pris le soir est manqué. Tout l'état tient dans les drapeaux :
## « call.<id>.<réponse> » ou « call.<id>.missed ». Données : data/calls.json.

const DATA_PATH := "res://data/calls.json"

static var _data := {}


static func get_data() -> Dictionary:
	if _data.is_empty():
		_data = DataLoader.load_json(DATA_PATH)
	return _data


static func get_call(call_id: String) -> Dictionary:
	for call in get_data().get("calls", []):
		if call.get("id", "") == call_id:
			return call
	return {}


## L'appel a-t-il déjà été pris ou manqué ?
static func is_done(call: Dictionary, flags: Dictionary) -> bool:
	var prefix := "call.%s." % call.get("id", "")
	for key in flags:
		if str(key).begins_with(prefix):
			return true
	return false


## Premier appel en attente (le téléphone sonne), ou {}.
static func pending(state: Dictionary) -> Dictionary:
	var flags: Dictionary = state.get("flags", {})
	for call in get_data().get("calls", []):
		if not is_done(call, flags) and EventRules.are_conditions_met(call.get("conditions", {}), state):
			return call
	return {}


## Conséquence d'une réponse : {reply, effects, flags} ; {} si la réponse est inconnue.
static func answer(call: Dictionary, answer_id: String) -> Dictionary:
	for entry in call.get("answers", []):
		if entry.get("id", "") == answer_id:
			var flags: Dictionary = entry.get("flags", {}).duplicate()
			flags["call.%s.%s" % [call.id, answer_id]] = true
			return {"reply": entry.get("reply", ""), "effects": entry.get("effects", {}), "flags": flags}
	return {}


## Conséquence d'un appel manqué.
static func missed(call: Dictionary) -> Dictionary:
	var block: Dictionary = call.get("missed", {})
	var flags: Dictionary = block.get("flags", {}).duplicate()
	flags["call.%s.missed" % call.id] = true
	return {"effects": block.get("effects", {}), "flags": flags}
