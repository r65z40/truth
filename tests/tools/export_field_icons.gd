extends SceneTree
## Outil hors-jeu : exporte les pictogrammes de champ (icônes ink) en PNG dans
## res://ui/icons/, pour les afficher en ligne dans les pièces (BBCode [img]).
## Lancer : godot --headless --path . -s res://tests/tools/export_field_icons.gd

const ICONS := ["f_person", "f_date", "f_id", "f_home", "f_work", "f_family", "f_warn"]
const SCALE := 2  # 16 px -> 32 px, rendu net à l'écran

func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://ui/icons")
	for name in ICONS:
		var tex := PixelIcons.get_icon(name, SCALE)
		var img := tex.get_image()
		var path := "res://ui/icons/%s.png" % name
		var err := img.save_png(path)
		print("%s -> %s (%s)" % [name, path, "ok" if err == OK else "ERREUR %d" % err])
	quit()
