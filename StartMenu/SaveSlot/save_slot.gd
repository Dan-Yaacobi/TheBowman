class_name SaveSlotCard extends Control
## One save slot on the start menu: a summary of the save, read straight from disk,
## plus an Erase button when the slot has something in it.

signal chosen(card: SaveSlotCard)
signal erase_requested(card: SaveSlotCard)

const MONTHS: Array[String] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
const FOCUS_LIFT: float = 12.0
const FOCUS_TIME: float = 0.14
const UNFOCUSED_TINT: Color = Color(0.8, 0.8, 0.85)

@export var slot: int = 0

@onready var body: Control = $Body
@onready var glow: Panel = $Body/Glow
@onready var slot_label: Label = %SlotLabel
@onready var stats: VBoxContainer = %Stats
@onready var empty_info: VBoxContainer = %EmptyInfo
@onready var date_label: Label = %DateLabel
@onready var select_button: Button = $Body/SelectButton
@onready var erase_button: Button = $EraseButton

var is_empty: bool = true
var _focus_tween: Tween

func _ready() -> void:
	select_button.pressed.connect(_on_select_button_pressed)
	erase_button.pressed.connect(_on_erase_button_pressed)
	select_button.focus_entered.connect(_set_highlighted.bind(true))
	select_button.focus_exited.connect(_set_highlighted.bind(false))
	select_button.mouse_entered.connect(select_button.grab_focus)
	erase_button.mouse_entered.connect(erase_button.grab_focus)
	glow.modulate.a = 0.0
	body.modulate = UNFOCUSED_TINT
	refresh()

## Re-reads the slot from disk.
func refresh() -> void:
	slot_label.text = "Slot %d" % (slot + 1)
	for child: Node in stats.get_children():
		child.queue_free()
	var info: Dictionary = SaveService.get_slot_info(slot)
	is_empty = info.is_empty()
	stats.visible = not is_empty
	empty_info.visible = is_empty
	erase_button.visible = not is_empty
	erase_button.focus_mode = Control.FOCUS_NONE if is_empty else Control.FOCUS_ALL
	date_label.text = ""
	if is_empty:
		return
	if info.get("corrupt", false):
		_add_row("Unreadable save", "")
		return

	var sections: Dictionary = info.get("sections", {})
	var meta: Dictionary = sections.get("meta", {})
	var resources: Dictionary = sections.get("resources", {})
	var upgrades: int = 0
	var levels: Dictionary = meta.get("levels", {})
	for key: String in levels:
		upgrades += int(levels[key])
	_add_row("Time played", _format_playtime(float(info.get("playtime", 0.0))))
	_add_row("Upgrades", str(upgrades))
	_add_row("Deaths", str(int(meta.get("run_deaths", 0))))
	_add_row("Gold", str(int(resources.get("COIN", 0))))
	date_label.text = _format_date(int(info.get("saved_at", 0)))

func get_focus_target() -> Control:
	return select_button

func _add_row(title: String, value: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	var title_label: Label = Label.new()
	title_label.text = title
	title_label.theme_type_variation = &"DimLabel"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override(&"font_size", 32)
	var value_label: Label = Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override(&"font_size", 32)
	row.add_child(title_label)
	row.add_child(value_label)
	stats.add_child(row)

func _format_playtime(seconds: float) -> String:
	if seconds <= 0.0:
		return "-"
	var minutes: int = int(seconds / 60.0)
	if minutes < 60:
		return "%dm" % maxi(minutes, 1)
	return "%dh %02dm" % [minutes / 60, minutes % 60]

func _format_date(unix_time: int) -> String:
	if unix_time <= 0:
		return ""
	var bias_minutes: int = int(Time.get_time_zone_from_system().get("bias", 0))
	var date: Dictionary = Time.get_datetime_dict_from_unix_time(unix_time + bias_minutes * 60)
	return "%s %d, %d  %02d:%02d" % [MONTHS[int(date.month) - 1], date.day, date.year, date.hour, date.minute]

func _set_highlighted(on: bool) -> void:
	if _focus_tween:
		_focus_tween.kill()
	_focus_tween = create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_focus_tween.tween_property(body, "position:y", -FOCUS_LIFT if on else 0.0, FOCUS_TIME)
	_focus_tween.tween_property(glow, "modulate:a", 1.0 if on else 0.0, FOCUS_TIME)
	_focus_tween.tween_property(body, "modulate", Color.WHITE if on else UNFOCUSED_TINT, FOCUS_TIME)

func _on_select_button_pressed() -> void:
	chosen.emit(self)

func _on_erase_button_pressed() -> void:
	erase_requested.emit(self)
