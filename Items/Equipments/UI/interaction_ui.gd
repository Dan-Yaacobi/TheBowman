class_name EquipmentInteractionUI extends Control

const STAT_LABEL = preload("uid://d3g6yk0cua2ov")
signal equip_new_item
signal destory_new_item
@onready var current_item: VBoxContainer = $PanelContainer/VBoxContainer/HBoxContainer/CurrentItem
@onready var new_item: VBoxContainer = $PanelContainer/VBoxContainer/HBoxContainer/NewItem

@export var stat_names_dict: Dictionary[String,String] = {}

func _make_label(_name: String, _amount: float = NAN) -> StatLabel:
	var label: StatLabel = STAT_LABEL.instantiate()
	label.set_label(_name, _amount)
	return label

func set_items(new_equip: Equipment, current_equip: EquipmentData) -> void:
	for child in new_item.get_children():
		child.queue_free()
	for child in current_item.get_children():
		child.queue_free()

	# display name
	var new_name_label = _make_label(new_equip.data.display_name)
	var cur_name_label = _make_label(current_equip.display_name if current_equip else "Empty")
	new_name_label.set_color(rarity_color(new_equip.data.rarity))
	cur_name_label.set_color(rarity_color(current_equip.rarity) if current_equip else Color.WHITE)
	new_item.add_child(new_name_label)
	current_item.add_child(cur_name_label)

	# stats
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

		var new_label = _make_label(stat_names_dict[stat_name], new_amount)
		var cur_label = _make_label(stat_names_dict[stat_name], cur_amount)

		if new_amount > cur_amount:
			new_label.set_color(Color.GREEN)
			cur_label.set_color(Color.RED)
		elif cur_amount > new_amount:
			cur_label.set_color(Color.GREEN)
			new_label.set_color(Color.RED)

		new_item.add_child(new_label)
		current_item.add_child(cur_label)
		
func rarity_color(rarity: float) -> Color:
	var colors: Array[Color] = [
		Color.WHITE,
		Color.GREEN,
		Color.CYAN,
		Color.PURPLE,
		Color.ORANGE
	]
	if rarity >= 5.0:
		var overflow = clampf(rarity - 5.0, 0.0, 1.0)
		return Color.ORANGE.lerp(Color(1.0, 0.84, 0.0), overflow)
	var t = clampf(rarity - 1.0, 0.0, 4.0)
	var low = floori(t)
	var high = mini(low + 1, 4)
	return colors[low].lerp(colors[high], t - low)

func _on_equip_button_pressed() -> void:
	equip_new_item.emit()

func _on_delete_button_pressed() -> void:
	destory_new_item.emit()
