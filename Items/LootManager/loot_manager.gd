class_name LootManager extends Node2D
const EQUIPMENT: String = "res://Items/Equipments/Equipment.tscn"
const COIN: String = "res://Items/Other/Coin/coin.tscn"

@export var max_rift_level: int = 15

# Rarity odds — base weights per tier (index matches EquipmentData.Rarity), higher rift level biases toward the back of this array
@export var rarity_weights: Array[float] = [50.0, 30.0, 15.0, 5.0]
@export var rift_rarity_scale: float = 0.15       # how much rift level pulls odds toward higher tiers

# Value shift per tier — % increase applied to stat ranges, shared across every item
@export var rarity_value_shift: Array[float] = [0.0, 0.2, 0.5, 0.8]

# Rift level scaling
@export var rift_stat_scale: float = 0.1          # how much stat ranges grow per rift (logarithmic), stacks with rarity_value_shift

@export var bow_pool: ItemPool
@export var quiver_pool: ItemPool
@export var ring_pool: ItemPool

enum Slot { BOW, QUIVER, RING }


func set_up() -> void:
	EventBus.try_drop.connect(drop_random_item)
	EventBus.drop_coins.connect(drop_coins)
	EventBus.drop_potion.connect(drop_potion)

func unset_up() -> void:
	EventBus.try_drop.disconnect(drop_random_item)
	EventBus.drop_coins.disconnect(drop_coins)
	EventBus.drop_potion.disconnect(drop_potion)

func drop_item(slot: Slot, forced_rarity: int = -1) -> EquipmentData:
	match slot:
		Slot.BOW: return roll_item(bow_pool, forced_rarity)
		Slot.QUIVER: return roll_item(quiver_pool, forced_rarity)
		Slot.RING: return roll_item(ring_pool, forced_rarity)
	return null

func drop_random_item(_position: Vector2, _chance: float, forced_rarity: int = -1) -> void:
	if randf_range(0, 100) <= _chance:
		var item: EquipmentData = drop_item(randi_range(0, 2) as Slot, forced_rarity)
		EventBus.equipment_dropped.emit(item, _position, null)

func drop_coins(_position: Vector2, _amount: int) -> void:
	ItemDropManager.drop_coins(_position, _amount)

func drop_potion(_position: Vector2, _chance: float) -> void:
	ItemDropManager.drop_potion(_position, _chance)

func roll_item(pool: ItemPool, forced_rarity: int = -1) -> EquipmentData:
	var template: EquipmentData = _pick_template(pool)
	if template == null:
		push_error("ItemPool has no templates: " + str(pool.resource_path))
		return null
	var data: EquipmentData = template.duplicate()
	if data.ability:
		data.ability = data.ability.duplicate()
	data.equipment_scene = template.equipment_scene

	var rarity: int = forced_rarity if forced_rarity >= 0 else _roll_rarity()
	_apply_rarity_rolls(data, rarity)
	return data

## Rerolls an already-owned item fully at a specific rarity — used by the wizard NPC.
## Fully replaces modifiers/minors; nothing from the previous roll is preserved.
func wizard_reroll(item: EquipmentData, new_rarity: int) -> void:
	_apply_rarity_rolls(item, new_rarity)

func _apply_rarity_rolls(data: EquipmentData, rarity: int) -> void:
	data.rarity = rarity
	data.modifiers = []
	data.bonus_abilities = []

	var rift_level: int = PlayerManager.player.stats.rift_level
	var rift_stat_scalar: float = 1.0 + log(max(rift_level, 1)) * rift_stat_scale
	var shift: float = rarity_value_shift[rarity]
	var range_multiplier: float = 1.0 + shift

	for tier_index in range(rarity + 1):
		var tier: RarityTier = data.tiers[tier_index]
		for def in tier.stat_rolls:
			var scaled_min: float = def.min_value * rift_stat_scalar * range_multiplier
			var scaled_max: float = def.max_value * rift_stat_scalar * range_multiplier
			var amount: float = snappedf(randf_range(scaled_min, scaled_max), 0.1)
			data.add_modifier(def.stat_name, amount, def.type)
		if tier.minor_roll_count > 0 and not tier.minor_ability_pool.is_empty():
			data.bonus_abilities.append_array(_roll_minors(tier.minor_ability_pool, tier.minor_roll_count, shift))

func _roll_rarity() -> int:
	var rift_level: int = PlayerManager.player.stats.rift_level
	var t: float = minf(float(rift_level) / float(max_rift_level), 1.0)
	var s: float = t * t * (3.0 - 2.0 * t)  # smoothstep

	var weights: Array[float] = rarity_weights.duplicate()
	# nudge odds toward higher tiers as rift level climbs
	for i in weights.size():
		var tier_bias: float = float(i) / float(weights.size() - 1)  # 0 for common, 1 for legendary
		weights[i] = lerpf(weights[i], weights[i] * (1.0 + tier_bias * rift_rarity_scale * 10.0), s)

	var total: float = 0.0
	for w in weights:
		total += w
	var roll: float = randf() * total
	var cumulative: float = 0.0
	for i in weights.size():
		cumulative += weights[i]
		if roll <= cumulative:
			return i
	return weights.size() - 1

func _pick_template(pool: ItemPool) -> EquipmentData:
	if pool.templates.is_empty():
		return null
	var total_weight: float = 0.0
	for template in pool.templates:
		total_weight += template.pick_weight
	var roll: float = randf() * total_weight
	var cumulative: float = 0.0
	for template in pool.templates:
		cumulative += template.pick_weight
		if roll <= cumulative:
			return template
	return pool.templates.back()

func _roll_minors(available: Array[MinorAbility], count: int, shift: float) -> Array[MinorAbility]:
	var result: Array[MinorAbility] = []
	var remaining: Array[MinorAbility] = available.duplicate()
	for i in count:
		if remaining.is_empty():
			break
		var total_weight: float = 0.0
		for minor in remaining:
			total_weight += 1.0 / minor.rarity_weight
		var roll: float = randf() * total_weight
		var cumulative: float = 0.0
		for minor in remaining:
			cumulative += 1.0 / minor.rarity_weight
			if roll <= cumulative:
				var rolled: MinorAbility = minor.duplicate()
				rolled.apply_shift(shift)
				result.append(rolled)
				remaining.erase(minor)
				break
	return result
	
func roll_specific(template: EquipmentData, forced_rarity: int = 0) -> EquipmentData:
	var data: EquipmentData = template.duplicate()
	if data.ability:
		data.ability = data.ability.duplicate()
	data.equipment_scene = template.equipment_scene
	_apply_rarity_rolls(data, forced_rarity)
	return data
