extends RefCounted
## Robot de partie : joue une campagne complète (jours 1 à 20) en passant
## uniquement par l'API de GameState, comme le ferait l'interface, avec des
## choix tirés au sort selon un « profil » de joueur. Sert à vérifier que toutes
## les fins sont atteignables, qu'aucune partie ne se bloque, et à mesurer
## l'équilibre des indicateurs. Outil de test : n'est jamais chargé par le jeu.
##
## Déterministe : même graine + même profil = même partie.
##
## Profil (toutes les clés sont facultatives) :
##   investigate   0..1  probabilité de faire chaque geste d'enquête
##   solve         0..1  probabilité de réussir un mini-jeu (comparer, frise, pointeuse)
##   field         0..1  probabilité de se rendre sur le terrain quand c'est possible
##   decide        "random" | "veritas" | "contrarian" (tout sauf l'avis de VERITAS) | "first" | "last"
##   veritas_rate  0..1  avec "veritas" : part des dossiers où l'avis est suivi (sinon au hasard)
##   decide_today  0..1  probabilité de conclure un dossier le jour même (sinon plus tard)
##   accept        0..1  probabilité d'accepter une promotion proposée
##   overtime      bool  le robot accepte-t-il les heures supplémentaires ?
##   careful       bool  au téléphone, au tri et le soir, choisit ce qui attire le
##                       moins la suspicion (radio toujours basse)

var rng := RandomNumberGenerator.new()
var profile: Dictionary = {}
## Journal de la partie : ce qui a été choisi (pour le rapport de couverture).
var log := {
	"decisions": [],      # "case.decision.outcome"
	"evenings": [],       # "jour.action[.volume]"
	"calls": [],          # "appel.réponse" ou "appel.missed"
	"letters": [],        # "lettre.verdict"
	"field": [],          # "scène.choix"
	"reviews": [],        # "acte.accepted|refused|denied"
	"minigames": [],      # "case.comparison|timeline|punch_clock|redaction"
	"undecided_at_end": [],
	"problems": [],       # anomalies détectées pendant la partie
	"sources": {},        # d'où viennent les points : {source: {indicateur: total}}
}
var _before := {}


## Mémorise les indicateurs avant un geste...
func _mark() -> void:
	_before = GameState.indicators.duplicate()


## ...puis attribue l'écart à une source (« décision 40921 », « soirée »...).
func _credit(source: String) -> void:
	for indicator in GameState.indicators:
		var delta := int(GameState.indicators[indicator]) - int(_before.get(indicator, 0))
		if delta == 0:
			continue
		if not log.sources.has(source):
			log.sources[source] = {}
		log.sources[source][indicator] = int(log.sources[source].get(indicator, 0)) + delta
	_mark()


func _init(seed_value: int, player_profile: Dictionary) -> void:
	rng.seed = seed_value
	profile = player_profile


func _p(key: String, default_value: float) -> float:
	return float(profile.get(key, default_value))


func _chance(key: String, default_value: float) -> bool:
	return rng.randf() < _p(key, default_value)


func _pick(items: Array) -> Variant:
	return items[rng.randi_range(0, items.size() - 1)]


## Profil prudent : parmi les choix, l'un de ceux qui coûtent le moins de suspicion.
func _pick_careful(items: Array, effects_of: Callable) -> Variant:
	if not profile.get("careful", false):
		return _pick(items)
	var best := []
	var lowest := 1 << 30
	for item in items:
		var cost := int((effects_of.call(item) as Dictionary).get("suspicion", 0))
		if cost < lowest:
			lowest = cost
			best = [item]
		elif cost == lowest:
			best.append(item)
	return _pick(best)


