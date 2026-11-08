extends Node
## Lance des centaines de parties jouées par le robot (playthrough_bot.gd) et
## écrit un rapport : fins atteintes par profil de joueur, contenu jamais vu
## (réponses, événements, soirées, terrain), anomalies, équilibre des indicateurs.
##
##   godot --headless --path . res://tests/tools/playthrough_report.tscn -- <dossier> [parties_par_profil] [pourcentage]
##
## [pourcentage] (facultatif) remplace le réglage des hausses de suspicion de
## data/rules/balance.json le temps du rapport, pour comparer deux réglages.
##
## Écrit <dossier>/playthrough.md et <dossier>/playthrough.json. La sauvegarde
## est redirigée vers le fichier de test : la partie du joueur n'est pas touchée.

const Bot := preload("res://tests/tools/playthrough_bot.gd")

## Profils de joueurs simulés (voir playthrough_bot.gd).
const PROFILES := {
	"hasard": {},
	"zele": {"investigate": 0.95, "solve": 0.95, "field": 0.95, "overtime": true, "accept": 0.5},
	"obeissant": {"decide": "veritas", "investigate": 0.5, "accept": 1.0},
	"paresseux": {"investigate": 0.15, "solve": 0.2, "field": 0.1, "decide_today": 0.5},
	"premier_choix": {"decide": "first", "investigate": 0.8, "solve": 0.8},
	"prudent": {"careful": true, "investigate": 0.8, "solve": 0.8},
	"prudent_obeissant": {"careful": true, "decide": "veritas", "investigate": 0.6, "accept": 1.0},
	"mixte": {"decide": "veritas", "veritas_rate": 0.6, "careful": true, "investigate": 0.8, "solve": 0.8},
	"mixte_risque": {"decide": "veritas", "veritas_rate": 0.4, "investigate": 0.8, "solve": 0.8},
	"rebelle": {"decide": "contrarian", "careful": true, "investigate": 0.9, "solve": 0.9, "field": 0.8},
	"dernier_choix": {"decide": "last", "investigate": 0.8, "solve": 0.8, "accept": 0.2},
}


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://playthrough"
	var games := int(args[1]) if args.size() > 1 else 200
	SaveManager.save_path = "user://test_savegame.json"
	if args.size() > 2:
		Balance.override_percent = int(args[2])
	DirAccess.make_dir_recursive_absolute(out_dir)
	var started := Time.get_ticks_msec()
	var runs := []
	var seed_value := 1
	for profile_id in PROFILES:
		for i in games:
			var bot := Bot.new(seed_value, PROFILES[profile_id])
			var result: Dictionary = bot.play()
			result["profile"] = profile_id
			result["seed"] = seed_value
			runs.append(result)
			seed_value += 1
		print("profil %s : %d parties" % [profile_id, games])
	var report := _analyse(runs)
	report["seconds"] = (Time.get_ticks_msec() - started) / 1000.0
	var json_file := FileAccess.open(out_dir.path_join("playthrough.json"), FileAccess.WRITE)
	json_file.store_string(JSON.stringify(report, "\t"))
	# Données brutes par partie (fin, indicateurs, drapeaux lus par les fins) pour
	# tester d'autres seuils sans rejouer.
	var watched := {}
	for ending in EndingRules.get_endings():
		for rule in ending.get("rules", []):
			for flag in rule.get("requires_flags", []) + rule.get("forbidden_flags", []):
				watched[flag] = true
	for flag in EndingRules.spared_flags():
		watched[flag] = true
	var raw := runs.map(func(run: Dictionary) -> Dictionary:
		var kept := {}
		for flag in watched:
			if run.flags.get(flag) == true:
				kept[flag] = true
		return {"profile": run.profile, "seed": run.seed, "ending": run.ending, "indicators": run.indicators, "flags": kept})
	var raw_file := FileAccess.open(out_dir.path_join("runs.json"), FileAccess.WRITE)
	raw_file.store_string(JSON.stringify(raw))
	var md_file := FileAccess.open(out_dir.path_join("playthrough.md"), FileAccess.WRITE)
	md_file.store_string(_markdown(report))
	print("RAPPORT ÉCRIT : %s (%d parties, %.1f s)" % [out_dir, runs.size(), report.seconds])
	get_tree().quit(0)


