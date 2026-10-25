class_name Guidance
extends RefCounted
## Aide à l'enquête : déduit de l'état de la partie le prochain pas conseillé au
## joueur (affiché en haut du bureau, désactivable dans les paramètres).
## Logique pure : ne fait que lire l'état.
##
## Renvoie {text, hint, target, part, coach}. target désigne l'application du
## bureau : "messages", "dossiers", "end_day" ou "". part précise l'endroit dans
## la fenêtre ouverte : "case", "tab:<pièce>", "facts", "notebook", "conclusion"
## ou "" ; case_id, le dossier concerné.
## coach : conseil plus détaillé pour la bulle d'aide ; un dossier peut le
## préciser dans son bloc "guide" (clés facts, notebook, conclusion), ce que fait
## le premier dossier, qui sert de tutoriel.

const MIN_NOTED_FACTS := 2


## state : {cases, flags, day_index} (GameState.get_condition_state())
## messages : GameState.messages
static func next_step(state: Dictionary, messages: Array) -> Dictionary:
	for message in messages:
		if message.id == "welcome_mazur" and not message.read:
			return _step("Lire le message de prise de fonction de R. MAZUR.",
					"Cliquez sur MESSAGES, à droite.", "messages", "",
					"Bienvenue, inspecteur. Commencez par mon message : il est dans votre courrier.")
	var cases: Dictionary = state.get("cases", {})
	for case_id in cases:
		var case_state: Dictionary = cases[case_id]
		if case_state.get("decision", "") != "":
			continue
		var view := CaseLibrary.filter_case(CaseLibrary.get_case(case_id), state)
		var guide: Dictionary = view.get("guide", {})
		var total: int = view.get("documents", []).size()
		var viewed := 0
		var next_unviewed := ""
		for document in view.get("documents", []):
			if document.id in case_state.get("viewed_documents", []):
				viewed += 1
			elif next_unviewed == "":
				next_unviewed = document.id
		if viewed == 0:
			return _case_step(case_id, _step("Ouvrir le dossier n° %s (%s)." % [case_id, view.get("subject_name", "?")],
					"Cliquez sur DOSSIERS, puis sur le dossier.", "dossiers", "case",
					guide.get("open", "Un dossier vous attend : n° %s, %s. Ouvrez-le." % [case_id, view.get("subject_name", "?")])))
		if viewed < total:
			return _case_step(case_id, _step("Lire toutes les pièces du dossier n° %s (%d/%d)." % [case_id, viewed, total],
					"Les pièces marquées « à lire » restent à consulter.", "dossiers",
					"tab:" + next_unviewed,
					guide.get("read", "Lisez chaque pièce : cliquez sur la pièce signalée (%d/%d)." % [viewed, total])))
		if case_state.get("noted_facts", []).size() < MIN_NOTED_FACTS:
			return _case_step(case_id, _step("Noter les éléments importants du dossier n° %s dans votre carnet." % case_id,
					"Cliquez sur les passages soulignés du texte (ou « + NOTER »).", "dossiers", "facts",
					guide.get("facts", "Sous la pièce, cliquez sur les éléments qui vous semblent importants : ils vont dans votre carnet.")))
		if case_state.get("contradictions_found", []).is_empty():
			return _case_step(case_id, _step("Confronter deux éléments du carnet, ou rédiger votre conclusion.",
					"Sélectionnez deux éléments à gauche, puis CONFRONTER.", "dossiers", "notebook",
					guide.get("notebook", "Dans le carnet, à gauche, choisissez deux éléments qui ne disent pas la même chose, puis CONFRONTER.")))
		return _case_step(case_id, _step("Rédiger et signer la conclusion du dossier n° %s." % case_id,
				"Bouton RÉDIGER LA CONCLUSION, en bas du dossier.", "dossiers", "conclusion",
				guide.get("conclusion", "Vous en savez assez. Rédigez votre conclusion et signez.")))
	var unread := 0
	for message in messages:
		if not message.read:
			unread += 1
	if unread > 0:
		return _step("Lire vos nouveaux messages (%d)." % unread, "Cliquez sur MESSAGES.", "messages", "",
				"Du courrier est arrivé : la suite de vos décisions s'y trouve.")
	return _step("Aucune tâche en attente : vous pouvez terminer votre journée.",
			"Bouton FIN DE SERVICE, en bas à droite.", "end_day", "",
			"Le travail du jour est fait. Rentrez chez vous : FIN DE SERVICE.")


static func _step(text: String, hint: String, target: String, part := "", coach := "") -> Dictionary:
	return {"text": text, "hint": hint, "target": target, "part": part, "coach": coach if coach != "" else text,
			"case_id": ""}


static func _case_step(case_id: String, step: Dictionary) -> Dictionary:
	step["case_id"] = case_id
	return step
