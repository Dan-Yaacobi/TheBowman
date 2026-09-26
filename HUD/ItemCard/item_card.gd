class_name ItemCard extends PanelContainer

class StatRow:
	var display_name: String
	var amount: float
	var present: bool
	var delta: float
	var show_delta: bool

	func _init(_display_name: String, _amount: float, _present: bool, _delta: float, _show_delta: bool) -> void:
		display_name = _display_name
		amount = _amount
		present = _present
		delta = _delta
		show_delta = _show_delta

const COLOR_NEUTRAL: Color = Color(0.95, 0.88, 0.75)
const COLOR_UPGRADE: Color = Color(0.4, 0.9, 0.3)
const COLOR_DOWNGRADE: Color = Color(0.9, 0.35, 0.2)
const COLOR_MISSING: Color = Color(0.5, 0.47, 0.42)
const COLOR_SECTION_HEADER: Color = Color(0.75, 0.65, 0.5)
const NAME_FONT_SIZE: int = 19
const TAG_FONT_SIZE: int = 13
const SECTION_FONT_SIZE: int = 13
const LABEL_FONT_SIZE: int = 16
const ABILITY_FONT_SIZE: int = 16

@onready var content: VBoxContainer = $MarginContainer/Content
@onready var empty_label: Label = $MarginContainer/Content/EmptyLabel
@onready var header: HBoxContainer = $MarginContainer/Content/Header
@onready var icon: TextureRect = $MarginContainer/Content/Header/Icon
@onready var name_label: Label = $MarginContainer/Content/Header/VBoxContainer/NameLabel
@onready var tag_label: Label = $MarginContainer/Content/Header/VBoxContainer/TagLabel
@onready var abilities_header: Label = $MarginContainer/Content/AbilitiesHeader
@onready var abilities: VBoxContainer = $MarginContainer/Content/Abilities
@onready var stats_header: Label = $MarginContainer/Content/StatHeader
@onready var stats: GridContainer = $MarginContainer/Content/Stats

var is_empty: bool = false

func _ready() -> void:
	_style_label(name_label, NAME_FONT_SIZE, COLOR_NEUTRAL)
	_style_label(tag_label, TAG_FONT_SIZE, COLOR_SECTION_HEADER)
	_style_label(abilities_header, SECTION_FONT_SIZE, COLOR_SECTION_HEADER)
	_style_label(stats_header, SECTION_FONT_SIZE, COLOR_SECTION_HEADER)
	_style_label(empty_label, NAME_FONT_SIZE, COLOR_MISSING)
	stats.columns = 3

func show_item(data: EquipmentData, tag: String, rows: Array[StatRow]) -> void:
	_reset()
	is_empty = false
	content.show()
	empty_label.hide()

	icon.texture = data.texture
	name_label.text = data.display_name
	name_label.add_theme_color_override("font_color", CustomVariables.rarity_color(data.rarity))
	tag_label.text = tag

	if data.ability:
		_add_ability(data.ability)
	for bonus: MinorAbility in data.bonus_abilities:
		if bonus:
			_add_ability(bonus)

	for row: StatRow in rows:
		_add_stat_row(row)

func show_empty() -> void:
	_reset()
	is_empty = true
	content.hide()
	empty_label.show()

## Sections whose heights get matched between the two cards so stat rows line up.
func get_sync_sections() -> Array[Control]:
	return [header, abilities]

func _reset() -> void:
	for child: Node in abilities.get_children():
		abilities.remove_child(child)
		child.queue_free()
	for child: Node in stats.get_children():
		stats.remove_child(child)
		child.queue_free()
	header.custom_minimum_size.y = 0.0
	abilities.custom_minimum_size.y = 0.0

func _add_ability(ability: PlayerAbility) -> void:
	var label: Label = _make_label(ability.get_tooltip(), ability.get_tooltip_color(), ABILITY_FONT_SIZE)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	abilities.add_child(label)

func _add_stat_row(row: StatRow) -> void:
	var name_cell: Label = _make_label(row.display_name, COLOR_NEUTRAL, LABEL_FONT_SIZE)
	name_cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var value_color: Color = COLOR_NEUTRAL if row.present else COLOR_MISSING
	var value_text: String = _format(row.amount) if row.present else "0"
	var value_cell: Label = _make_label(value_text, value_color, LABEL_FONT_SIZE)
	value_cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	var delta_text: String = ""
	var delta_color: Color = COLOR_NEUTRAL
	if row.show_delta and not is_zero_approx(row.delta):
		delta_text = ("+" if row.delta > 0.0 else "") + _format(row.delta)
		delta_color = COLOR_UPGRADE if row.delta > 0.0 else COLOR_DOWNGRADE
	var delta_cell: Label = _make_label(delta_text, delta_color, LABEL_FONT_SIZE)
	delta_cell.custom_minimum_size.x = 48.0
	delta_cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	stats.add_child(name_cell)
	stats.add_child(value_cell)
	stats.add_child(delta_cell)

func _make_label(text: String, color: Color, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	_style_label(label, font_size, color)
	return label

func _style_label(label: Label, font_size: int, color: Color) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))

func _format(amount: float) -> String:
	return String.num(snappedf(amount, 0.01))
