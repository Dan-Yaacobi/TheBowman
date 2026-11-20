class_name SpiritMenu extends CanvasLayer
## The spirit's options list. Shows entries as buttons; keyboard/controller move focus
## (ui_up / ui_down), Interact or ui_accept picks, mouse hover focuses and click picks.

signal option_chosen(entry: SpiritMenuEntry)

@export var button_font_size: int = 22
## Turn-ins (what lit the spirit's "!") wear the same gold "!" and pulse, so the player knows to pick them.
@export var turn_in_color: Color = Color(1, 0.85, 0.2, 1)
@export var turn_in_prefix: String = "! "
@export var turn_in_pulse_speed: float = 4.0

@onready var panel: PanelContainer = $Control/Panel
@onready var entries_box: VBoxContainer = $Control/Panel/Entries

var _buttons: Array[Button] = []
var _turn_in_buttons: Array[Button] = []
var _time: float = 0.0

func _ready() -> void:
	panel.visible = false

func _process(delta: float) -> void:
	if _turn_in_buttons.is_empty():
		return
	_time += delta
	var brightness: float = 1.0 + 0.35 * (0.5 + 0.5 * sin(_time * turn_in_pulse_speed))
	for button: Button in _turn_in_buttons:
		button.modulate = Color(brightness, brightness, brightness)

func open(entries: Array[SpiritMenuEntry]) -> void:
	_clear()
	for entry: SpiritMenuEntry in entries:
		var button: Button = Button.new()
		button.text = (turn_in_prefix + entry.label) if entry.is_turn_in else entry.label
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", button_font_size)
		button.pressed.connect(_on_entry_button_pressed.bind(entry))
		button.mouse_entered.connect(button.grab_focus)
		entries_box.add_child(button)
		_buttons.append(button)
		if entry.is_turn_in:
			for color_name: StringName in [&"font_color", &"font_hover_color", &"font_focus_color", &"font_pressed_color"]:
				button.add_theme_color_override(color_name, turn_in_color)
			_turn_in_buttons.append(button)
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
	_turn_in_buttons.clear()

func _on_entry_button_pressed(entry: SpiritMenuEntry) -> void:
	if not panel.visible:
		return
	option_chosen.emit(entry)
