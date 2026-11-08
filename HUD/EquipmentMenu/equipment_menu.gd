class_name EquipmentMenu extends CanvasLayer

const CHARACTER_AREA: String = "Control/CenterContainer/Window/VBox/Columns/CharacterPanel/CharacterArea/"
const TOOLTIP_GAP: float = 12.0
const ITEM_ICON_SIZE: float = 28.0
const COLOR_HIGHLIGHT: Color = Color("ffcf5a")
const COLOR_ROW_STRIPE: Color = Color(1.0, 1.0, 1.0, 0.05)
const COLOR_ROW_HIGHLIGHT: Color = Color(1.0, 0.81, 0.35, 0.12)

@export_group("Stats Text")
@export var stat_font_size: int = 22
@export var stat_group_font_size: int = 26
@export var panel_title_font_size: int = 30
## Width of the value and item-share columns, so numbers line up on the right.
@export var stat_value_width: float = 80.0
@export var stat_share_width: float = 70.0

@onready var close_button: Button = $Control/CenterContainer/Window/VBox/Footer/CloseButton
@onready var bow_slot: EquipmentSlot = get_node(CHARACTER_AREA + "BowSlot")
@onready var quiver_slot: EquipmentSlot = get_node(CHARACTER_AREA + "QuiverSlot")
@onready var ring_slot: EquipmentSlot = get_node(CHARACTER_AREA + "RingSlot")
@onready var stats_list: VBoxContainer = $Control/CenterContainer/Window/VBox/Columns/StatsPanel/VBox/Scroll/StatsList
@onready var stats_title: Label = $Control/CenterContainer/Window/VBox/Columns/StatsPanel/VBox/Header
@onready var abilities_title: Label = $Control/CenterContainer/Window/VBox/Columns/AbilitiesPanel/VBox/Header
@onready var abilities_list: VBoxContainer = $Control/CenterContainer/Window/VBox/Columns/AbilitiesPanel/VBox/Scroll/AbilitiesList
@onready var item_tooltip: ItemCard = $Control/ItemTooltip
@onready var root_control: Control = $Control
@onready var character_area: Control = get_node(CHARACTER_AREA)

var _stats: PlayerStats
var _is_open: bool = false
## Bumped on every hover so a stale tooltip placement stops after its await.
var _tooltip_request: int = 0

func _ready() -> void:
	close_button.pressed.connect(_on_close)
	stats_title.add_theme_font_size_override("font_size", panel_title_font_size)
	abilities_title.add_theme_font_size_override("font_size", panel_title_font_size)
	for entry: Array in [[bow_slot, "bow"], [quiver_slot, "arrow"], [ring_slot, "ring"]]:
		var slot: EquipmentSlot = entry[0]
		slot.mouse_entered.connect(_on_slot_mouse_entered.bind(slot, entry[1]))
		slot.mouse_exited.connect(_on_slot_mouse_exited)
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("EquipmentMenu"):
		toggle(PlayerManager.player.stats)


# --- Public API (called by PauseMenu) ---

func open(stats: PlayerStats) -> void:
	if _is_open:
		return
	_open(stats)


func close() -> void:
	if not _is_open:
		return
	_on_close()


func toggle(stats: PlayerStats) -> void:
	if _is_open:
		_on_close()
	else:
		_open(stats)


# --- Internal ---

func _open(stats: PlayerStats) -> void:
	_stats = stats
	_is_open = true
	get_tree().paused = true
	show()
	_fit_to_screen()
	item_tooltip.hide()
	bow_slot.refresh(_stats.bow, "Bow")
	quiver_slot.refresh(_stats.arrow, "Quiver")
	ring_slot.refresh(_stats.ring, "Ring")
	_build_stats()
	_build_abilities()


## The layer is scaled up (see its Scale in the inspector), so the root control covers
## the screen in unscaled units.
func _fit_to_screen() -> void:
	root_control.position = Vector2.ZERO
	root_control.size = get_viewport().get_visible_rect().size / scale


func _on_close() -> void:
	_is_open = false
	get_tree().paused = false
	item_tooltip.hide()
	hide()


func _on_slot_mouse_entered(slot: EquipmentSlot, prop: String) -> void:
	var equipment: EquipmentData = _stats.get(prop)
	if equipment == null:
		return
	var contributions: Dictionary[String, float] = _item_contributions(equipment)
	_show_tooltip(slot, equipment, contributions)
	_build_stats(equipment, contributions)


func _on_slot_mouse_exited() -> void:
	_tooltip_request += 1
	item_tooltip.hide()
	_build_stats()


# --- Item tooltip ---

## Total of each stat an item adds, after its color level. Several tiers can roll the same stat.
func _item_contributions(equipment: EquipmentData) -> Dictionary[String, float]:
	var result: Dictionary[String, float] = {}
	for mod: EquipmentData.StatModifier in equipment.modifiers:
		result[mod.stat_name] = result.get(mod.stat_name, 0.0) + equipment.scaled_amount(mod)
	return result