## Joue une partie entière. Renvoie le résumé : fin, indicateurs, drapeaux, journal.
func play() -> Dictionary:
	GameState.new_game()
	var guard := 0
	while true:
		guard += 1
		if guard > 60:
			log.problems.append("boucle de jours anormale (plus de 60 journées)")
			break
		_play_day()
		_check_invariants()
		if GameState.has_evening_pending():
			_play_evening()
		if GameState.has_act_review_pending():
			_play_review()
		if GameState.is_final_day():
			break
		_mark()
		var fired := GameState.end_day()
		# Effets des événements du matin, un par un (approximation : bornes 0-100 ignorées).
		for event in fired:
			for indicator in event.get("effects", {}):
				var source := "événement %s" % event.id
				if not log.sources.has(source):
					log.sources[source] = {}
				log.sources[source][indicator] = int(log.sources[source].get(indicator, 0)) + Balance.scaled(indicator, int(event.effects[indicator]))
	for case_id in GameState.cases:
		if GameState.can_decide(case_id):
			log.undecided_at_end.append(case_id)
	# La sauvegarde doit relire exactement l'état de fin de partie.
	var saved := GameState.to_dict()
	GameState.from_dict(saved.duplicate(true))
	if JSON.stringify(GameState.to_dict()) != JSON.stringify(saved):
		log.problems.append("la sauvegarde ne relit pas le même état")
	var result := GameState.get_ending()
	var ending_id: String = result.get("ending", {}).get("id", "")
	if ending_id == "":
		log.problems.append("aucune fin résolue")
	return {
		"ending": ending_id,
		"indicators": GameState.indicators.duplicate(),
		"rank": int(GameState.player.get("rank", 0)),
		"days": GameState.day_index + 1,
		"flags": GameState.flags.duplicate(true),
		"fired_events": GameState.fired_events.duplicate(),
		"assigned": GameState.cases.keys(),
		"overtime_days": GameState.overtime_days.size(),
		"log": log,
	}


func _play_day() -> void:
	_mark()
	var call := GameState.get_pending_call()
	if not call.is_empty() and rng.randf() < 0.85:
		var answer: Dictionary = _pick_careful(call.get("answers", []),
				func(a: Dictionary) -> Dictionary: return a.get("effects", {}))
		if GameState.answer_call(call.id, answer.id) == "" and str(answer.get("reply", "")) != "":
			log.problems.append("jour %d : réponse refusée à l'appel %s" % [GameState.day_index, call.id])
		log.calls.append("%s.%s" % [call.id, answer.id])
	elif not call.is_empty():
		log.calls.append("%s.missed" % call.id)
	for letter in GameState.get_pending_letters():
		if rng.randf() < 0.8:
			var verdict: String = _pick_careful(MailSorting.VERDICTS,
					func(v: String) -> Dictionary: return MailSorting.resolve(letter, v).get("effects", {}))
			if not GameState.sort_letter(letter.id, verdict):
				log.problems.append("jour %d : tri refusé pour %s" % [GameState.day_index, letter.id])
			log.letters.append("%s.%s" % [letter.id, verdict])
		else:
			log.letters.append("%s.%s" % [letter.id, MailSorting.DEFAULT_VERDICT])
	_credit("téléphone et courrier")
	# Les dossiers dans un ordre tiré au sort : le temps de la journée est limité.
	var case_ids: Array = GameState.cases.keys()
	_shuffle(case_ids)
	for case_id in case_ids:
		if GameState.can_decide(case_id):
			_investigate(case_id)
			_credit("enquête %s" % case_id)
		elif GameState.can_start_field(case_id) and _chance("field", 0.6):
			# Une scène peut s'ouvrir sur un dossier refermé (le couloir de BRANDT, 54100).
			var scene := GameState.get_field_scene(case_id)
			if _can_spend(scene.get("time_action", "interrogate")):
				_play_field(case_id, scene)
				_credit("terrain %s" % case_id)
	for case_id in case_ids:
		if not GameState.can_decide(case_id):
			continue
		var view := GameState.get_case_view(case_id)
		if view.get("decisions", []).is_empty():
			log.problems.append("jour %d : dossier %s sans aucune décision possible" % [GameState.day_index, case_id])
			continue
		var urgent := GameState.deadline_status(case_id) == "pending"
		if urgent or _chance("decide_today", 0.8) or GameState.is_final_day():
			_decide(case_id, view)


func _shuffle(items: Array) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Variant = items[i]
		items[i] = items[j]
		items[j] = tmp


