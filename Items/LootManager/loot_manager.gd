class_name LootManager extends Node2D
const EQUIPMENT: String = "res://Items/Equipments/Equipment.tscn"
const COIN: String = "res://Items/Other/Coin/coin.tscn"

@export var max_rift_level: int = 15
# Rarity
@export var quality_floor_max: float = 0.8       # how high the floor gets at max rarity
@export var quality_ceiling_min: float = 0.4     # ceiling for rarity 1 items
@export var rarity_bias: float = 3.0             # higher = legendary items rarer (C base)
@export var lift_exp: float = 0.7

# Rift level scaling
@export var rift_stat_scale: float = 0.1         # A: how much stat ranges grow per rift (logarithmic)
@export var rift_quality_scale: float = 0.1      # B: how much rift level boosts quality floor
@export var rift_rarity_scale: float = 0.1       # C: how much rift level reduces rarity bias

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

func drop_item(slot: Slot, _rarity_skew: float = 0) -> EquipmentData:
	match slot:
		Slot.BOW: return roll_item(bow_pool, _rarity_skew)
		Slot.QUIVER: return roll_item(quiver_pool, _rarity_skew)
		Slot.RING: return roll_item(ring_pool, _rarity_skew)
	return null

func drop_random_item(_position: Vector2, _chance: float, _rarity_skew: float = 0) -> void:
	if randf_range(0, 100) <= _chance:
		var item: EquipmentData = drop_item(randi_range(0, 2) as Slot, _rarity_skew)
		EventBus.equipment_dropped.emit(item, _position, null)

func drop_coins(_position: Vector2, _amount: int) -> void:
	ItemDropManager.drop_coins(_position, _amount)

func drop_potion(_position: Vector2, _chance: float) -> void:
	ItemDropManager.drop_potion(_position, _chance)

func roll_item(pool: ItemPool, _rarity_skew: float = 0) -> EquipmentData:
	var template: EquipmentData = _pick_template(pool)
	if template == null:
		push_error("ItemPool has no templates: " + str(pool.resource_path))
		return null
	var data: EquipmentData = template.duplicate()
	# own our ability instance — never register/mutate the shared template resource
	if data.ability:
		data.ability = data.ability.duplicate()

	var rift_level: int = PlayerManager.player.stats.rift_level

	# A: logarithmic stat range scalar — gradual growth with rift level
	var rift_stat_scalar: float = 1.0 + log(max(rift_level, 1)) * rift_stat_scale

	# B: rift quality floor boost — later rifts guarantee better rolls
	var rift_quality_boost: float = log(max(rift_level, 1)) * rift_quality_scale

	# C: rift rarity bias reduction — higher rarity items more common in later rifts
	var t: float = minf(float(rift_level) / float(max_rift_level), 1.0)
	var s: float = t * t * (3.0 - 2.0 * t)
	var effective_rarity_bias: float = lerpf(rarity_bias, 0.5, s)

	# roll rarity first
	var rarity_roll: float = randf()
	var rarity_curved: float = pow(pow(rarity_roll, lift_exp), effective_rarity_bias)
	data.rarity = clampf(1.0 + rarity_curved * (CustomVariables.MAX_RARITY - 1) + _rarity_skew, 1.0, CustomVariables.MAX_RARITY)
	var rarity_normalized: float = (data.rarity - 1.0) / (CustomVariables.MAX_RARITY - 1.0)

	# quality floor and ceiling — rarity driven + rift quality boost
	var quality_floor: float = clampf(rarity_normalized * quality_floor_max + rift_quality_boost, 0.0, 1.0)
	var quality_ceiling: float = clampf(rarity_normalized * (1.0 - quality_ceiling_min) + quality_ceiling_min + rift_quality_boost, 0.0, 1.0)

	# guaranteed stats — every entry always rolls, only the value varies
	for def in template.guaranteed_stats:
		var roll_bounded: float = quality_floor + randf() * (quality_ceiling - quality_floor)
		var scaled_min: float = def.min_value * rift_stat_scalar
		var scaled_max: float = def.max_value * rift_stat_scalar
		var amount: float = snappedf(scaled_min + roll_bounded * (scaled_max - scaled_min), 0.1)
		data.add_modifier(def.stat_name, amount, def.type)

	# minor abilities — count scales with rarity, picked without replacement
	var minor_count: int = template.min_minor_count + roundi(rarity_normalized * (template.max_minor_count - template.min_minor_count))
	data.bonus_abilities = _roll_minors(template.minor_abilities, minor_count, quality_floor, quality_ceiling)

	data.equipment_scene = load(EQUIPMENT)
	return data

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

func _roll_minors(available: Array[MinorAbility], count: int, quality_floor: float, quality_ceiling: float) -> Array[MinorAbility]:
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
				var quality: float = quality_floor + randf() * (quality_ceiling - quality_floor)
				rolled.roll_values(quality)
				result.append(rolled)
				remaining.erase(minor)
				break
	return result
