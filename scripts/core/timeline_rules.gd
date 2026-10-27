class_name TimelineRules
extends RefCounted
## Mini-jeu « frise chronologique » (acte 2), logique pure. Le joueur remet des
## repères datés dans l'ordre. Bien ordonner la frise met en évidence qu'un fait
## tombe là où il ne peut pas être innocent (l'anomalie) : cela établit une
## contradiction du dossier, comme la comparaison de pièces. Le jeu ne tranche
## rien et n'invente rien — les dates sont déjà écrites dans les pièces.
##
## Bloc "timeline" d'un dossier (facultatif) :
## {
##   "id", "title", "intro",
##   "conditions"?,                      mêmes conditions que les pièces (requires_flags...)
##   "entries": [ {
##       "id", "label",
##       "date",                         clé triable, par ex. "1986-10-20" (AAAA-MM-JJ)
##       "decisive"?,                    repère qui porte l'anomalie
##       "note"?                         précision affichée une fois la frise juste
##   } ],
##   "establishes": "<clé de contradiction>",   posée si la frise est remise dans l'ordre
##   "advantage": {"note_facts", "set_flags", "effects", "text"}
## }


static func get_timeline(case_data: Dictionary) -> Dictionary:
	return case_data.get("timeline", {})


## Repères triés dans le vrai ordre chronologique (par "date").
static func sorted_entries(timeline: Dictionary) -> Array:
	var entries: Array = timeline.get("entries", []).duplicate()
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("date", "")) < str(b.get("date", "")))
	return entries


## Identifiants des repères dans le vrai ordre.
static func solution(timeline: Dictionary) -> Array:
	return sorted_entries(timeline).map(func(e: Dictionary) -> String: return e.get("id", ""))


## Note l'ordre proposé par le joueur. `order` : liste d'identifiants de repères.
## Renvoie {correct, decisive_ok, misplaced} : correct = l'ordre complet est juste ;
## decisive_ok = le repère décisif est à sa vraie place.
static func grade(timeline: Dictionary, order: Array) -> Dictionary:
	var truth := solution(timeline)
	var decisive_id := ""
	for entry in timeline.get("entries", []):
		if entry.get("decisive", false):
			decisive_id = entry.get("id", "")
	var misplaced := 0
	var decisive_ok := true
	for i in truth.size():
		var placed: String = order[i] if i < order.size() else ""
		if placed != truth[i]:
			misplaced += 1
			if truth[i] == decisive_id or placed == decisive_id:
				decisive_ok = false
	return {"correct": misplaced == 0 and order.size() == truth.size(),
			"decisive_ok": decisive_ok, "misplaced": misplaced}
