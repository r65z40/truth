class_name ComparisonRules
extends RefCounted
## Mini-jeu « comparer deux pièces » (logique pure). Deux documents sont posés
## côte à côte ; le joueur pointe, trait par trait, ce qui diffère. Le jeu ne
## fabrique rien : il révèle une différence déjà écrite dans les pièces. Trouver
## le trait décisif établit une contradiction du dossier (avantage), exactement
## comme une confrontation du carnet — en plus direct.
##
## Bloc "comparison" d'un dossier (facultatif) :
## {
##   "id", "title", "intro",
##   "left":  {"label", "photo_document"},   pièce de gauche (photo)
##   "right": {"label", "photo_document"},   pièce de droite (photo)
##   "points": [ {"id", "label", "field", "decisive"?} ],  traits comparés
##   "establishes": "<clé de contradiction>",             posée si le trait décisif diffère
##   "advantage": {"note_facts": [...], "set_flags": {...}, "effects": {...}, "text"}
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


## Compare un trait entre les deux photos. Renvoie
## {differs, decisive, left, right} (left/right : libellés lisibles).
static func compare_point(point: Dictionary, left_photo: Dictionary, right_photo: Dictionary) -> Dictionary:
	var field: String = point.get("field", "")
	var left_value: Variant = left_photo.get(field, _default_for(field))
	var right_value: Variant = right_photo.get(field, _default_for(field))
	return {
		"differs": left_value != right_value,
		"decisive": point.get("decisive", false),
		"left": _label(field, left_value),
		"right": _label(field, right_value),
	}


static func _default_for(field: String) -> Variant:
	return false if field == "glasses" else "none"


static func _label(field: String, value: Variant) -> String:
	return VALUE_LABELS.get(field, {}).get(value, str(value))
