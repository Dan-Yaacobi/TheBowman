class_name LootManager extends Node2D

const EQUIPMENT: String = "res://Items/Equipments/Equipment.tscn"
@export var bow_pool: ItemPool
@export var quiver_pool: ItemPool
@export var ring_pool: ItemPool

enum Slot { BOW, QUIVER, RING }

func _ready() -> void:
	set_up()
	
func set_up() -> void:
	EventBus.try_drop.connect(drop_random_item)
	
func drop_item(slot: Slot) -> EquipmentData:
	return roll_item(bow_pool)
	match slot:
		Slot.BOW: return roll_item(bow_pool)
		Slot.QUIVER: return roll_item(quiver_pool)
		Slot.RING: return roll_item(ring_pool)
	return null

func drop_random_item(_position: Vector2) -> EquipmentData:
	var item: EquipmentData = drop_item(randi_range(0, 2) as Slot)
	EventBus.equipment_dropped.emit(item, _position)
	return item
# In LootManager

func roll_item(pool: ItemPool) -> EquipmentData:
	var data = EquipmentData.new()
	data.slot = pool.slot
	data.display_name = pool.possible_display_names.pick_random()
	data.equipment_scene = load(EQUIPMENT)

	var count = randi_range(pool.min_stat_count, pool.max_stat_count)
	var available = pool.possible_stats.duplicate()
	available.shuffle()

	var total_quality: float = 0.0

	for i in count:
		var def: StatRollDef = available[i]
		var amount = randf_range(def.min_value, def.max_value)
		amount = snappedf(amount, 0.1)
		data.add_modifier(def.stat_name, amount, def.type)

		# Quality: how close was this roll to the max (0.0 → 1.0)
		var range_size = def.max_value - def.min_value
		var quality: float = 0.0
		if range_size > 0.0:
			quality = (amount - def.min_value) / range_size
		total_quality += quality

	# Normalize: average quality per stat, scaled by stat count generosity
	# max_stat_count stats all at 1.0 = rarity 5
	var max_possible_quality = float(pool.max_stat_count)
	var raw_score = total_quality / max_possible_quality  # 0.0 → ~1.0+
	
	# Map to 1–5 range (scores above 1.0 can push past 5, handled by rarity_color)
	data.rarity = 1.0 + raw_score * 4.0
	data.texture = pool.possible_textures[mini(floori(data.rarity) - 1, pool.possible_textures.size() - 1)]

	return data