func _analyse(runs: Array) -> Dictionary:
	var endings_by_profile := {}
	var ending_total := {}
	var problems := {}
	var seen := {"outcomes": {}, "events": {}, "evenings": {}, "calls": {}, "field": {}, "reviews": {}, "assigned": {}}
	var indicator_stats := {}
	var undecided := 0
	var example_seed := {}
	var sources := {}
	var by_profile := {}
	for run in runs:
		if not by_profile.has(run.profile):
			by_profile[run.profile] = {"games": 0, "suspicion": 0, "loyalty": 0, "influence": 0, "sources": {}}
		var bucket: Dictionary = by_profile[run.profile]
		bucket.games += 1
		for indicator in ["suspicion", "loyalty", "influence"]:
			bucket[indicator] += int(run.indicators.get(indicator, 0))
		for source in run.log.sources:
			var value := int(run.log.sources[source].get("suspicion", 0))
			bucket.sources[source] = bucket.sources.get(source, 0) + value
		for source in run.log.sources:
			if not sources.has(source):
				sources[source] = {}
			for indicator in run.log.sources[source]:
				sources[source][indicator] = sources[source].get(indicator, 0) + int(run.log.sources[source][indicator])
		var profile: String = run.profile
		if not endings_by_profile.has(profile):
			endings_by_profile[profile] = {}
		endings_by_profile[profile][run.ending] = endings_by_profile[profile].get(run.ending, 0) + 1
		ending_total[run.ending] = ending_total.get(run.ending, 0) + 1
		if not example_seed.has(run.ending):
			example_seed[run.ending] = "%s / graine %d" % [profile, run.seed]
		for problem in run.log.problems:
			problems[problem] = problems.get(problem, 0) + 1
		for entry in run.log.decisions:
			var parts: PackedStringArray = entry.split(".")
			seen.outcomes["%s.%s" % [parts[0], parts[2]]] = true
		for event_id in run.fired_events:
			seen.events[event_id] = true
		for entry in run.log.evenings:
			var parts: PackedStringArray = entry.split(".")
			if parts.size() > 1:
				seen.evenings["%s.%s" % [parts[0], parts[1]]] = true
		for entry in run.log.calls:
			seen.calls[entry] = true
		for entry in run.log.field:
			seen.field[entry] = true
		for entry in run.log.reviews:
			seen.reviews[entry] = true
		for case_id in run.assigned:
			seen.assigned[case_id] = true
		undecided += run.log.undecided_at_end.size()
		for indicator in run.indicators:
			if not indicator_stats.has(indicator):
				indicator_stats[indicator] = {"min": 100, "max": 0, "sum": 0}
			var value := int(run.indicators[indicator])
			indicator_stats[indicator].min = mini(indicator_stats[indicator].min, value)
			indicator_stats[indicator].max = maxi(indicator_stats[indicator].max, value)
			indicator_stats[indicator].sum += value
	for indicator in indicator_stats:
		indicator_stats[indicator]["mean"] = snappedf(float(indicator_stats[indicator].sum) / runs.size(), 0.1)
	for source in sources:
		for indicator in sources[source]:
			sources[source][indicator] = snappedf(float(sources[source][indicator]) / runs.size(), 0.1)
	for profile in by_profile:
		var bucket: Dictionary = by_profile[profile]
		for indicator in ["suspicion", "loyalty", "influence"]:
			bucket[indicator] = snappedf(float(bucket[indicator]) / bucket.games, 0.1)
		for source in bucket.sources:
			bucket.sources[source] = snappedf(float(bucket.sources[source]) / bucket.games, 0.1)
	return {
		"games": runs.size(),
		"by_profile": by_profile,
		"near_misses": _near_misses(runs),
		"sources": sources,
		"endings_by_profile": endings_by_profile,
		"endings_total": ending_total,
		"endings_never": EndingRules.get_endings().map(func(e: Dictionary) -> String: return e.id).filter(
				func(id: String) -> bool: return not ending_total.has(id)),
		"ending_examples": example_seed,
		"problems": problems,
		"indicators": indicator_stats,
		"undecided_at_end": undecided,
		"unseen": _unseen(seen),
	}


