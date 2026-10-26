class_name ComparisonRules
extends RefCounted
## Mini-jeu « comparer deux pièces » (logique pure). Deux pièces du dossier sont
## posées côte à côte ; pour chaque trait, le joueur juge lui-même si les deux
## mentions concordent ou non. Le jeu ne tranche pas à sa place et n'invente
## rien : la vérité de chaque trait est déjà écrite dans les pièces. Bien juger
## le trait décisif — sans fabriquer de fausses différences — établit une
## contradiction du dossier (l'avantage), comme une confrontation du carnet.
##
## Bloc "comparison" d'un dossier (facultatif) :
## {
##   "id", "title", "intro",
##   "conditions"?,                          mêmes conditions que les pièces (requires_flags...)
##   "left":  {"label", "photo_document"?, "mark"?},   pièce de gauche
##   "right": {"label", "photo_document"?, "mark"?},   pièce de droite
##   "points": [ {
##       "id", "label",
##       "field"?,                            trait de photo (face/hair/glasses/...)
##       "detail_left"?, "detail_right"?,     mention exacte portée par chaque pièce
##       "decisive"?,                         trait qui porte la contradiction
##       "note"?                              précision affichée après le jugement
##   } ],
##   "establishes": "<clé de contradiction>",             posée si la comparaison est juste
##   "advantage": {"note_facts", "set_flags", "effects", "text"}
## }

## Rendu lisible des valeurs d'un trait de photo (voir IdPhoto).
const VALUE_LABELS := {
	"face": {"round": "visage rond", "long": "visage allongé"},
	"hair": {"short": "cheveux courts", "long": "cheveux longs", "curly": "cheveux bouclés",
			"receding": "cheveux dégarnis", "bald": "crâne rasé"},
	"glasses": {true: "avec lunettes", false: "sans lunettes"},
	"facial_hair": {"none": "visage glabre", "mustache": "moustache", "beard": "barbe"},
	"mark": {"none": "aucun signe particulier", "scar": "cicatrice", "mole": "grain de beauté"},
}


static func get_comparison(case_data: Dictionary) -> Dictionary:
	return case_data.get("comparison", {})


## Photo d'une pièce du dossier (clé "photo"), ou {}.
static func photo_of(case_data: Dictionary, document_id: String) -> Dictionary:
	for document in case_data.get("documents", []):
		if document.get("id", "") == document_id:
			return document.get("photo", {})
	return {}


## Compare un trait entre les deux pièces. Utilise la mention exacte
## (detail_left/detail_right) si elle est fournie, sinon le trait de photo.
## Renvoie {differs, decisive, left, right} (left/right : textes à afficher).
static func compare_point(point: Dictionary, left_photo: Dictionary, right_photo: Dictionary) -> Dictionary:
	var left_detail: String = point.get("detail_left", "")
	var right_detail: String = point.get("detail_right", "")
	var differs: bool
	if left_detail != "" or right_detail != "":
		differs = left_detail != right_detail
	else:
		var field: String = point.get("field", "")
		var left_value: Variant = left_photo.get(field, _default_for(field))
		var right_value: Variant = right_photo.get(field, _default_for(field))
		differs = left_value != right_value
		left_detail = _label(field, left_value)
		right_detail = _label(field, right_value)
	return {
		"differs": differs,
		"decisive": point.get("decisive", false),
		"left": left_detail,
		"right": right_detail,
	}


## Note le jugement du joueur. `verdicts` : {point_id: true si « différent »}.
## Un trait non jugé compte comme une erreur. Renvoie
## {wrong, all_ok, decisive_ok} : all_ok = aucune erreur (condition de l'avantage).
static func grade(comparison: Dictionary, left_photo: Dictionary, right_photo: Dictionary,
		verdicts: Dictionary) -> Dictionary:
	var wrong := 0
	var decisive_ok := true
	for point in comparison.get("points", []):
		var point_id: String = point.get("id", "")
		var truth: bool = compare_point(point, left_photo, right_photo).differs
		# Trait non jugé : erreur (il faut se prononcer sur chaque pièce).
		if not verdicts.has(point_id) or bool(verdicts[point_id]) != truth:
			wrong += 1
			if point.get("decisive", false):
				decisive_ok = false
	return {"wrong": wrong, "all_ok": wrong == 0, "decisive_ok": decisive_ok}


static func _default_for(field: String) -> Variant:
	return false if field == "glasses" else "none"


static func _label(field: String, value: Variant) -> String:
	return VALUE_LABELS.get(field, {}).get(value, str(value))
