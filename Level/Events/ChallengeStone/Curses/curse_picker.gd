class_name CursePicker extends CanvasLayer

signal confirmed(curses: Array[ChallengeCurse])
signal cancelled

@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var curse_list: VBoxContainer = %CurseList
@onready var start_button: Button = %StartButton
@onready var cancel_button: Button = %CancelButton

var _offered: Array[ChallengeCurse] = []
var _boxes: Array[CheckBox] = []

func _ready() -> void:
	hide()
	start_button.pressed.connect(_on_start_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)

func open(challenge: ChallengeDef, curses: Array[ChallengeCurse]) -> void:
	title_label.text = challenge.display_name
	description_label.text = challenge.description
	_offered = curses

	for child: Node in curse_list.get_children():
		child.queue_free()
	_boxes.clear()

	for curse: ChallengeCurse in curses:
		var box: CheckBox = CheckBox.new()
		box.text = "%s: %s" % [curse.display_name, curse.description]
		box.icon = curse.icon
		curse_list.add_child(box)
		_boxes.append(box)

	show()
	start_button.grab_focus()

func _on_start_pressed() -> void:
	var selected: Array[ChallengeCurse] = []
	for i: int in _boxes.size():
		if _boxes[i].button_pressed:
			selected.append(_offered[i])
	hide()
	confirmed.emit(selected)

func _on_cancel_pressed() -> void:
	hide()
	cancelled.emit()
	
func close() -> void:
	hide()
