class_name RedactionRules
extends RefCounted
## Caviarder (logique pure, acte 4 MIROIR) : sur le projet rédigé par VERITAS,
## l'agent noircit les lignes de son choix avant de signer « Caviarder ». Ce qui
## reste lisible compte : un caviardage partiel peut encore condamner quelqu'un.
##
## Format dans le JSON du dossier :
##   "redaction": {"document": "<id de la pièce>", "lines": [{"id", "text"}]}
## Chaque texte de ligne figure mot pour mot dans la pièce. Les lignes noircies
## sont gardées dans l'état du dossier (redacted_lines). Conditions de décision
## (voir DecisionRules) : "redacted:a+b" (toutes ces lignes noircies) et
## "redacted_any" (au moins une ligne noircie).


static func get_redaction(case_data: Dictionary) -> Dictionary:
	var redaction: Variant = case_data.get("redaction", {})
	return redaction if redaction is Dictionary else {}


static func line_ids(case_data: Dictionary) -> Array:
	return get_redaction(case_data).get("lines", []).map(func(line: Dictionary) -> String: return line.id)


## Noircit ou rend lisible une ligne ; renvoie la nouvelle liste (inchangée si la
## ligne n'existe pas).
static func toggle(case_data: Dictionary, redacted: Array, line_id: String) -> Array:
	if not line_id in line_ids(case_data):
		return redacted
	var result := redacted.duplicate()
	if line_id in result:
		result.erase(line_id)
	else:
		result.append(line_id)
	return result


## Barre noire de la longueur d'une ligne (affichage).
static func bar(text: String) -> String:
	return "█".repeat(clampi(int(text.length() * 0.6), 6, 80))


## Condition "redacted:a+b" ou "redacted_any" remplie ?
static func is_condition_met(condition: String, redacted: Array) -> bool:
	if condition == "redacted_any":
		return not redacted.is_empty()
	for line_id in condition.trim_prefix("redacted:").split("+", false):
		if not line_id in redacted:
			return false
	return true