func _show_tooltip(slot: EquipmentSlot, equipment: EquipmentData, contributions: Dictionary[String, float]) -> void:
	var rows: Array[ItemCard.StatRow] = []
	for stat_name: String in contributions:
		rows.append(ItemCard.StatRow.new(_get_stat_display_name(stat_name), contributions[stat_name], true, 0.0, false, PlayerStats.unit_suffix(stat_name)))
	var slot_name: String = str(EquipmentData.slots.keys()[equipment.slot]).capitalize()
	item_tooltip.show_item(equipment, slot_name, rows)
	item_tooltip.show()
	_place_tooltip(slot)


## Kept over the character panel so the stats summary stays visible: side slots open toward
## the character, the bottom slot opens upward. Clamped to the screen.
## Wrapped labels measure one word per line on the first layout pass, so the card is hidden
## until its height settles (same approach as ItemComparisonScreen).
func _place_tooltip(slot: EquipmentSlot) -> void:
	_tooltip_request += 1
	var request: int = _tooltip_request
	item_tooltip.modulate.a = 0.0
	for i: int in 3:
		item_tooltip.reset_size()
		await get_tree().process_frame
		if not is_inside_tree() or request != _tooltip_request or not item_tooltip.visible:
			return
	item_tooltip.reset_size()
	item_tooltip.modulate.a = 1.0
	var screen: Vector2 = root_control.size
	var slot_rect: Rect2 = slot.get_global_rect()
	var area_rect: Rect2 = character_area.get_global_rect()
	var tip_size: Vector2 = item_tooltip.size
	var pos: Vector2
	var offset_x: float = slot_rect.get_center().x - area_rect.get_center().x
	if absf(offset_x) < slot_rect.size.x * 0.5:
		pos = Vector2(slot_rect.get_center().x - tip_size.x * 0.5, slot_rect.position.y - TOOLTIP_GAP - tip_size.y)
	elif offset_x > 0.0:
		pos = Vector2(slot_rect.position.x - TOOLTIP_GAP - tip_size.x, slot_rect.position.y)
	else:
		pos = Vector2(slot_rect.end.x + TOOLTIP_GAP, slot_rect.position.y)
	pos.x = clampf(pos.x, 0.0, maxf(screen.x - tip_size.x, 0.0))
	pos.y = clampf(pos.y, 0.0, maxf(screen.y - tip_size.y, 0.0))
	item_tooltip.global_position = pos


# --- Stats summary ---

## Rebuilds the stat list. With a hovered item, the stats it adds are highlighted with its share.
func _build_stats(hovered: EquipmentData = null, contributions: Dictionary[String, float] = {}) -> void:
	_clear(stats_list)
	var current_group: String = ""
	var row_index: int = 0
	for entry: Array in PlayerStats.DISPLAY_STATS:
		var group: String = entry[0]
		var display: String = entry[1]
		var prop: String = entry[2]
		var value: Variant = _stats.get(prop)
		if value == null:
			continue
		var total: float = (value as Stat).value() if value is Stat else float(value)
		if PlayerStats.HIDE_WHEN_ZERO_GROUPS.has(group) and roundi(total) == 0 and not contributions.has(prop):
			continue

		if group != current_group:
			current_group = group
			row_index = 0
			_add_group_header(group)

		var highlighted: bool = contributions.has(prop)
		var row_color: Color = COLOR_ROW_HIGHLIGHT if highlighted else (COLOR_ROW_STRIPE if row_index % 2 == 0 else Color.TRANSPARENT)
		var row: HBoxContainer = _make_stat_row(row_color)
		row_index += 1

		var name_label: Label = _make_stat_label(display)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if highlighted:
			name_label.add_theme_color_override("font_color", COLOR_HIGHLIGHT)
		row.add_child(name_label)

		var value_label: Label = _make_stat_label(_format_stat_total(prop, value, total))
		value_label.custom_minimum_size.x = stat_value_width
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if value is Stat:
			var stat: Stat = value
			if not is_equal_approx(stat.value(), stat.base_value):
				value_label.add_theme_color_override("font_color", ItemCard.COLOR_UPGRADE if stat.value() > stat.base_value else ItemCard.COLOR_DOWNGRADE)
		row.add_child(value_label)

		var share_label: Label = _make_stat_label("")
		share_label.custom_minimum_size.x = stat_share_width
		share_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if highlighted:
			var share: float = contributions[prop]
			share_label.text = ("+" if share >= 0.0 else "") + _format_float(share) + PlayerStats.unit_suffix(prop)
			share_label.add_theme_color_override("font_color", CustomVariables.item_color_tint(hovered.color))
		row.add_child(share_label)


