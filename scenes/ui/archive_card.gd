class_name ArchiveCard
extends ColorRect
## Carte d'archive affichée après la signature d'un dossier : la photo du sujet,
## une mention tamponnée (TRANSFÉRÉ / RELAXÉ / MUTÉ…), la conséquence, et parfois
## une phrase d'un proche. Transforme un indicateur en visage.
##
## Données fournies par FateRules.fate_for (logique pure, déterministe).

signal continued

var _photo := IdPhoto.new()

@onready var _photo_holder: Control = %PhotoHolder
@onready var _subject: Label = %SubjectName
@onready var _stamp: Label = %StampLabel
@onready var _line: Label = %LineLabel
@onready var _quote: Label = %QuoteLabel
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
	_photo_holder.add_child(_photo)
	_continue_button.pressed.connect(_on_continue)
	hide()


## Affiche le destin du sujet. Renvoie false si rien à montrer.
func show_fate(fate: Dictionary) -> bool:
	if fate.is_empty():
		return false
	var photo: Dictionary = fate.get("photo", {})
	_photo.photo = photo
	_photo.visible = not photo.is_empty()
	_subject.text = fate.get("subject_name", "")
	_stamp.text = fate.get("stamp", "")
	_line.text = fate.get("line", "")
	var quote: String = fate.get("quote", "")
	_quote.text = quote
	_quote.visible = quote != ""
	show()
	_continue_button.grab_focus()
	return true


func _on_continue() -> void:
	hide()
	continued.emit()
