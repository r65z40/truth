extends MinistryWindow
## Fenêtre « Dossier personnel » : l'évaluation de l'agent par sa hiérarchie,
## en appréciations (jamais en chiffres).

@onready var _text: RichTextLabel = %PersonnelText


func _on_opened() -> void:
	var assessment := Assessment.describe(GameState.indicators, GameState.flags)
	var lines: PackedStringArray = []
	lines.append("[b]AGENT :[/b] %s     [b]MATRICULE :[/b] %s" % [GameState.player.name, GameState.player.badge])
	lines.append("[b]GRADE :[/b] %s     [b]AFFECTATION :[/b] Section 4" % GameState.get_rank_title())
	lines.append("[b]ÉVALUATION AU :[/b] %s" % GameState.get_date_short())
	lines.append("")
	for line in assessment.lines:
		lines.append("[b]%s :[/b] %s" % [line.label.to_upper(), line.text])
	lines.append("")
	lines.append("[b]OBSERVATIONS :[/b]")
	if assessment.notes.is_empty():
		lines.append("Néant.")
	for note in assessment.notes:
		lines.append("- " + note)
	lines.append("")
	lines.append("[b]DÉCISIONS SIGNÉES :[/b] %d" % GameState.decisions.size())
	_text.text = "\n".join(lines)