## A row is a tinted panel holding name | value | item share.
func _make_stat_row(color: Color) -> HBoxContainer:
	var panel: PanelContainer = PanelContainer.new()
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(3)
	box.content_margin_left = 6.0
	box.content_margin_right = 6.0
	box.content_margin_top = 1.0
	box.content_margin_bottom = 1.0
	panel.add_theme_stylebox_override("panel", box)
	stats_list.add_child(panel)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	return row


func _add_group_header(group: String) -> void:
	var header: Label = _make_label(group)
	header.theme_type_variation = &"HeaderLabel"
	header.add_theme_font_size_override("font_size", stat_group_font_size)
	if stats_list.get_child_count() > 0:
		# Breathing room above every group but the first.
		var spacer: Control = Control.new()
		spacer.custom_minimum_size.y = 8.0
		stats_list.add_child(spacer)
	stats_list.add_child(header)


func _make_stat_label(text: String) -> Label:
	var label: Label = _make_label(text)
	label.add_theme_font_size_override("font_size", stat_font_size)
	return label


func _get_stat_display_name(prop: String) -> String:
	for entry: Array in PlayerStats.DISPLAY_STATS:
		if entry[2] == prop:
			return entry[1]
	return prop.capitalize()


## Total in the stat's display units (percent of base for percent stats).
func _format_stat_total(prop: String, value: Variant, total: float) -> String:
	if value is Stat:
		return _format_float(PlayerStats.display_total(prop, value)) + PlayerStats.unit_suffix(prop)
	return _format_float(total)


func _format_float(val: float) -> String:
	return str(roundi(val))


# --- Abilities ---

## Two sections: abilities that come from equipped items (grouped per item), and native ones
## (milestones, altar, everything else the player has registered).
func _build_abilities() -> void:
	_clear(abilities_list)
	var items: Array[EquipmentData] = []
	for item: EquipmentData in [_stats.bow, _stats.arrow, _stats.ring]:
		if item != null:
			items.append(item)

	var from_items: Array[PlayerAbility] = []
	_add_section_header("Equipment")
	for item: EquipmentData in items:
		var item_abilities: Array[PlayerAbility] = _get_item_abilities(item)
		from_items.append_array(item_abilities)
		if item_abilities.is_empty():
			continue
		abilities_list.add_child(_make_item_header(item))
		for ability: PlayerAbility in item_abilities:
			abilities_list.add_child(_make_ability_label(ability))
	if from_items.is_empty():
		abilities_list.add_child(_make_dim_label("None"))

	_add_section_header("Native")
	var native: Array[PlayerAbility] = _get_native_abilities(from_items)
	for ability: PlayerAbility in native:
		abilities_list.add_child(_make_ability_label(ability))
	if native.is_empty():
		abilities_list.add_child(_make_dim_label("None"))


func _get_item_abilities(item: EquipmentData) -> Array[PlayerAbility]:
	var result: Array[PlayerAbility] = []
	if item.ability:
		result.append(item.ability)
	for bonus: MinorAbility in item.bonus_abilities:
		if bonus:
			result.append(bonus)
	return result


func _get_native_abilities(exclude: Array[PlayerAbility]) -> Array[PlayerAbility]:
	var result: Array[PlayerAbility] = []
	var lists: Array[Array] = [
		_stats.passive_abilities, _stats.shooting_abilities, _stats.jump_abilities,
		_stats.dash_abilities, _stats.release_abilities, _stats.draw_abilities,
		_stats.before_hit_abilities, _stats.after_hit_abilities, _stats.sword_abilities,
	]
	for list: Array in lists:
		for ability: PlayerAbility in list:
			if ability and not exclude.has(ability) and not result.has(ability):
				result.append(ability)
	# Abilities without a tooltip are core mechanics (crit roll/reset), not something to list.
	return result.filter(func(ability: PlayerAbility) -> bool: return not ability.get_tooltip().is_empty())


func _add_section_header(text: String) -> void:
	var header: Label = _make_label(text)
	header.theme_type_variation = &"HeaderLabel"
	abilities_list.add_child(header)


func _make_item_header(item: EquipmentData) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	var icon: TextureRect = TextureRect.new()
	icon.texture = item.texture
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.custom_minimum_size = Vector2(ITEM_ICON_SIZE, ITEM_ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var name_label: Label = _make_label(item.display_name)
	name_label.add_theme_color_override("font_color", CustomVariables.rarity_color(item.rarity))
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(name_label)
	return row


func _make_ability_label(ability: PlayerAbility) -> Label:
	var text: String = ability.get_tooltip()
	if text.is_empty():
		# Abilities without a tooltip still show up, named after their script.
		text = ability.get_script().resource_path.get_file().get_basename().capitalize()
	var line: Label = _make_label(text)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.add_theme_color_override("font_color", ability.get_tooltip_color())
	return line


# --- Helpers ---

func _make_label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	return label


func _make_dim_label(text: String) -> Label:
	var label: Label = _make_label(text)
	label.theme_type_variation = &"DimLabel"
	return label


func _clear(container: Node) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()
