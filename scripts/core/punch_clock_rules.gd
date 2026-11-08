class_name PunchClockRules
extends RefCounted
## Mini-jeu « la pointeuse » (logique pure) : le ruban encreur d'une horloge de
## pointage garde l'empreinte de chaque passage. L'agent touche les jours où le
## ruban dément un certificat. La bonne sélection établit une contradiction du
## dossier, comme la comparaison et la frise. Rien n'est inventé : le ruban ne dit
## que ce que la pièce du service technique dit déjà (l'horloge marchait).
##
## Bloc "punch_clock" d'un dossier (facultatif) :
## {
##   "id", "title", "intro", "conditions"?,
##   "rows": [ {"id", "label", "punches", "certificate"} ],
##   "answer": ["<id de ligne>", ...],          les jours où le ruban dément un certificat
##   "establishes": "<clé de contradiction>",
##   "advantage": {"note_facts", "set_flags", "effects", "text"}
## }


static func get_punch_clock(case_data: Dictionary) -> Dictionary:
	var block: Variant = case_data.get("punch_clock", {})
	return block if block is Dictionary else {}


## Note une sélection : {correct, missing, wrong}.
static func grade(punch_clock: Dictionary, selected: Array) -> Dictionary:
	var answer: Array = punch_clock.get("answer", [])
	var missing := answer.filter(func(row_id: String) -> bool: return not row_id in selected).size()
	var wrong := selected.filter(func(row_id: Variant) -> bool: return not row_id in answer).size()
	return {"correct": missing == 0 and wrong == 0 and not answer.is_empty(), "missing": missing, "wrong": wrong}


## Contrôle de cohérence des données : réponses connues, contradiction existante.
static func validate(case_data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var block := get_punch_clock(case_data)
	if block.is_empty():
		return errors
	var ids: Array = block.get("rows", []).map(func(row: Dictionary) -> String: return row.get("id", ""))
	for row_id in block.get("answer", []):
		if not row_id in ids:
			errors.append("pointeuse : réponse inconnue %s" % row_id)
	for fact_id in block.get("advantage", {}).get("note_facts", []):
		if CaseLibrary.get_fact(case_data, fact_id).is_empty():
			errors.append("pointeuse : élément inconnu %s" % fact_id)
	return errors
