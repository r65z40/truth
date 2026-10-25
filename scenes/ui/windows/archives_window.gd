class_name ArchivesWindow
extends MinistryWindow
## Fenêtre « Archives » : les rapports transmis par l'agent, rangés en chemises.
## Un clic rouvre le dossier. Le fonds historique reste verrouillé tant que
## l'habilitation de l'agent est insuffisante (il viendra avec la carrière).

## L'agent veut rouvrir un dossier archivé.
signal case_requested(case_id: String)

@onready var _archive_list: VBoxContainer = %ArchiveList
@onready var _empty_hint: Label = %ArchiveEmpty
@onready var _clearance: Label = %ClearanceLabel
@onready var _lock_icon: TextureRect = %LockIcon


func _ready() -> void:
	super()
	_lock_icon.texture = PixelIcons.get_icon("lock", 3)


func _on_opened() -> void:
	for child in _archive_list.get_children():
		_archive_list.remove_child(child)
		child.queue_free()
	for entry in archived_cases():
		var button := Button.new()
		button.name = "Archive_" + entry.case_id
		button.text = "N° %s  //  %s\n%s  //  %s" % [entry.case_id, entry.subject, entry.decision, entry.status]
		button.icon = PixelIcons.get_icon("dossiers", 2)
		button.theme_type_variation = &"DocumentTab"
		button.tooltip_text = "Rouvrir le dossier n° %s." % entry.case_id
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0, 64)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(case_requested.emit.bind(entry.case_id))
		_archive_list.add_child(button)
	_empty_hint.visible = _archive_list.get_child_count() == 0
	_clearance.text = "ACCÈS AUX ARCHIVES HISTORIQUES : HABILITATION DE NIVEAU 3 REQUISE.\nVotre habilitation actuelle : niveau 1 (%s)." % GameState.get_rank_title()


## Dossiers conclus par l'agent : {case_id, subject, decision, status}.
static func archived_cases() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for case_id in GameState.cases:
		var case_state: Dictionary = GameState.cases[case_id]
		if case_state.decision == "":
			continue
		var case_data := CaseLibrary.get_case(case_id)
		entries.append({
			"case_id": case_id,
			"subject": case_data.get("subject_name", "?"),
			"decision": CaseLibrary.get_decision(case_data, case_state.decision).get("label", "?"),
			"status": "en cours d'enquête" if case_state.status == GameState.CASE_UNDER_INVESTIGATION else "clos",
		})
	return entries
