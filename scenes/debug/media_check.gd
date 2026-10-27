class_name MediaCheck
extends Control
## Outil « Médias » de la visite des scènes : liste chaque musique, ambiance,
## bruitage et image attendus (MediaCatalog), dit s'il est fourni ou manquant,
## et permet de l'écouter ou de le voir. Après avoir déposé un fichier dans
## Godot, rouvrir cet écran pour vérifier qu'il est bien pris en compte.

const KIND_TITLES := {
	"music": "MUSIQUES  (data/music.json, assets/music/)",
	"ambiance": "AMBIANCES  (data/sounds.json, assets/sounds/ambiances/)",
	"effect": "BRUITAGES  (data/sounds.json, assets/sounds/effets/)",
	"image": "IMAGES  (data/images.json)",
	"field": "DÉCORS DE TERRAIN  (data/field/*.json, assets/field/)",
}
const PRESENT_COLOR := Color(0.235, 0.878, 0.478)
const MISSING_COLOR := Color(0.816, 0.29, 0.227)
const THUMB_SIZE := Vector2(96, 54)

var _player: AudioStreamPlayer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_player = AudioStreamPlayer.new()
	_player.bus = Sound.SFX_BUS
	add_child(_player)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.043, 0.051, 0.047)
	add_child(bg)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	# Place pour le bouton « ← GALERIE » en haut à droite.
	margin.add_theme_constant_override("margin_top", 64)
	scroll.add_child(margin)
	var column := VBoxContainer.new()
	column.name = "Column"
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)

	var list := MediaCatalog.entries()
	var count := MediaCatalog.summary(list)
	var title := Label.new()
	title.text = tr("MÉDIAS DU JEU : %d / %d FOURNIS") % [count.present, count.total]
	title.theme_type_variation = &"HeaderLabel"
	title.add_theme_font_size_override("font_size", 26)
	column.add_child(title)
	var help := Label.new()
	help.theme_type_variation = &"MutedLabel"
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.text = tr("Déposer le fichier au chemin indiqué (extension libre : .ogg/.wav/.mp3 pour le son, .png/.webp/.jpg pour l'image), laisser Godot l'importer, puis rouvrir cet écran. Guide complet : docs/MEDIAS.md.")
	column.add_child(help)

	var current_kind := ""
	for entry: Dictionary in list:
		if entry.kind != current_kind:
			current_kind = entry.kind
			var section := Label.new()
			section.theme_type_variation = &"StampLabel"
			section.text = tr(KIND_TITLES.get(current_kind, current_kind))
			column.add_child(HSeparator.new())
			column.add_child(section)
		column.add_child(_build_row(entry))


func _build_row(entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var files: Array = entry.files
	var found: Array = files.filter(MediaLibrary.exists)

	var status := Label.new()
	status.custom_minimum_size = Vector2(110, 0)
	status.text = (tr("FOURNI") if found.size() == files.size() else "%d / %d" % [found.size(), files.size()]) \
			if not found.is_empty() else tr("MANQUANT")
	status.add_theme_color_override("font_color", PRESENT_COLOR if not found.is_empty() else MISSING_COLOR)
	row.add_child(status)

	var text := Label.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var names := ", ".join(files.map(func(path: String) -> String: return path.trim_prefix("res://")))
	text.text = "%s%s\n%s" % [entry.id, ("  ·  " + entry.usage) if entry.usage != "" else "", names]
	row.add_child(text)

	if entry.kind in ["image", "field"]:
		var thumb := TextureRect.new()
		thumb.custom_minimum_size = THUMB_SIZE
		thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if not found.is_empty() and str(found[0]).get_extension() != "ogv":
			thumb.texture = MediaLibrary.load_texture(found[0])
		row.add_child(thumb)
	else:
		var listen := Button.new()
		listen.text = tr("ÉCOUTER")
		listen.custom_minimum_size = Vector2(120, 44)
		listen.focus_mode = Control.FOCUS_NONE
		listen.disabled = found.is_empty()
		listen.set_meta("sound", "")
		listen.pressed.connect(_listen.bind(found))
		row.add_child(listen)
	return row


## Joue le fichier (une variante au hasard s'il y en a plusieurs) ; un second
## appui pendant la lecture l'arrête.
func _listen(files: Array) -> void:
	if _player.playing:
		_player.stop()
		return
	_player.stream = MediaLibrary.load_stream(files.pick_random())
	_player.play()
