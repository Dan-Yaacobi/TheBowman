class_name SpiritMenu extends CanvasLayer
## The spirit's options list. Shows entries as buttons; keyboard/controller move focus
## (ui_up / ui_down), Interact or ui_accept picks, mouse hover focuses and click picks.

signal option_chosen(entry: SpiritMenuEntry)

@export var button_font_size: int = 22

@onready var panel: PanelContainer = $Control/Panel
@onready var entries_box: VBoxContainer = $Control/Panel/Entries

var _buttons: Array[Button] = []

func _ready() -> void:
	panel.visible = false

func open(entries: Array[SpiritMenuEntry]) -> void:
	_clear()
	for entry: SpiritMenuEntry in entries:
		var button: Button = Button.new()
		button.text = entry.label
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", button_font_size)
		button.pressed.connect(_on_entry_button_pressed.bind(entry))
		button.mouse_entered.connect(button.grab_focus)
		entries_box.add_child(button)
		_buttons.append(button)
	if _buttons.is_empty():
		return
	# Wrap focus top <-> bottom.
	var first: Button = _buttons[0]
	var last: Button = _buttons[_buttons.size() - 1]
	first.focus_neighbor_top = first.get_path_to(last)
	last.focus_neighbor_bottom = last.get_path_to(first)
	panel.visible = true
	first.grab_focus()

func close() -> void:
	panel.visible = false
	_clear()

func is_open() -> bool:
	return panel.visible

## Picks the focused entry (for the Interact key, which buttons don't handle themselves).
func choose_focused() -> void:
	for button: Button in _buttons:
		if button.has_focus():
			button.pressed.emit()
			return
	# Focus was lost (e.g. clicked elsewhere): take it back instead of guessing.
	if not _buttons.is_empty():
		_buttons[0].grab_focus()

func _clear() -> void:
	for button: Button in _buttons:
		entries_box.remove_child(button)
		button.queue_free()
	_buttons.clear()

func _on_entry_button_pressed(entry: SpiritMenuEntry) -> void:
	if not panel.visible:
		return
	option_chosen.emit(entry)
