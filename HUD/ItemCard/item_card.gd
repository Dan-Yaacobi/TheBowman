class_name ItemCard extends PanelContainer

class StatRow:
	var display_name: String
	var amount: float
	var present: bool
	var delta: float
	var show_delta: bool
	var suffix: String
	## Digits after the point (0 = whole numbers).
	var decimals: int = 0
	## For stats where less is better (draw time): a negative delta shows as an upgrade.
	var lower_is_better: bool = false

	func _init(_display_name: String, _amount: float, _present: bool, _delta: float, _show_delta: bool, _suffix: String = "") -> void:
		display_name = _display_name
		amount = _amount
		present = _present
		delta = _delta
		show_delta = _show_delta
		suffix = _suffix

const COLOR_NEUTRAL: Color = Color(0.95, 0.88, 0.75)
const COLOR_UPGRADE: Color = Color(0.4, 0.9, 0.3)
const COLOR_DOWNGRADE: Color = Color(0.9, 0.35, 0.2)
const COLOR_MISSING: Color = Color(0.5, 0.47, 0.42)
const COLOR_SECTION_HEADER: Color = Color(0.75, 0.65, 0.5)
const NAME_FONT_SIZE: int = 19
const TAG_FONT_SIZE: int = 13
const SECTION_FONT_SIZE: int = 13
const LABEL_FONT_SIZE: int = 16
const MAIN_ABILITY_FONT_SIZE: int = 18
const BONUS_ABILITY_FONT_SIZE: int = 14
const BONUS_HEADER_TEXT: String = "BONUS"

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
	tag_label.text = tag + "  ·  " + data.color_label()
	tag_label.add_theme_color_override("font_color", CustomVariables.item_color_tint(data.color))

	if data.ability:
		_add_main_ability(data.ability)
	var added_bonus_header: bool = false
	for bonus: MinorAbility in data.bonus_abilities:
		if not bonus:
			continue
		if not added_bonus_header:
			added_bonus_header = true
			abilities.add_child(_make_label(BONUS_HEADER_TEXT, COLOR_SECTION_HEADER, SECTION_FONT_SIZE))
		_add_bonus_ability(bonus)

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

## The item's defining ability: larger text in a frame tinted by the ability's color.
func _add_main_ability(ability: PlayerAbility) -> void:
	var tint: Color = ability.get_tooltip_color()
	var frame: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(tint.r, tint.g, tint.b, 0.12)
	style.border_color = Color(tint.r, tint.g, tint.b, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(5.0)
	frame.add_theme_stylebox_override("panel", style)
	var label: Label = _make_label(ability.get_tooltip(), tint, MAIN_ABILITY_FONT_SIZE)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	frame.add_child(label)
	abilities.add_child(frame)

## Rolled minor abilities: smaller, listed under the BONUS label.
func _add_bonus_ability(ability: PlayerAbility) -> void:
	var label: Label = _make_label("+ " + ability.get_tooltip(), ability.get_tooltip_color(), BONUS_ABILITY_FONT_SIZE)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	abilities.add_child(label)

func _add_stat_row(row: StatRow) -> void:
	var name_cell: Label = _make_label(row.display_name, COLOR_NEUTRAL, LABEL_FONT_SIZE)
	name_cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var value_color: Color = COLOR_NEUTRAL if row.present else COLOR_MISSING
	var value_text: String = _format(row.amount, row.decimals) + row.suffix if row.present else "0"
	var value_cell: Label = _make_label(value_text, value_color, LABEL_FONT_SIZE)
	value_cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	var delta_text: String = ""
	var delta_color: Color = COLOR_NEUTRAL
	if row.show_delta and _format(row.delta, row.decimals) != _format(0.0, row.decimals):
		delta_text = ("+" if row.delta > 0.0 else "") + _format(row.delta, row.decimals) + row.suffix
		var better: bool = (row.delta < 0.0) if row.lower_is_better else (row.delta > 0.0)
		delta_color = COLOR_UPGRADE if better else COLOR_DOWNGRADE
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

func _format(amount: float, decimals: int = 0) -> String:
	if decimals <= 0:
		return str(roundi(amount))
	return ("%." + str(decimals) + "f") % amount

## A bow's draw time row (seconds, lower is better). delta < 0 = this bow draws faster.
static func draw_time_row(draw_time: float, delta: float, show_delta: bool) -> StatRow:
	var row: StatRow = StatRow.new("Draw Time", draw_time, true, delta, show_delta, "s")
	row.decimals = 2
	row.lower_is_better = true
	return row
