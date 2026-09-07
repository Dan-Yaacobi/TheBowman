class_name LootManager extends Node2D
const EQUIPMENT: String = "res://Items/Equipments/Equipment.tscn"
const COIN: String = "res://Items/Other/Coin/coin.tscn"

@export var max_rift_level: int = 15

# Rift level → tier thresholds. Reaching threshold N grants tier N (index into data.tiers / RarityTier arrays)
@export var rift_level_tier_bands: Array[int] = [4, 8, 12]
@export var tier_upgrade_chance: float = 0.15   # chance to roll one tier above your guaranteed floor

# Rift level scaling — the only lever on stat magnitude; bounded via smoothstep against max_rift_level
@export var rift_stat_scale: float = 0.5

@export var bow_pool: ItemPool
@export var quiver_pool: ItemPool
@export var ring_pool: ItemPool

enum Slot { BOW, QUIVER, RING }

func _enter_tree() -> void:
	GameStateManager.current_loot_manager = self
	
func set_up() -> void:
	EventBus.try_drop.connect(drop_random_item)
	EventBus.drop_coins.connect(drop_coins)
	EventBus.drop_potion.connect(drop_potion)
	EventBus.drop_specific_item.connect(drop_specific)
	
func unset_up() -> void:
	EventBus.try_drop.disconnect(drop_random_item)
	EventBus.drop_coins.disconnect(drop_coins)
	EventBus.drop_potion.disconnect(drop_potion)
	EventBus.drop_specific_item.disconnect(drop_specific)
	
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
	return _roll_from_template(template, forced_rarity)

## Rerolls an already-owned item fully at a specific rarity — used by the wizard NPC.
## Fully replaces modifiers/minors; nothing from the previous roll is preserved.
func wizard_reroll(item: EquipmentData, new_rarity: int) -> void:
	_apply_rarity_rolls(item, new_rarity)

func _apply_rarity_rolls(data: EquipmentData, rarity: int) -> void:
	data.rarity = rarity
	data.modifiers = []
	data.bonus_abilities = []

	var rift_level: int = PlayerManager.player.stats.rift_level
	var t: float = minf(float(rift_level) / float(max_rift_level), 1.0)
	var s: float = t * t * (3.0 - 2.0 * t)  # smoothstep, bounded growth
	var rift_stat_scalar: float = 1.0 + s * rift_stat_scale

	for tier_index in range(rarity + 1):
		var tier: RarityTier = data.tiers[tier_index]
		for def in tier.stat_rolls:
			var scaled_min: float = def.min_value * rift_stat_scalar
			var scaled_max: float = def.max_value * rift_stat_scalar
			var amount: float = snappedf(randf_range(scaled_min, scaled_max), 0.1)
			data.add_modifier(def.stat_name, amount, def.type)
		if tier.minor_roll_count > 0 and not tier.minor_ability_pool.is_empty():
			data.bonus_abilities.append_array(_roll_minors(tier.minor_ability_pool, tier.minor_roll_count, 0.0))

## Guaranteed tier floor based on rift level, with a small chance to roll one tier above it.
## Rarity is never randomly rolled below the current rift-level band.
func _rarity_for_rift_level(rift_level: int) -> int:
	var tier: int = 0
	for threshold in rift_level_tier_bands:
		if rift_level >= threshold:
			tier += 1
	var max_tier: int = rift_level_tier_bands.size()
	if randf() < tier_upgrade_chance:
		tier = mini(tier + 1, max_tier)
	return tier

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
	
func roll_distinct_items(count: int, forced_rarity: int = -1) -> Array[EquipmentData]:
	var remaining: Array[EquipmentData] = []
	remaining.append_array(bow_pool.templates)
	remaining.append_array(quiver_pool.templates)
	remaining.append_array(ring_pool.templates)

	var results: Array[EquipmentData] = []
	for i in mini(count, remaining.size()):
		var total_weight: float = 0.0
		for template in remaining:
			total_weight += template.pick_weight
		var roll: float = randf() * total_weight
		var cumulative: float = 0.0
		for template in remaining:
			cumulative += template.pick_weight
			if roll <= cumulative:
				results.append(_roll_from_template(template, forced_rarity))
				remaining.erase(template)
				break

	return results

func _roll_from_template(template: EquipmentData, forced_rarity: int = -1) -> EquipmentData:
	var data: EquipmentData = template.duplicate()
	if data.ability:
		data.ability = data.ability.duplicate()
	data.equipment_scene = template.equipment_scene
	var rarity: int = forced_rarity if forced_rarity >= 0 else _rarity_for_rift_level(PlayerManager.player.stats.rift_level)
	_apply_rarity_rolls(data, rarity)
	return data
	
func drop_specific(template: EquipmentData, _position: Vector2, forced_rarity: int = 0) -> void:
	var item: EquipmentData = template.duplicate()
	if item.ability:
		item.ability = item.ability.duplicate()
	item.equipment_scene = template.equipment_scene
	_apply_rarity_rolls(item, forced_rarity)
	EventBus.equipment_dropped.emit(item, _position, null)
