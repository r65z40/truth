class_name PixelIcons
extends RefCounted
## Icônes en pixels du bureau et des pièces de dossier, dessinées ici même
## (grilles de 16 x 16 caractères) avec les couleurs du thème (type PixelIcon).
## Aucune image externe : les textures sont fabriquées au premier usage puis gardées.
##
## Lettres : k encre, p papier, P papier foncé, f chemise, F bois, a rouge,
## g vert phosphore, w lampe, s peau, c étoffe, b métal, d écran ; « . » transparent.

const SIZE := 16
const THEME_PATH := "res://ui/theme/ministry_theme.tres"
const COLOR_NAMES := {
	"k": "ink", "p": "paper", "P": "paper_dark", "f": "folder", "F": "wood", "a": "alert",
	"g": "accent", "w": "lamp", "s": "skin", "c": "cloth", "b": "metal", "d": "screen",
}
## Icône de pièce selon le type de document (data/cases/*.json, champ « type »).
const DOCUMENT_ICONS := {
	"identity": "identity", "report": "report", "register": "register", "intercept": "intercept",
	"letter": "letter", "travel_log": "travel_log",
}

const GRIDS := {
	"dossiers": [
		"................",
		"................",
		".kkkkkk.........",
		".kffffkk........",
		".kfffffkkkkkkkk.",
		".kffpppppppppfk.",
		".kffpkkkkkkkpfk.",
		".kffppppppppppfk",
		".kkkkkkkkkkkkkkk",
		".kffffffffffffk.",
		".kffffffffffffk.",
		".kfffkkkkkfffFk.",
		".kffffffffffffk.",
		".kFFFFFFFFFFFFk.",
		".kkkkkkkkkkkkkk.",
		"................",
	],
	"messages": [
		"................",
		"................",
		"................",
		"kkkkkkkkkkkkkkkk",
		"kpkppppppppppkpk",
		"kppkppppppppkppk",
		"kpppkppppppkpppk",
		"kppppkkppkkppppk",
		"kpppppPkkPpppppk",
		"kppppPppppPppppk",
		"kpppPppppppPpppk",
		"kppPppppppppPppk",
		"kpPppppppppppPpk",
		"kkkkkkkkkkkkkkkk",
		"................",
		"................",
	],
	"archives": [
		"................",
		".kkkkkkkkkkkkkk.",
		".kbbbbbbbbbbbbk.",
		".kbkkkkkkkkkkbk.",
		".kbbbbbkkbbbbbk.",
		".kbbbbbbbbbbbbk.",
		".kkkkkkkkkkkkkk.",
		".kbbbbbbbbbbbbk.",
		".kbkkkkkkkkkkbk.",
		".kbbbbbkkbbbbbk.",
		".kbbbbbbbbbbbbk.",
		".kkkkkkkkkkkkkk.",
		".kbbbbbbbbbbbbk.",
		".kbbbbbkkbbbbbk.",
		".kkkkkkkkkkkkkk.",
		"................",
	],
	"personnel": [
		"................",
		"..kkkkkkkkkkkk..",
		"..kPPPPPPPPPPk..",
		"..kPPPkkkkPPPk..",
		"..kPPkssssPPPk..",
		"..kPPkssssPPPk..",
		"..kPPPkssPPPPk..",
		"..kPPcccccPPPk..",
		"..kPcccccccPPk..",
		"..kPPPPPPPPPPk..",
		"..kPkkkkkkkkPk..",
		"..kPPPPPPPPPPk..",
		"..kPkkkkkPPaPk..",
		"..kPPPPPPPaaak..",
		"..kkkkkkkkkkkk..",
		"................",
	],
	"terminal": [
		"................",
		".kkkkkkkkkkkkkk.",
		".kbbbbbbbbbbbbk.",
		".kbddddddddddbk.",
		".kbdgddddddddbk.",
		".kbddgdddddddbk.",
		".kbdgdggggdddbk.",
		".kbddddddddddbk.",
		".kbddddddddddbk.",
		".kbbbbbbbbbbbbk.",
		".kkkkkkkkkkkkkk.",
		"......kbbk......",
		"....kkkkkkkk....",
		"...kbbbbbbbbk...",
		"...kkkkkkkkkk...",
		"................",
	],
	"identity": [
		"................",
		"................",
		"kkkkkkkkkkkkkkkk",
		"kaaaaaaaaaaaaaak",
		"kppppppppppppppk",
		"kpkkkkkppppppppk",
		"kpkssskpkkkkkppk",
		"kpkssskppppppppk",
		"kpkcccckpkkkkppk",
		"kpkcccckpppppppk",
		"kpkkkkkkpkkkpppk",
		"kppppppppppppppk",
		"kppppppppppaappk",
		"kkkkkkkkkkkkkkkk",
		"................",
		"................",
	],
	"report": [
		"..kkkkkkkkkk....",
		"..kppppppppkk...",
		"..kpkkkkkppkpk..",
		"..kppppppppkkkk.",
		"..kpkkkkkkkpppk.",
		"..kppppppppppk..",
		"..kpkkkkkkkkpk..",
		"..kppppppppppk..",
		"..kpkkkkkkkkpk..",
		"..kpppppaaaapk..",
		"..kpppppappapk..",
		"..kpkkkkaaaapk..",
		"..kppppppppppk..",
		"..kkkkkkkkkkkk..",
		"................",
		"................",
	],
	"register": [
		"................",
		".kkkkkkkkkkkkkk.",
		".kFkPPPPPPPPPPk.",
		".kFkPkkkkkkkkPk.",
		".kFkPPPPPPPPPPk.",
		".kFkPkPkPkPkPPk.",
		".kFkkkkkkkkkkkk.",
		".kFkPkPkPkPkPPk.",
		".kFkkkkkkkkkkkk.",
		".kFkPkPkPkPkPPk.",
		".kFkkkkkkkkkkkk.",
		".kFkPkPkPkPkPPk.",
		".kFkPPPPPPPPPPk.",
		".kkkkkkkkkkkkkk.",
		"................",
		"................",
	],
	"intercept": [
		"................",
		"................",
		".kkkkkkkkkkkkkk.",
		".kbbbbbbbbbbbbk.",
		".kbkkkkkkkkkkbk.",
		".kbkpppppppkbbk.",
		".kbkpkkpkkpkbbk.",
		".kbkpkkpkkppkbk.",
		".kbkpppppppkbbk.",
		".kbkkkkkkkkkkbk.",
		".kbbbbbbbbbbbbk.",
		".kbbbkkkkkkbbbk.",
		".kkkkkkkkkkkkkk.",
		"................",
		"................",
		"................",
	],
	"letter": [
		"................",
		"....kkkkkkkk....",
		"....kppppppk....",
		"....kpkkkkpk....",
		"....kppppppk....",
		"kkkkkpkkkkpkkkkk",
		"kpkppppppppppkpk",
		"kppkppppppppkppk",
		"kpppkkppppkkpppk",
		"kpppppkaakpppppk",
		"kppppkpaapkppppk",
		"kpppkppppppkpppk",
		"kppkppppppppkppk",
		"kpkppppppppppkpk",
		"kkkkkkkkkkkkkkkk",
		"................",
	],
	"travel_log": [
		"................",
		"................",
		"..kkkkkkkkkkkk..",
		"..kwwwwwwwwwwk..",
		"..kwkkkkkkkkwk..",
		"..kwwwwwwwwwwk..",
		"..kkkkkkkkkkkk..",
		"..kwwwwwwwwwwk..",
		"..kwkkwkkwkkwk..",
		"..kwwwwwwwwwwk..",
		"..kwkkwkkwkkwk..",
		"..kwwwwwwwwwwk..",
		"..kwkkkkkkaawk..",
		"..kwwwwwwwwwwk..",
		"..kkkkkkkkkkkk..",
		"................",
	],
	"document": [
		"..kkkkkkkkk.....",
		"..kpppppppkk....",
		"..kpppppppkpk...",
		"..kpkkkkkpkkkk..",
		"..kpppppppppPk..",
		"..kpkkkkkkkkPk..",
		"..kpppppppppPk..",
		"..kpkkkkkkkkPk..",
		"..kpppppppppPk..",
		"..kpkkkkkkkkPk..",
		"..kpppppppppPk..",
		"..kpkkkkkppppk..",
		"..kpppppppppPk..",
		"..kkkkkkkkkkkk..",
		"................",
		"................",
	],}

