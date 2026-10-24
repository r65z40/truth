class_name Guidance
extends RefCounted
## Aide à l'enquête : déduit de l'état de la partie le prochain pas conseillé au
## joueur (affiché en haut du bureau, désactivable dans les paramètres).
## Logique pure : ne fait que lire l'état.
##
## Renvoie {text, hint, target}. target désigne le bouton du bureau à signaler :
## "messages", "dossiers", "end_day" ou "".

const MIN_NOTED_FACTS := 2


## state : {cases, flags, day_index} (GameState.get_condition_state())
## messages : GameState.messages
static func next_step(state: Dictionary, messages: Array) -> Dictionary:
	for message in messages:
		if message.id == "welcome_mazur" and not message.read:
			return _step("Lire le message de prise de fonction de R. MAZUR.",
					"Cliquez sur MESSAGES, à droite.", "messages")
	var cases: Dictionary = state.get("cases", {})
	for case_id in cases:
		var case_state: Dictionary = cases[case_id]
		if case_state.get("decision", "") != "":
			continue
		var view := CaseLibrary.filter_case(CaseLibrary.get_case(case_id), state)
		var total: int = view.get("documents", []).size()
		var viewed := 0
		for document in view.get("documents", []):
			if document.id in case_state.get("viewed_documents", []):
				viewed += 1
		if viewed == 0:
			return _step("Ouvrir le dossier n° %s (%s)." % [case_id, view.get("subject_name", "?")],
					"Cliquez sur DOSSIERS, puis sur le dossier.", "dossiers")
		if viewed < total:
			return _step("Lire toutes les pièces du dossier n° %s (%d/%d)." % [case_id, viewed, total],
					"Les onglets beiges au-dessus de la pièce changent de document.", "dossiers")
		if case_state.get("noted_facts", []).size() < MIN_NOTED_FACTS:
			return _step("Noter les éléments importants du dossier n° %s dans votre carnet." % case_id,
					"Boutons « + NOTER » sous chaque pièce.", "dossiers")
		if case_state.get("contradictions_found", []).is_empty():
			return _step("Confronter deux éléments du carnet, ou rédiger votre conclusion.",
					"Sélectionnez deux éléments à gauche, puis CONFRONTER.", "dossiers")
		return _step("Rédiger et signer la conclusion du dossier n° %s." % case_id,
				"Bouton RÉDIGER LA CONCLUSION, en bas du dossier.", "dossiers")
	var unread := 0
	for message in messages:
		if not message.read:
			unread += 1
	if unread > 0:
		return _step("Lire vos nouveaux messages (%d)." % unread, "Cliquez sur MESSAGES.", "messages")
	return _step("Aucune tâche en attente : vous pouvez terminer votre journée.",
			"Bouton FIN DE SERVICE, en bas à droite.", "end_day")


static func _step(text: String, hint: String, target: String) -> Dictionary:
	return {"text": text, "hint": hint, "target": target}
