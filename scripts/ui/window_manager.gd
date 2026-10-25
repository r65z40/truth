class_name WindowManager
extends Control
## Zone de travail du bureau : range les fenêtres (MinistryWindow) posées comme
## enfants directs. Plusieurs fenêtres peuvent être ouvertes à la fois ; un clic
## dans une fenêtre la passe au premier plan. Sur un écran étroit (téléphone),
## chaque fenêtre occupe toute la zone de travail.
##
## Ne contient aucune règle de jeu : seulement la géométrie et l'ordre des fenêtres.

## Une fenêtre s'ouvre, se ferme, se réduit ou passe au premier plan.
signal windows_changed

## En dessous de cette largeur, les fenêtres s'ouvrent en plein écran.
const COMPACT_WIDTH := 900.0

## Vrai sur petit écran : fenêtres en plein écran.
var compact := false
## Force le mode petit écran (réglage ou essai sur ordinateur).
var force_compact := false:
	set(value):
		force_compact = value
		relayout()
var _focused: MinistryWindow
var _placed: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for window in get_windows():
		_register(window)
	resized.connect(relayout)
	relayout()


## Ajoute une fenêtre créée en cours de partie (une pièce ouverte à part).
## Elle est détruite à sa fermeture.
func add_window(window: MinistryWindow) -> void:
	window.set_meta("transient", true)
	add_child(window)
	_register(window)


## Ferme toutes les fenêtres (fin de service).
func close_all() -> void:
	for window in get_windows():
		window.close()


func _register(window: MinistryWindow) -> void:
	window.movable = true
	window.opened.connect(_on_window_opened.bind(window))
	window.restored.connect(_on_window_restored.bind(window))
	window.closed.connect(_on_window_closed.bind(window))
	window.minimized.connect(_on_window_hidden.bind(window))
	window.resized.connect(_on_window_resized.bind(window))


func _on_window_closed(window: MinistryWindow) -> void:
	if window.get_meta("transient", false):
		_placed.erase(window)
		window.queue_free()
	_on_window_hidden(window)


func get_windows() -> Array[MinistryWindow]:
	var result: Array[MinistryWindow] = []
	for child in get_children():
		if child is MinistryWindow and not child.is_queued_for_deletion():
			result.append(child)
	return result


## Fenêtre au premier plan (la dernière activée encore visible), ou null.
func get_focused() -> MinistryWindow:
	if _focused and _focused.visible:
		return _focused
	return null


## Passe une fenêtre au premier plan et grise la barre de titre des autres.
func raise_window(window: MinistryWindow) -> void:
	move_child(window, -1)
	_focused = window
	for other in get_windows():
		other.set_active(other == window)
	windows_changed.emit()


## Fenêtres ouvertes (visibles ou réduites), dans l'ordre d'ouverture.
func get_open_windows() -> Array[MinistryWindow]:
	var result: Array[MinistryWindow] = []
	for window in _placed:
		if window.is_open():
			result.append(window)
	return result


## Clic sur un bouton de la barre des tâches : ressort, active ou réduit la fenêtre.
func toggle_from_taskbar(window: MinistryWindow) -> void:
	if window.is_minimized:
		window.restore()
	elif window == get_focused():
		window.minimize()
	else:
		raise_window(window)


func _input(event: InputEvent) -> void:
	# Un clic dans une fenêtre en arrière-plan la passe devant, sans consommer le clic.
	if not (event is InputEventMouseButton and event.pressed) or not is_visible_in_tree():
		return
	var windows := get_windows()
	windows.reverse()
	for window in windows:
		if window.visible and window.get_global_rect().has_point(event.global_position):
			if window != _focused:
				raise_window(window)
			return


func _on_window_opened(window: MinistryWindow) -> void:
	# Une fenêtre déjà ouverte puis rouverte se contente de revenir devant.
	if not _placed.has(window):
		_place(window)
	_placed.erase(window)
	_placed[window] = true
	_apply_compact(window)
	raise_window(window)
	# Le contenu rafraîchi peut agrandir la fenêtre un instant : on la remet en place.
	_refit.call_deferred(window)


func _on_window_restored(window: MinistryWindow) -> void:
	_apply_compact(window)
	raise_window(window)


func _on_window_hidden(window: MinistryWindow) -> void:
	if window == _focused:
		_focused = null
		var visible_windows := get_windows().filter(func(w: MinistryWindow) -> bool: return w.visible)
		if not visible_windows.is_empty():
			raise_window(visible_windows[-1])
			return
	windows_changed.emit()


## Première ouverture : la fenêtre quitte ses ancres de scène pour une position
## libre, calculée à partir de ses marges d'origine dans la zone de travail.
func _place(window: MinistryWindow) -> void:
	var start := Vector2(window.offset_left, window.offset_top)
	var end := Vector2(window.offset_right, window.offset_bottom)
	var anchored := window.anchor_right > window.anchor_left
	var rect_size := size - start + end if anchored else window.size
	window.set_anchors_preset(Control.PRESET_TOP_LEFT)
	window.position = start if anchored else (size - rect_size) / 2.0
	window.size = rect_size
	window.clamp_to_parent()


## Un contenu plus long peut agrandir la fenêtre : elle ne dépasse jamais la zone.
func _on_window_resized(window: MinistryWindow) -> void:
	if _placed.has(window) and not Rect2(Vector2.ZERO, size).encloses(window.get_rect()):
		_refit.call_deferred(window)


func _refit(window: MinistryWindow) -> void:
	if compact or window.is_maximized:
		window.fit_to_parent()
	else:
		window.clamp_to_parent()


func _apply_compact(window: MinistryWindow) -> void:
	if compact or window.is_maximized:
		window.fit_to_parent()


## Recalcule le mode petit écran et replace les fenêtres ouvertes.
func relayout() -> void:
	compact = force_compact or size.x < COMPACT_WIDTH or OS.has_feature("mobile")
	for window in _placed:
		_refit(window)
