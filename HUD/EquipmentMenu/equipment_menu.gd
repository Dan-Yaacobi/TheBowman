class_name EquipmentMenu extends CanvasLayer

@onready var close_button: Button = $Control/CloseButton
@onready var bow_slot: EquipmentSlot = $Control/ColorRect/HBoxContainer/Left/Slots/BowSlot
@onready var ring_slot: EquipmentSlot = $Control/ColorRect/HBoxContainer/Left/Slots/RingSlot
@onready var quiver_slot: EquipmentSlot = $Control/ColorRect/HBoxContainer/Left/Slots/QuiverSlot
@onready var stats_panel: VBoxContainer = $Control/ColorRect/HBoxContainer/Right/StatsPanel
@onready var abilities_panel: VBoxContainer = $Control/ColorRect/HBoxContainer/Right/AbilitiesPanel

var _stats: PlayerStats
var _hovered_slot: String = ""
var _is_open: bool = false

func _ready() -> void:
	close_button.pressed.connect(_on_close)
	ring_slot.pressed.connect(_on_unequip.bind("ring"))
	bow_slot.mouse_entered.connect(_on_hover.bind("bow"))
	quiver_slot.mouse_entered.connect(_on_hover.bind("arrow"))
	ring_slot.mouse_entered.connect(_on_hover.bind("ring"))
	bow_slot.mouse_exited.connect(_on_unhover)
	quiver_slot.mouse_exited.connect(_on_unhover)
	ring_slot.mouse_exited.connect(_on_unhover)
	hide()

func toggle(stats: PlayerStats) -> void:
	if _is_open:
		_on_close()
	else:
		_open(stats)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("EquipmentMenu"):
		toggle(PlayerManager.player.stats)

func _open(stats: PlayerStats) -> void:
	_stats = stats
	_is_open = true
	get_tree().paused = true
	show()
	_refresh_slots()
	_refresh_stats()
	_refresh_abilities()


func _on_close() -> void:
	_is_open = false
	get_tree().paused = false
	hide()


func _on_unequip(slot: String) -> void:
	var slot_enum: EquipmentData.slots
	match slot:
		"bow": slot_enum = EquipmentData.slots.BOW
		"arrow": slot_enum = EquipmentData.slots.ARROW
		"ring": slot_enum = EquipmentData.slots.RING
	
	var equipped_node: Equipment = PlayerManager.player.get_equipped_node_in_slot(slot_enum)
	if equipped_node == null:
		return
	equipped_node.become_unequipped()
	_refresh_slots()
	_refresh_stats()


func _on_hover(slot: String) -> void:
	var equipment: EquipmentData = _stats.get(slot)
	if equipment == null:
		return
	_hovered_slot = slot
	_refresh_stats()


func _on_unhover() -> void:
	_hovered_slot = ""
	_refresh_stats()


func _refresh_slots() -> void:
	bow_slot.refresh(_stats.bow, "Bow")
	quiver_slot.refresh(_stats.arrow, "Quiver")
	ring_slot.refresh(_stats.ring, "Ring")


func _refresh_stats() -> void:
	for child: Node in stats_panel.get_children():
		child.queue_free()

	if _hovered_slot != "":
		var equipment: EquipmentData = _stats.get(_hovered_slot)
		if equipment != null:
			_build_item_stats(equipment)
			return

	_build_player_stats()


func _build_player_stats() -> void:
	var current_group: String = ""
	for entry: Array in PlayerStats.DISPLAY_STATS:
		var group: String = entry[0]
		var display: String = entry[1]
		var prop: String = entry[2]

		if group != current_group:
			current_group = group
			var header: Label = Label.new()
			header.text = "— " + group + " —"
			stats_panel.add_child(header)

		var value: Variant = _stats.get(prop)
		if value == null:
			continue
		var line: Label = Label.new()
		line.text = display + ": " + _format_stat(value)
		stats_panel.add_child(line)


func _build_item_stats(equipment: EquipmentData) -> void:
	var header: Label = Label.new()
	header.text = equipment.display_name
	header.modulate = CustomVariables.rarity_color(equipment.rarity)
	stats_panel.add_child(header)

	for mod: EquipmentData.StatModifier in equipment.modifiers:
		var line: Label = Label.new()
		var _sign: String = "+" if mod.amount >= 0 else ""
		var type_label: String = " (x)" if mod.stat_type == Stat.buff_type.MULTIPLICATIVE else ""
		line.text = mod.stat_name + ": " + _sign + "%.2f" % mod.amount + type_label
		stats_panel.add_child(line)


func _refresh_abilities() -> void:
	for child: Node in abilities_panel.get_children():
		child.queue_free()

	var any: bool = false
	for pair: Array in PlayerStats.ABILITY_GROUPS:
		var label: String = pair[0]
		var prop: String = pair[1]
		var abilities: Array = _stats.get(prop)
		if abilities == null or abilities.is_empty():
			continue
		any = true
		var header: Label = Label.new()
		header.text = "— " + label + " —"
		abilities_panel.add_child(header)
		for ability: PlayerAbility in abilities:
			var line: Label = Label.new()
			line.text = ability.get_tooltip()
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			abilities_panel.add_child(line)

	if not any:
		var line: Label = Label.new()
		line.text = "No abilities"
		abilities_panel.add_child(line)


func _format_stat(value: Variant) -> String:
	if value is Stat:
		return "%.2f" % value.value()
	return str(value)
