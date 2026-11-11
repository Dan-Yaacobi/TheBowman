class_name ItemComparisonScreen extends Control

signal equip_pressed

## Upper bound on frames to wait for the cards' layout to settle before syncing heights.
const MAX_LAYOUT_FRAMES: int = 6
## Arrow Damage is shown as the real hit it adds (same label as the equipment menu).
const HIT_DAMAGE_PROP: String = "arrow_damage"
const HIT_DAMAGE_LABEL: String = "Hit Damage"

@export var stat_names_dict: Dictionary[String, String] = {}

@onready var new_card: ItemCard = $CenterContainer/VBoxContainer/Cards/NewCard
@onready var current_card: ItemCard = $CenterContainer/VBoxContainer/Cards/CurrentCard
@onready var equip_button: Button = $CenterContainer/VBoxContainer/Buttons/CenterContainer/EquipButton

var target: Equipment
var is_open: bool = false

func _ready() -> void:
	hide()
	equip_button.pressed.connect(_on_equip_button_pressed)

func set_target(equipment: Equipment) -> void:
	target = equipment

func clear_target() -> void:
	if is_open:
		close()
	target = null

func open() -> void:
	if target == null:
		return
	var current_data: EquipmentData = PlayerManager.player.get_equipped_in_slot(target.data.slot)
	_populate(target.data, current_data)
	is_open = true
	show()
	get_tree().paused = true
	EventBus.equipment_inspected.emit(target.data)
	_sync_card_sections()

func close() -> void:
	is_open = false
	hide()
	get_tree().paused = false

# Opening: only when an item is targeted and nothing else has paused the game.
# Always opens, even with an empty slot (the current card shows as empty).
func _unhandled_input(event: InputEvent) -> void:
	if is_open or target == null or get_tree().paused:
		return
	if event.is_action_pressed("Interact"):
		get_viewport().set_input_as_handled()
		open()

# Closing: _input runs before PauseMenu's _unhandled_input, so Esc closes this
# screen without also opening the pause menu.
func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed("Interact") or event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _on_equip_button_pressed() -> void:
	close()
	equip_pressed.emit()

func _populate(new_data: EquipmentData, current_data: EquipmentData) -> void:
	var stat_names: Array[String] = _collect_stat_names(new_data, current_data)
	var new_rows: Array[ItemCard.StatRow] = []
	var current_rows: Array[ItemCard.StatRow] = []

	for stat_name: String in stat_names:
		var display: String = _display_name(stat_name)
		var new_has: bool = _find_modifier(new_data, stat_name) != null
		var cur_has: bool = _find_modifier(current_data, stat_name) != null
		# Every roll of the stat summed (several tiers can roll it), after each item's color level.
		var new_amount: float = _stat_total(new_data, stat_name)
		var cur_amount: float = _stat_total(current_data, stat_name)
		var suffix: String = PlayerStats.unit_suffix(stat_name)
		if stat_name == HIT_DAMAGE_PROP:
			# Shown as real damage on a full (non-perfect) draw, like the equipment menu.
			display = HIT_DAMAGE_LABEL
			new_amount = _hit_gain(new_amount, cur_amount, new_data)
			cur_amount = _hit_gain(cur_amount, cur_amount, current_data)
		new_rows.append(ItemCard.StatRow.new(display, new_amount, new_has, new_amount - cur_amount, true, suffix))
		current_rows.append(ItemCard.StatRow.new(display, cur_amount, cur_has, 0.0, false, suffix))

	var slot_name: String = _slot_name(new_data.slot)
	new_card.show_item(new_data, slot_name, new_rows)
	if current_data:
		current_card.show_item(current_data, slot_name + "  ·  Equipped", current_rows)
	else:
		current_card.show_empty()

## Full-draw hit damage this item's Arrow Damage roll adds, on top of everything else the
## player has (the currently equipped item's roll taken out first).
func _hit_gain(item_amount: float, equipped_amount: float, item: EquipmentData) -> float:
	var player: Player = PlayerManager.player
	var stat: Stat = player.stats.arrow_damage
	var without: float = stat.value_without(equipped_amount, Stat.buff_type.ADDITIVE)
	var with_item: float = stat.value_without(equipped_amount - item_amount, Stat.buff_type.ADDITIVE)
	var bow_power: float = player.color_levels.get_bow_power()
	if item and item.slot == EquipmentData.slots.BOW:
		bow_power = player.color_levels.get_power(item.color)
	return (player.main_hand.base_hit_for(with_item) - player.main_hand.base_hit_for(without)) * bow_power

func _collect_stat_names(new_data: EquipmentData, current_data: EquipmentData) -> Array[String]:
	var names: Array[String] = []
	for mod: EquipmentData.StatModifier in new_data.modifiers:
		if not names.has(mod.stat_name):
			names.append(mod.stat_name)
	if current_data:
		for mod: EquipmentData.StatModifier in current_data.modifiers:
			if not names.has(mod.stat_name):
				names.append(mod.stat_name)
	names.sort_custom(func(a: String, b: String) -> bool: return _display_name(a).naturalnocasecmp_to(_display_name(b)) < 0)
	return names

func _stat_total(data: EquipmentData, stat_name: String) -> float:
	if data == null:
		return 0.0
	var total: float = 0.0
	for mod: EquipmentData.StatModifier in data.modifiers:
		if mod.stat_name == stat_name:
			total += data.scaled_amount(mod)
	return total

func _find_modifier(data: EquipmentData, stat_name: String) -> EquipmentData.StatModifier:
	if data == null:
		return null
	for mod: EquipmentData.StatModifier in data.modifiers:
		if mod.stat_name == stat_name:
			return mod
	return null

func _display_name(stat_name: String) -> String:
	return stat_names_dict.get(stat_name, stat_name)

func _slot_name(slot: EquipmentData.slots) -> String:
	return str(EquipmentData.slots.keys()[slot]).capitalize()

# Wait for layout to settle, then match header/ability heights so stat rows line up.
# Autowrapped ability labels first measure at zero width (one word per line, very tall)
# and only get their real height a pass or two later, so one frame isn't enough.
func _sync_card_sections() -> void:
	new_card.modulate.a = 0.0
	current_card.modulate.a = 0.0
	var last_height: float = -1.0
	for i: int in MAX_LAYOUT_FRAMES:
		await get_tree().process_frame
		if not is_inside_tree():
			return
		var height_now: float = new_card.get_combined_minimum_size().y + current_card.get_combined_minimum_size().y
		if is_equal_approx(height_now, last_height):
			break
		last_height = height_now
	if not current_card.is_empty:
		var new_sections: Array[Control] = new_card.get_sync_sections()
		var current_sections: Array[Control] = current_card.get_sync_sections()
		for i: int in new_sections.size():
			var height: float = maxf(new_sections[i].size.y, current_sections[i].size.y)
			new_sections[i].custom_minimum_size.y = height
			current_sections[i].custom_minimum_size.y = height
	new_card.modulate.a = 1.0
	current_card.modulate.a = 1.0
