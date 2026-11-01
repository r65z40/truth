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
## Pli d'accueil, puis mémento « qui fait quoi » (Milice, Section 7, VERITAS...),
## à lire avant le premier dossier.
const WELCOME_MESSAGE_ID := "welcome_mazur"
const MEMO_MESSAGE_ID := "memento_agent"


## state : {cases, flags, day_index} (GameState.get_condition_state()), plus
## hours_used (heures de service employées aujourd'hui, 0 par défaut).
## messages : GameState.messages
static func next_step(state: Dictionary, messages: Array) -> Dictionary:
	for message in messages:
		if message.id == WELCOME_MESSAGE_ID and not message.read:
			return _step(UiText.of("Lire le message de prise de fonction de R. MAZUR."),
					UiText.of("Cliquez sur l'icône COURRIER, dans la colonne de gauche."), "messages", "",
					UiText.of("Bienvenue, inspecteur. Pas d'inquiétude : je vous guide pas à pas. Suivez le bandeau « À FAIRE », en haut, et l'icône qui clignote. Pour commencer, ouvrez votre courrier."))
	for message in messages:
		if message.id == MEMO_MESSAGE_ID and not message.read:
			return _step(UiText.of("Lire le mémento : qui fait quoi au ministère (Milice, Section 7, VERITAS...)."),
					UiText.of("Dans le COURRIER, cliquez sur le pli « Mémento de l'agent »."), "messages", "",
					UiText.of("Avant votre premier dossier, lisez le mémento. Il explique qui est la Milice, ce que fait la Section 7, à quoi sert VERITAS, et comment finir votre journée."))
	# Plus une heure de service, même en heures supplémentaires : il ne reste qu'à rentrer.
	if WorkTime.remaining(int(state.get("hours_used", 0))) <= 0:
		return _step(UiText.of("Vos heures de service sont épuisées : terminez la journée."),
				UiText.of("Bouton FIN DE SERVICE, en bas à droite."), "end_day", "",
				UiText.of("Il n'y a plus une heure à prendre aujourd'hui. Cliquez sur FIN DE SERVICE, en bas à droite : les dossiers en cours vous attendront demain."))
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
			return _case_step(case_id, _step(UiText.of("Ouvrir le dossier n° %s (%s).") % [case_id, view.get("subject_name", "?")],
					UiText.of("Cliquez sur DOSSIERS, puis sur le dossier."), "dossiers", "case",
					guide.get("open", UiText.of("Un dossier vous attend : n° %s, %s. Ouvrez-le.") % [case_id, view.get("subject_name", "?")])))
		if viewed < total:
			return _case_step(case_id, _step(UiText.of("Lire toutes les pièces du dossier n° %s (%d/%d).") % [case_id, viewed, total],
					UiText.of("Les pièces marquées « à lire » restent à consulter."), "dossiers",
					"tab:" + next_unviewed,
					guide.get("read", UiText.of("Lisez chaque pièce : cliquez sur la pièce signalée (%d/%d).") % [viewed, total])))
		if case_state.get("noted_facts", []).size() < MIN_NOTED_FACTS:
			return _case_step(case_id, _step(UiText.of("Noter les éléments importants du dossier n° %s dans votre carnet.") % case_id,
					UiText.of("Cliquez sur les passages soulignés du texte (ou « + NOTER »)."), "dossiers", "facts",
					guide.get("facts", UiText.of("Sous la pièce, cliquez sur les éléments qui vous semblent importants : ils vont dans votre carnet."))))
		# Mini-jeu facultatif mais conseillé : quand le dossier propose une
		# confrontation de pièces accessible, on la met en avant, avec la loupe
		# pour examiner cachets et signatures de près.
		var comparison: Dictionary = ComparisonRules.get_comparison(view)
		if case_state.get("contradictions_found", []).is_empty() and not comparison.is_empty() \
				and EventRules.are_conditions_met(comparison.get("conditions", {}), state):
			return _case_step(case_id, _step(
					UiText.of("Comparer deux pièces du dossier n° %s, ou confronter deux éléments du carnet.") % case_id,
					UiText.of("Bouton COMPARER. Touchez AGRANDIR pour examiner une pièce de près."), "dossiers", "compare",
					guide.get("compare", UiText.of("Deux pièces de ce dossier peuvent se contredire. Ouvrez COMPARER, et servez-vous de la loupe (AGRANDIR) pour examiner de près les cachets et les signatures."))))
		if case_state.get("contradictions_found", []).is_empty():
			return _case_step(case_id, _step(UiText.of("Confronter deux éléments du carnet, ou rédiger votre conclusion."),
					UiText.of("Sélectionnez deux éléments à gauche, puis CONFRONTER."), "dossiers", "notebook",
					guide.get("notebook", UiText.of("Dans le carnet, à gauche, choisissez deux éléments qui ne disent pas la même chose, puis CONFRONTER."))))
		return _case_step(case_id, _step(UiText.of("Rédiger et signer la conclusion du dossier n° %s.") % case_id,
				UiText.of("Bouton RÉDIGER LA CONCLUSION, en bas du dossier."), "dossiers", "conclusion",
				guide.get("conclusion", UiText.of("Vous en savez assez. Rédigez votre conclusion et signez."))))
	var unread := 0
	for message in messages:
		if not message.read:
			unread += 1
	if unread > 0:
		return _step(UiText.of("Lire vos nouveaux messages (%d).") % unread, UiText.of("Cliquez sur l'icône COURRIER, à gauche."), "messages", "",
				UiText.of("Du courrier est arrivé : la suite de vos décisions s'y trouve."))
	return _step(UiText.of("Aucune tâche en attente : vous pouvez terminer votre journée."),
			UiText.of("Bouton FIN DE SERVICE, en bas à droite."), "end_day", "",
			UiText.of("Le travail du jour est fait. Rentrez chez vous : FIN DE SERVICE."))


static func _step(text: String, hint: String, target: String, part := "", coach := "") -> Dictionary:
	return {"text": text, "hint": hint, "target": target, "part": part, "coach": coach if coach != "" else text,
			"case_id": ""}


static func _case_step(case_id: String, step: Dictionary) -> Dictionary:
	step["case_id"] = case_id
	return step