## Le robot respecte la journée de 8 h, sauf profil « heures supplémentaires ».
func _can_spend(action: String) -> bool:
	var check := WorkTime.check(GameState.hours_used, action)
	if not check.ok:
		return false
	if WorkTime.is_overtime(GameState.hours_used + WorkTime.cost(action)) and not profile.get("overtime", false):
		return false
	return true


func _investigate(case_id: String) -> void:
	var view := GameState.get_case_view(case_id)
	var case_data := CaseLibrary.get_case(case_id)
	# Lire et noter (gratuit).
	for document in view.get("documents", []):
		if not _chance("investigate", 0.7):
			continue
		GameState.mark_document_viewed(case_id, document.id)
		for fact in document.get("facts", []):
			if _chance("investigate", 0.7):
				GameState.note_fact(case_id, fact.id)
	# Confronter les éléments notés qui se contredisent (gratuit).
	var noted: Array = GameState.get_case_state(case_id).noted_facts
	for i in noted.size():
		for j in range(i + 1, noted.size()):
			if CaseLibrary.confront(case_data, noted[i], noted[j]) != "" and _chance("investigate", 0.7):
				GameState.confront_facts(case_id, noted[i], noted[j])
	# Fiche d'enquête (niveau débutant) : retenir une des deux versions, au hasard.
	if profile.get("sheet", true):
		for question in CaseSheet.build(view, GameState.get_case_state(case_id)):
			if not question.conflict.is_empty() and not GameState.get_case_state(case_id).sheet_choices.has(question.id) \
					and _chance("investigate", 0.5):
				GameState.retain_version(case_id, question.id, _pick(question.conflict))
	# Prouver une contradiction repérée qui a un prix.
	for key in GameState.get_case_state(case_id).contradictions_noticed.duplicate():
		var state := GameState.contradiction_prove_state(case_id, key)
		if state.affordable and (not state.overtime or profile.get("overtime", false)) and _chance("investigate", 0.5):
			GameState.prove_contradiction(case_id, key)
	# Demander une pièce, consulter le supérieur.
	if GameState.is_feature_unlocked("request_document"):
		for document in GameState.get_requestable_documents(case_id):
			if _chance("investigate", 0.5) and _can_spend("request_document"):
				GameState.request_document(case_id, document.id)
	if _chance("investigate", 0.3) and _can_spend("consult_superior"):
		GameState.consult_superior(case_id)
	# Mini-jeux : réussis selon le profil.
	if not ComparisonRules.get_comparison(case_data).is_empty() and _chance("solve", 0.6):
		if not GameState.apply_comparison(case_id).is_empty():
			log.minigames.append("%s.comparison" % case_id)
	var timeline := TimelineRules.get_timeline(case_data)
	if not timeline.is_empty() and _chance("solve", 0.6):
		if not GameState.apply_timeline(case_id, TimelineRules.solution(timeline)).is_empty():
			log.minigames.append("%s.timeline" % case_id)
	var clock := PunchClockRules.get_punch_clock(case_data)
	if not clock.is_empty() and _chance("solve", 0.6):
		if GameState.apply_punch_clock(case_id, clock.get("answer", [])).get("established", "") != "":
			log.minigames.append("%s.punch_clock" % case_id)
	var line_ids := RedactionRules.line_ids(case_data)
	if not line_ids.is_empty() and GameState.get_case_state(case_id).get("redacted_lines", []).is_empty():
		for line_id in line_ids:
			if rng.randf() < 0.5:
				GameState.toggle_redaction(case_id, line_id)
		log.minigames.append("%s.redaction.%d" % [case_id, GameState.get_case_state(case_id).get("redacted_lines", []).size()])
	# Terrain.
	if GameState.can_start_field(case_id) and _chance("field", 0.6):
		var scene := GameState.get_field_scene(case_id)
		if _can_spend(scene.get("time_action", "interrogate")):
			_play_field(case_id, scene)


