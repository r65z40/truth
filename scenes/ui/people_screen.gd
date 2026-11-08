class_name PeopleScreen
extends ColorRect
## Le répertoire des personnes : une ligne par personne croisée (nom, rôle,
## dossier, statut). Lecture seule ; PeopleDirectory choisit quoi montrer.

signal closed

const GROUP_TITLES := {
	"ministry": "AU MINISTÈRE",
	"family": "PROCHES ET VOISINS",
	"subjects": "SUJETS ET TÉMOINS",
}

var _rows: VBoxContainer
var _empty: Label


func _init() -> void:
	name = "PeopleScreen"
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Même voile que les autres écrans posés sur le bureau.
	color = Color(0.02, 0.025, 0.022, 0.88)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var card := PanelContainer.new()
	card.theme_type_variation = &"DocumentPanel"
	card.custom_minimum_size = Vector2(760, 0)
	center.add_child(card)
	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 22)
	card.add_child(pad)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	pad.add_child(column)
	var kicker := Label.new()
	kicker.theme_type_variation = &"MutedLabel"
	kicker.text = "RÉPERTOIRE"
	column.add_child(kicker)
	var title := _label(column, &"HeaderLabel")
	title.text = "Personnes croisées"
	var intro := _label(column, &"MutedLabel")
	intro.text = "Une fiche s'ajoute à chaque dossier ouvert. Le rôle suit ce que vous savez, pas plus."
	_empty = _label(column, &"DocumentLabel")
	_empty.text = "Aucune fiche pour l'instant."
	_rows = VBoxContainer.new()
	_rows.name = "Rows"
	_rows.add_theme_constant_override("separation", 8)
	column.add_child(_rows)
	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "FERMER"
	close_button.custom_minimum_size = Vector2(0, 48)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	close_button.pressed.connect(close)
	column.add_child(close_button)


func _label(parent: Control, variation: StringName) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label


func open() -> void:
	refresh()
	show()


func refresh() -> void:
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	var entries := PeopleDirectory.visible_entries(GameState.get_condition_state())
	_empty.visible = entries.is_empty()
	var group := ""
	for entry: Dictionary in entries:
		if entry.group != group:
			group = entry.group
			var heading := _label(_rows, &"MutedLabel")
			heading.text = tr(GROUP_TITLES.get(group, ""))
		var row := _label(_rows, &"DocumentLabel")
		row.name = "Person_" + str(entry.id)
		var line: String = entry.name
		if entry.case != "":
			line += "  //  " + tr("dossier %s") % entry.case
		if entry.stamp != "":
			line += "  //  " + entry.stamp
		row.text = line + "\n" + entry.role


func close() -> void:
	hide()
	closed.emit()
