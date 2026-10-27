class_name DeskTraces
extends RefCounted
## Traces sur le bureau (logique pure) : data/desk_traces.json décrit de petits
## papiers posés sur le bureau, visibles tant que leurs conditions (jour, acte,
## drapeaux, indicateurs) sont remplies. Simple affichage : aucune trace ne
## change l'état de la partie.

const TRACES_PATH := "res://data/desk_traces.json"
## Au plus autant de papiers à la fois, pour ne pas encombrer le bureau.
const MAX_VISIBLE := 3


static func get_data() -> Dictionary:
	return DataLoader.load_json(TRACES_PATH)


## Traces visibles pour cet état ; les dernières du fichier l'emportent.
static func visible_traces(state: Dictionary, data: Dictionary = get_data()) -> Array:
	var matching: Array = data.get("traces", []).filter(func(trace: Dictionary) -> bool:
		return MusicRules.are_conditions_met(trace.get("conditions", {}), state))
	return matching.slice(maxi(matching.size() - MAX_VISIBLE, 0))
