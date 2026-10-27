extends MinistryWindow
## Fenêtre « Dossier personnel » : la fiche d'évaluation de l'agent par sa
## hiérarchie, en appréciations (jamais en chiffres).

@onready var _icon: TextureRect = %PersonnelIcon
@onready var _identity: Label = %PersonnelIdentity
@onready var _text: RichTextLabel = %PersonnelText


func _ready() -> void:
	super()
	_icon.texture = PixelIcons.get_icon("personnel", 4)


func _on_opened() -> void:
	_identity.text = tr("AGENT : %s     MATRICULE : %s
GRADE : %s     AFFECTATION : Section 4
ÉVALUATION AU : %s") % [
		GameState.player.name, GameState.player.badge, GameState.get_rank_title(), GameState.get_date_short()]
	var assessment := Assessment.describe(GameState.indicators, GameState.flags)
	var lines: PackedStringArray = []
	# Extrait d'état civil : la ligne du père est partiellement caviardée et le
	# dossier familial scellé. Visible dès le début, pour qu'on sente vite que
	# quelque chose, autour du père, est tenu hors de portée.
	var record: Dictionary = GameState.player.get("record", {})
	if not record.is_empty():
		lines.append(tr("[b]ÉTAT CIVIL (EXTRAIT) :[/b]"))
		for field in ["born", "father", "sealed"]:
			if record.get(field, "") != "":
				lines.append(record[field])
		lines.append("")
	lines.append(tr("[b]APPRÉCIATIONS DE LA HIÉRARCHIE[/b]"))
	lines.append("")
	for line in assessment.lines:
		lines.append("[b]%s :[/b] %s" % [line.label.to_upper(), line.text])
	lines.append("")
	lines.append(tr("[b]OBSERVATIONS :[/b]"))
	if assessment.notes.is_empty():
		lines.append(tr("Néant."))
	for note in assessment.notes:
		lines.append("- " + note)
	lines.append("")
	lines.append(tr("[b]DÉCISIONS SIGNÉES :[/b] %d") % GameState.decisions.size())
	_text.text = "\n".join(lines)
