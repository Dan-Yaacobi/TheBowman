class_name EquipmentInteractionUI extends Control

const STAT_LABEL = preload("uid://d3g6yk0cua2ov")

signal equip_new_item
signal destory_new_item

@onready var equip_button: Button = $PanelContainer/VBoxContainer/Buttons/EquipButton
@onready var delete_button: Button = $PanelContainer/VBoxContainer/Buttons/DeleteButton
@onready var new_item: VBoxContainer = $PanelContainer/VBoxContainer/HBoxContainer/NewItem

@export var stat_names_dict: Dictionary[String, String] = {}

const COLOR_NEUTRAL := Color(0.95, 0.88, 0.75)
const COLOR_UPGRADE := Color(0.4, 0.9, 0.3)
const COLOR_DOWNGRADE := Color(0.9, 0.35, 0.2)
const COLOR_ABILITY := Color(0.95, 0.75, 0.2)
const COLOR_SEPARATOR := Color(0.25, 0.12, 0.04, 0.8)
const NAME_FONT_SIZE := 19
const LABEL_FONT_SIZE := 16
const ABILITY_FONT_SIZE := 16
const BUTTON_FONT_SIZE := 15

func _ready() -> void:
	new_item.add_theme_constant_override("separation", 6)
	_apply_button_style(equip_button, Color(0.35, 0.2, 0.08), Color(0.5, 0.3, 0.12))
	_apply_button_style(delete_button, Color(0.4, 0.15, 0.05), Color(0.55, 0.22, 0.08))

func _apply_button_style(button: Button, normal_color: Color, hover_color: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = normal_color
	normal.border_width_left = 2
	normal.border_width_right = 2
	normal.border_width_top = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(0.12, 0.06, 0.02, 1.0)
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_left = 4
	normal.corner_radius_bottom_right = 4
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6

	var hover := normal.duplicate()
	hover.bg_color = hover_color

	var pressed := normal.duplicate()
	pressed.bg_color = normal_color.darkened(0.25)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", normal.duplicate())
	button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	button.add_theme_color_override("font_color", COLOR_NEUTRAL)
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.8))
	button.add_theme_color_override("font_pressed_color", Color(0.7, 0.6, 0.4))

func _make_label(_name: String, _amount: float = NAN) -> StatLabel:
	var label: StatLabel = STAT_LABEL.instantiate()
	label.set_label(_name, _amount)
	label.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	label.add_theme_color_override("font_color", COLOR_NEUTRAL)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	return label

func _make_separator() -> HSeparator:
	var sep := HSeparator.new()
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_SEPARATOR
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	sep.add_theme_stylebox_override("separator", style)
	return sep

func set_items(new_equip: Equipment) -> void:
	for child in new_item.get_children():
		child.queue_free()

	var current_equip = PlayerManager.player.get_equipped_in_slot(new_equip.data.slot)

	var new_name_label = _make_label(new_equip.data.display_name)
	new_name_label.set_color(CustomVariables.rarity_color(new_equip.data.rarity))
	new_name_label.add_theme_font_size_override("font_size", NAME_FONT_SIZE)
	new_item.add_child(new_name_label)
	new_item.add_child(_make_separator())

	var all_stats: Array = []
	for mod in new_equip.data.modifiers:
		if not all_stats.has(mod.stat_name):
			all_stats.append(mod.stat_name)
	if current_equip:
		for mod in current_equip.modifiers:
			if not all_stats.has(mod.stat_name):
				all_stats.append(mod.stat_name)

	for stat_name in all_stats:
		var new_mod = new_equip.data.modifiers.filter(func(m): return m.stat_name == stat_name)
		var cur_mod = current_equip.modifiers.filter(func(m): return m.stat_name == stat_name) if current_equip else []
		var new_amount: float = new_mod[0].amount if new_mod.size() > 0 else 0.0
		var cur_amount: float = cur_mod[0].amount if cur_mod.size() > 0 else 0.0
		var delta = new_amount - cur_amount
		var display_name = stat_names_dict.get(stat_name, stat_name)
		var label: StatLabel
		if current_equip == null:
			label = _make_label(display_name, new_amount)
		else:
			var sign_str := "+" if delta >= 0 else ""
			var delta_str := sign_str + ("%.2f" % delta).trim_suffix("0").trim_suffix(".")
			label = _make_label(display_name + ":  " + delta_str)
		if delta > 0:
			label.set_color(COLOR_UPGRADE)
		elif delta < 0:
			label.set_color(COLOR_DOWNGRADE)
		else:
			label.set_color(COLOR_NEUTRAL)
		new_item.add_child(_wrap_in_panel(label))

	if new_equip.data.ability:
		new_item.add_child(_make_separator())
		var ability_label = _make_label(new_equip.data.ability.get_tooltip())
		ability_label.set_color(COLOR_ABILITY)
		ability_label.add_theme_font_size_override("font_size", ABILITY_FONT_SIZE)
		new_item.add_child(ability_label)
		
func _wrap_in_panel(label: StatLabel) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.25)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(label)
	return panel
func _on_equip_button_pressed() -> void:
	equip_new_item.emit()

func _on_delete_button_pressed() -> void:
	destory_new_item.emit()