## Pour chaque fin : combien de parties remplissaient les drapeaux d'une de ses
## règles, et pourquoi elles ne l'ont pas obtenue (seuil d'indicateur manqué, ou
## une fin placée avant elle dans l'ordre a gagné).
func _near_misses(runs: Array) -> Dictionary:
	var result := {}
	for ending in EndingRules.get_endings():
		var rules: Array = ending.get("rules", [])
		if rules.is_empty():
			continue
		var entry := {"flags_ok": 0, "reached": 0, "threshold_missed": {}, "won_by_other": {}}
		for run in runs:
			var indicators: Dictionary = run.indicators.duplicate()
			indicators["spared"] = EndingRules.count_spared(run.flags)
			var state := {"flags": run.flags, "indicators": indicators, "day_index": 0, "cases": {}, "fired_events": []}
			var flags_ok := false
			var missed := []
			for rule in rules:
				var flags_only: Dictionary = rule.duplicate()
				flags_only.erase("min_indicators")
				flags_only.erase("max_indicators")
				if EventRules.are_conditions_met(flags_only, state):
					flags_ok = true
					if not EventRules.are_conditions_met(rule, state):
						for indicator in rule.get("min_indicators", {}):
							if int(indicators.get(indicator, 0)) < int(rule.min_indicators[indicator]):
								missed.append("%s < %d" % [indicator, int(rule.min_indicators[indicator])])
						for indicator in rule.get("max_indicators", {}):
							if int(indicators.get(indicator, 0)) > int(rule.max_indicators[indicator]):
								missed.append("%s > %d" % [indicator, int(rule.max_indicators[indicator])])
			if not flags_ok:
				continue
			entry.flags_ok += 1
			if run.ending == ending.id:
				entry.reached += 1
			elif not missed.is_empty() and not EndingRules._is_reached(ending, state):
				for reason in missed:
					entry.threshold_missed[reason] = entry.threshold_missed.get(reason, 0) + 1
			else:
				entry.won_by_other[run.ending] = entry.won_by_other.get(run.ending, 0) + 1
		result[ending.id] = entry
	return result


## Tout ce que les données prévoient et qu'aucune partie n'a montré.
func _unseen(seen: Dictionary) -> Dictionary:
	var outcomes := []
	var cases_never := []
	for case_id in CaseLibrary.get_case_ids():
		if not seen.assigned.has(case_id):
			cases_never.append(case_id)
		var responses := {}
		for decision in CaseLibrary.get_case(case_id).get("decisions", []):
			for outcome in decision.get("outcomes", []):
				responses[outcome.get("response", "")] = true
		for response in responses:
			if response != "" and not seen.outcomes.has("%s.%s" % [case_id, response]):
				outcomes.append("%s.%s" % [case_id, response])
	var events := []
	for event in EventRules.get_events():
		if not seen.events.has(event.id):
			events.append(event.id)
	var evenings := []
	for evening in EveningRules.get_data().get("evenings", []):
		for action in evening.get("actions", []):
			if not seen.evenings.has("%d.%s" % [int(evening.day), action.id]):
				evenings.append("jour %d : %s" % [int(evening.day), action.id])
	var calls := []
	for call in CallRules.get_data().get("calls", []):
		for answer in call.get("answers", []):
			if not seen.calls.has("%s.%s" % [call.id, answer.id]):
				calls.append("%s.%s" % [call.id, answer.id])
	var field := []
	for path in DirAccess.get_files_at("res://data/field/"):
		if not path.ends_with(".json"):
			continue
		var scene := FieldRules.get_scene(path.get_basename())
		for option in FieldRules.all_options(scene):
			if not seen.field.has("%s.%s" % [scene.id, option.id]):
				field.append("%s.%s" % [scene.id, option.id])
		for presentation in scene.get("presentations", []):
			var found := false
			for fact_id in presentation.get("facts", []):
				if seen.field.has("%s.present.%s" % [scene.id, fact_id]):
					found = true
			if not found:
				field.append("%s.présenter:%s" % [scene.id, presentation.id])
	return {"cases": cases_never, "outcomes": outcomes, "events": events, "evenings": evenings,
			"calls": calls, "field": field, "reviews": seen.reviews.keys()}