static var _cache: Dictionary = {}


static func has_icon(icon_name: String) -> bool:
	return GRIDS.has(icon_name)


## Texture de l'icône, agrandie sans lissage : 16 x 16 pixels fois scale.
static func get_icon(icon_name: String, scale := 1) -> Texture2D:
	if not GRIDS.has(icon_name):
		icon_name = "document"
	var key := "%s@%d" % [icon_name, scale]
	if not _cache.has(key):
		var image := build_image(icon_name)
		if scale > 1:
			image.resize(SIZE * scale, SIZE * scale, Image.INTERPOLATE_NEAREST)
		_cache[key] = ImageTexture.create_from_image(image)
	return _cache[key]


## Icône d'une pièce de dossier d'après son type ; page générique sinon.
static func document_icon(document_type: String, scale := 1) -> Texture2D:
	return get_icon(DOCUMENT_ICONS.get(document_type, "document"), scale)


static func build_image(icon_name: String) -> Image:
	var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var palette := _palette()
	var rows: Array = GRIDS[icon_name]
	for y in mini(rows.size(), SIZE):
		var row: String = rows[y]
		for x in mini(row.length(), SIZE):
			var key := row[x]
			if palette.has(key):
				image.set_pixel(x, y, palette[key])
	return image


static func _palette() -> Dictionary:
	var theme := load(THEME_PATH) as Theme
	var palette := {}
	for key in COLOR_NAMES:
		palette[key] = theme.get_color(COLOR_NAMES[key], &"PixelIcon")
	return palette
