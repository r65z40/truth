extends MinistryWindow
## Fenêtre « Archives » (provisoire) : dossiers clos de la partie.
## Les archives historiques consultables viendront avec la progression de carrière.

@onready var _archive_text: RichTextLabel = %ArchiveText


func _on_opened() -> void:
	var lines: PackedStringArray = ["[b]ARCHIVES CENTRALES  //  FONDS DE LA SECTION 4[/b]", ""]
	var closed_count := 0
	for case_id in GameState.cases:
		var case_state: Dictionary = GameState.cases[case_id]
		if case_state.decision == "":
			continue
		var case_data := CaseLibrary.get_case(case_id)
		var decision := CaseLibrary.get_decision(case_data, case_state.decision)
		var status := "en cours d'enquête" if case_state.status == GameState.CASE_UNDER_INVESTIGATION else "clos"
		lines.append("- Dossier n° %s : %s  //  %s (%s)" % [case_id, case_data.get("subject_name", "?"),
				decision.get("label", "?"), status])
		closed_count += 1
	if closed_count == 0:
		lines.append("Aucun rapport transmis par cet agent.")
	lines.append("")
	lines.append("[color=#d04a3a]ACCÈS AUX ARCHIVES HISTORIQUES : HABILITATION DE NIVEAU 3 REQUISE.[/color]")
	lines.append("Votre habilitation actuelle : niveau 1 (%s)." % GameState.get_rank_title())
	_archive_text.text = "\n".join(lines)