func _play_field(case_id: String, scene: Dictionary) -> void:
	if GameState.start_field(case_id).is_empty():
		log.problems.append("jour %d : terrain %s annoncé possible mais refusé" % [GameState.day_index, scene.id])
		return
	var guard := 0
	while guard < 40:
		guard += 1
		var state := GameState.get_field_state(scene.id)
		if state.get("finished", false):
			return
		var options := GameState.get_field_options(scene.id)
		var noted: Array = GameState.get_case_state(case_id).noted_facts
		var presentable: Array = []
		for presentation in scene.get("presentations", []):
			for fact_id in presentation.get("facts", []):
				if fact_id in noted and not presentation.id in state.get("chosen", []):
					presentable.append(fact_id)
		if not presentable.is_empty() and rng.randf() < 0.3:
			var fact_id: String = _pick(presentable)
			if not GameState.field_present(scene.id, fact_id).is_empty():
				log.field.append("%s.present.%s" % [scene.id, fact_id])
				continue
		if options.is_empty():
			GameState.field_leave(scene.id)
			return
		var option: Dictionary = _pick(options)
		if GameState.field_choose(scene.id, option.id).is_empty():
			log.problems.append("terrain %s : choix %s proposé mais refusé" % [scene.id, option.id])
			GameState.field_leave(scene.id)
			return
		log.field.append("%s.%s" % [scene.id, option.id])
	log.problems.append("terrain %s : scène sans fin (40 tours)" % scene.id)


func _decide(case_id: String, view: Dictionary) -> void:
	var decisions: Array = view.get("decisions", [])
	var choice := ""
	match str(profile.get("decide", "random")):
		"veritas":
			if rng.randf() < _p("veritas_rate", 1.0):
				choice = Veritas.recommendation(view, GameState.get_case_state(case_id), GameState.flags).get("decision_id", "")
		"contrarian":
			var advised: String = Veritas.recommendation(view, GameState.get_case_state(case_id), GameState.flags).get("decision_id", "")
			var others := decisions.filter(func(d: Dictionary) -> bool: return d.id != advised)
			if not others.is_empty():
				choice = _pick(others).id
		"first":
			choice = decisions[0].id
		"last":
			choice = decisions[-1].id
	if choice == "":
		choice = _pick(decisions).id
	var result := GameState.apply_decision(case_id, choice)
	if result.is_empty():
		log.problems.append("jour %d : décision %s.%s refusée" % [GameState.day_index, case_id, choice])
		return
	_credit("décision %s" % case_id)
	log.decisions.append("%s.%s.%s" % [case_id, choice, result.response_id])


func _play_evening() -> void:
	_mark()
	_evening()
	_credit("soirées")


func _evening() -> void:
	var day := GameState.day_index
	if GameState.is_overtime_today():
		GameState.lose_evening()
		log.evenings.append("%d.lost" % day)
		return
	var actions := GameState.get_evening_actions()
	if actions.is_empty():
		log.problems.append("jour %d : soirée sans aucune action" % day)
		GameState.lose_evening()
		return
	var action: Dictionary = _pick_careful(actions,
			func(a: Dictionary) -> Dictionary: return EveningRules.resolve(a, GameState.get_condition_state()).get("effects", {}))
	var volume := ""
	if RadioRules.is_radio(action):
		volume = RadioRules.LOW if profile.get("careful", false) or rng.randf() < 0.5 else RadioRules.LOUD
	if GameState.choose_evening_action(action.id, volume).is_empty():
		log.problems.append("jour %d : action de soirée %s refusée" % [day, action.id])
	log.evenings.append("%d.%s%s" % [day, action.id, "." + volume if volume != "" else ""])


func _play_review() -> void:
	var review := GameState.get_act_review()
	var accept := _chance("accept", 0.6)
	_mark()
	GameState.complete_act_review(accept)
	_credit("promotions")
	var verdict := "denied"
	if review.evaluation.eligible:
		verdict = "accepted" if accept else "refused"
	log.reviews.append("%d.%s" % [review.act, verdict])


func _check_invariants() -> void:
	for indicator in GameState.indicators:
		var value := int(GameState.indicators[indicator])
		if value < GameState.INDICATOR_MIN or value > GameState.INDICATOR_MAX:
			log.problems.append("jour %d : indicateur %s hors bornes (%d)" % [GameState.day_index, indicator, value])
	if GameState.hours_used > WorkTime.day_hours() + WorkTime.overtime_hours():
		log.problems.append("jour %d : heures dépassées (%d)" % [GameState.day_index, GameState.hours_used])
