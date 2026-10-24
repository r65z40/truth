class_name MinistryWindow
extends PanelContainer
## Cadre commun des fenêtres du terminal gouvernemental : barre de titre,
## mention de classification et bouton de fermeture (grande zone tactile).
##
## Une fenêtre concrète hérite de ce script et place son contenu dans un
## VBoxContainer enfant nommé « Layout » ; la barre de titre y est insérée en tête.
## Surcharger _on_opened() pour rafraîchir le contenu à l'ouverture.

signal closed
## Demande au bureau d'afficher une courte notification.
signal notify(text: String)

@export var window_title := "FENÊTRE"
@export var classification := "DIFFUSION RESTREINTE"


func _ready() -> void:
	theme_type_variation = &"WindowFrame"
	var layout := get_node("Layout") as VBoxContainer
	var title_bar := _build_title_bar()
	layout.add_child(title_bar)
	layout.move_child(title_bar, 0)


func open() -> void:
	show()
	_on_opened()


func close() -> void:
	if not visible:
		return
	hide()
	closed.emit()


## À surcharger : appelé à chaque ouverture.
func _on_opened() -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _build_title_bar() -> Control:
	var bar := PanelContainer.new()
	bar.name = "TitleBar"
	bar.theme_type_variation = &"TitleBar"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	bar.add_child(row)

	var title := Label.new()
	title.text = window_title
	title.theme_type_variation = &"HeaderLabel"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.clip_text = true
	row.add_child(title)

	var stamp := Label.new()
	stamp.text = classification
	stamp.theme_type_variation = &"StampLabel"
	stamp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(stamp)

	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "FERMER [X]"
	close_button.theme_type_variation = &"AlertButton"
	close_button.custom_minimum_size = Vector2(0, 44)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(close)
	row.add_child(close_button)
	return bar
