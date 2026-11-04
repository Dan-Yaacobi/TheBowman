class_name ColorScrollCard extends PanelContainer
## One option in the ColorScrollPicker. The whole card is clickable.

signal chosen(color: CustomVariables.ItemColor)

@export var color: CustomVariables.ItemColor = CustomVariables.ItemColor.PRECISION
@export var display_name: String = ""
@export var texture: Texture2D
@export var tint: Color = Color.WHITE
## Fallback only: the picker fills the bonus line from ColorLevels so it shows the real numbers.
@export var bonus_text: String = ""

@export_group("Look")
@export var background: Color = Color(0.13, 0.09, 0.07, 0.95)
@export var background_hover: Color = Color(0.2, 0.14, 0.1, 0.95)
@export var hover_scale: float = 1.05
@export var hover_duration: float = 0.08

@onready var icon: TextureRect = $Margin/VBox/Icon
@onready var name_label: Label = $Margin/VBox/NameLabel
@onready var level_label: Label = $Margin/VBox/LevelLabel
@onready var power_label: Label = $Margin/VBox/PowerLabel
@onready var bonus_label: Label = $Margin/VBox/BonusLabel
@onready var select_button: Button = $SelectButton

const ITEM_ICON_SIZE: float = 28.0
const NO_ITEMS_COLOR: Color = Color(0.6, 0.57, 0.52)

var _style: StyleBoxFlat
## Equipped items of this color, built under the bonus line each time the picker opens.
var _items_box: VBoxContainer
var _tween: Tween

func _ready() -> void:
	_style = StyleBoxFlat.new()
	_style.set_border_width_all(3)
	_style.set_corner_radius_all(4)
	add_theme_stylebox_override("panel", _style)
	icon.texture = texture
	name_label.text = display_name
	name_label.add_theme_color_override("font_color", tint)
	bonus_label.text = bonus_text
	_items_box = VBoxContainer.new()
	_items_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_items_box.add_theme_constant_override("separation", 2)
	bonus_label.get_parent().add_child(_items_box)
	resized.connect(_on_resized)
	select_button.pressed.connect(_on_select_button_pressed)
	select_button.mouse_entered.connect(_set_highlight.bind(true))
	select_button.mouse_exited.connect(_on_select_button_hover_lost)
	select_button.focus_entered.connect(_set_highlight.bind(true))
	select_button.focus_exited.connect(_on_select_button_hover_lost)
	_set_highlight(false)

func setup(level: int, power_pct: int, bonus: String, items: Array[EquipmentData]) -> void:
	level_label.text = "Lv %d  >  %d" % [level, level + 1]
	power_label.text = "+%d%% %s item power" % [power_pct, display_name]
	if bonus != "":
		bonus_label.text = bonus
	_show_items(items)

## Lists the equipped items this scroll would make stronger (icon + name in rarity color).
func _show_items(items: Array[EquipmentData]) -> void:
	for child: Node in _items_box.get_children():
		_items_box.remove_child(child)
		child.queue_free()
	var header: Label = Label.new()
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", NO_ITEMS_COLOR)
	header.text = "Your %s items:" % display_name if not items.is_empty() else "No %s items equipped" % display_name
	_items_box.add_child(header)
	for item: EquipmentData in items:
		var row: HBoxContainer = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var item_icon: TextureRect = TextureRect.new()
		item_icon.texture = item.texture
		item_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		item_icon.custom_minimum_size = Vector2(ITEM_ICON_SIZE, ITEM_ICON_SIZE)
		item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var item_name: Label = Label.new()
		item_name.text = item.display_name
		item_name.add_theme_font_size_override("font_size", 16)
		item_name.add_theme_color_override("font_color", CustomVariables.rarity_color(item.rarity))
		row.add_child(item_icon)
		row.add_child(item_name)
		_items_box.add_child(row)

func set_selectable(selectable: bool) -> void:
	select_button.disabled = not selectable

func focus() -> void:
	select_button.grab_focus()

func _set_highlight(on: bool) -> void:
	_style.bg_color = background_hover if on else background
	_style.border_color = tint if on else tint.darkened(0.45)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2.ONE * (hover_scale if on else 1.0), hover_duration)

func _on_select_button_hover_lost() -> void:
	_set_highlight(select_button.has_focus() or select_button.is_hovered())

func _on_select_button_pressed() -> void:
	chosen.emit(color)

func _on_resized() -> void:
	pivot_offset = size / 2.0
