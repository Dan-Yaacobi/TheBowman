class_name ItemComparisonScreen extends Control

signal equip_pressed

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
	_sync_card_sections()

func close() -> void:
	is_open = false
	hide()
	get_tree().paused = false

# Opening: only when an item is targeted and nothing else has paused the game.
# Empty slot → equip directly, no comparison needed.
func _unhandled_input(event: InputEvent) -> void:
	if is_open or target == null or get_tree().paused:
		return
	if event.is_action_pressed("Interact"):
		get_viewport().set_input_as_handled()
		if _is_slot_empty():
			equip_pressed.emit()
		else:
			open()

func _is_slot_empty() -> bool:
	return PlayerManager.player.get_equipped_in_slot(target.data.slot) == null
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
		var new_mod: EquipmentData.StatModifier = _find_modifier(new_data, stat_name)
		var cur_mod: EquipmentData.StatModifier = _find_modifier(current_data, stat_name)
		var new_amount: float = new_mod.amount if new_mod else 0.0
		var cur_amount: float = cur_mod.amount if cur_mod else 0.0
		new_rows.append(ItemCard.StatRow.new(display, new_amount, new_mod != null, new_amount - cur_amount, true))
		current_rows.append(ItemCard.StatRow.new(display, cur_amount, cur_mod != null, 0.0, false))

	var slot_name: String = _slot_name(new_data.slot)
	new_card.show_item(new_data, slot_name, new_rows)
	if current_data:
		current_card.show_item(current_data, slot_name + "  ·  Equipped", current_rows)
	else:
		current_card.show_empty()

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

# Wait one frame for layout, then match header/ability heights so stat rows line up.
func _sync_card_sections() -> void:
	new_card.modulate.a = 0.0
	current_card.modulate.a = 0.0
	await get_tree().process_frame
	if not current_card.is_empty:
		var new_sections: Array[Control] = new_card.get_sync_sections()
		var current_sections: Array[Control] = current_card.get_sync_sections()
		for i: int in new_sections.size():
			var height: float = maxf(new_sections[i].size.y, current_sections[i].size.y)
			new_sections[i].custom_minimum_size.y = height
			current_sections[i].custom_minimum_size.y = height
	new_card.modulate.a = 1.0
	current_card.modulate.a = 1.0
