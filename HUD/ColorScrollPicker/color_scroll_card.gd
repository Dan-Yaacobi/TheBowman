class_name ColorScrollCard extends PanelContainer
## One option in the ColorScrollPicker. The whole card is clickable.

signal chosen(color: CustomVariables.ItemColor)

@export var color: CustomVariables.ItemColor = CustomVariables.ItemColor.PRECISION
@export var display_name: String = ""
@export var texture: Texture2D
@export var tint: Color = Color.WHITE
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

var _style: StyleBoxFlat
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
	resized.connect(_on_resized)
	select_button.pressed.connect(_on_select_button_pressed)
	select_button.mouse_entered.connect(_set_highlight.bind(true))
	select_button.mouse_exited.connect(_on_select_button_hover_lost)
	select_button.focus_entered.connect(_set_highlight.bind(true))
	select_button.focus_exited.connect(_on_select_button_hover_lost)
	_set_highlight(false)

func setup(level: int, power_pct: int) -> void:
	level_label.text = "Lv %d  >  %d" % [level, level + 1]
	power_label.text = "+%d%% %s item power" % [power_pct, display_name]

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
