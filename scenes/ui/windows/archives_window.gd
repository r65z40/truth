extends MinistryWindow
## Fenêtre « Archives » (provisoire) : dossiers clos de la partie.
## Les archives historiques consultables viendront avec la progression de carrière.

@onready var _archive_text: RichTextLabel = %ArchiveText


func _on_opened() -> void:
	var lines: PackedStringArray = ["[b]ARCHIVES CENTRALES  //  FONDS DE LA SECTION 4[/b]", ""]
	var closed_count := 0
	for case_id in GameState.cases:
		if GameState.cases[case_id].status == GameState.CASE_CLOSED:
			var case_data := CaseLibrary.get_case(case_id)
			lines.append("- Dossier n° %s : %s" % [case_id, case_data.get("subject_name", "?")])
			closed_count += 1
	if closed_count == 0:
		lines.append("Aucun dossier clos par cet agent.")
	lines.append("")
	lines.append("[color=#d04a3a]ACCÈS AUX ARCHIVES HISTORIQUES : HABILITATION DE NIVEAU 3 REQUISE.[/color]")
	lines.append("Votre habilitation actuelle : niveau 1 (%s)." % GameState.get_rank_title())
	_archive_text.text = "\n".join(lines)