func _markdown(report: Dictionary) -> String:
	var lines := ["# Rapport du robot de partie", "",
			"%d parties complètes, %.0f s." % [report.games, report.seconds], "", "## Fins atteintes", ""]
	var profiles: Array = report.endings_by_profile.keys()
	lines.append("| Fin | Total | " + " | ".join(profiles) + " |")
	lines.append("|---|---|" + "---|".repeat(profiles.size()))
	for ending in EndingRules.get_endings():
		var row := "| %s | %d |" % [ending.title, report.endings_total.get(ending.id, 0)]
		for profile in profiles:
			row += " %d |" % report.endings_by_profile[profile].get(ending.id, 0)
		lines.append(row)
	lines.append("")
	lines.append("Jamais atteintes : %s" % (", ".join(report.endings_never) if not report.endings_never.is_empty() else "aucune"))
	lines.append("")
	lines.append("### Fins manquées de peu")
	lines.append("")
	lines.append("Parties qui avaient les drapeaux d'une fin, et ce qui les en a privées :")
	lines.append("")
	for ending_id in report.near_misses:
		var miss: Dictionary = report.near_misses[ending_id]
		lines.append("- %s : drapeaux réunis dans %d parties, fin obtenue %d fois ; seuil manqué %s ; une autre fin a gagné %s"
				% [ending_id, miss.flags_ok, miss.reached, JSON.stringify(miss.threshold_missed), JSON.stringify(miss.won_by_other)])
	lines.append("")
	lines.append("## Anomalies")
	lines.append("")
	if report.problems.is_empty():
		lines.append("Aucune.")
	for problem in report.problems:
		lines.append("- %s (%d fois)" % [problem, report.problems[problem]])
	lines.append("")
	lines.append("Dossiers laissés sans conclusion en fin de partie : %d" % report.undecided_at_end)
	lines.append("")
	lines.append("## Indicateurs en fin de partie")
	lines.append("")
	for indicator in report.indicators:
		var stats: Dictionary = report.indicators[indicator]
		lines.append("- %s : min %d, moyenne %.1f, max %d" % [indicator, stats.min, stats.mean, stats.max])
	lines.append("")
	lines.append("| Profil | Loyauté | Suspicion | Influence |")
	lines.append("|---|---|---|---|")
	for profile in report.by_profile:
		var bucket: Dictionary = report.by_profile[profile]
		lines.append("| %s | %.1f | %.1f | %.1f |" % [profile, bucket.loyalty, bucket.suspicion, bucket.influence])
	lines.append("")
	lines.append("## D'où vient la suspicion (moyenne par partie)")
	lines.append("")
	var by_suspicion: Array = report.sources.keys().filter(
			func(source: String) -> bool: return report.sources[source].get("suspicion", 0.0) != 0.0)
	by_suspicion.sort_custom(func(a: String, b: String) -> bool:
			return report.sources[a].get("suspicion", 0.0) > report.sources[b].get("suspicion", 0.0))
	for source in by_suspicion.slice(0, 25):
		lines.append("- %s : %+.1f" % [source, report.sources[source].suspicion])
	lines.append("")
	lines.append("## Contenu jamais vu")
	for section in ["cases", "outcomes", "events", "evenings", "calls", "field"]:
		var items: Array = report.unseen[section]
		lines.append("")
		lines.append("### %s (%d)" % [section, items.size()])
		for item in items:
			lines.append("- %s" % item)
	lines.append("")
	lines.append("Revues d'acte vues : %s" % ", ".join(report.unseen.reviews))
	return "\n".join(lines) + "\n"
