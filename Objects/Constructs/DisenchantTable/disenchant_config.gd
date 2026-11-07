class_name DisenchantConfig extends Resource
## What disenchanting a found item gives back, and the lifetime milestones.
## One instance lives in Resources/disenchant_config.tres and is loaded by the Disenchanting autoload.

## Which resource each equipment slot breaks into.
@export var slot_materials: Dictionary[EquipmentData.slots, CustomVariables.items] = {
	EquipmentData.slots.BOW: CustomVariables.items.WOOD,
	EquipmentData.slots.ARROW: CustomVariables.items.ESSENCE,
	EquipmentData.slots.RING: CustomVariables.items.COIN,
}
## Material amount per rarity, indexed by EquipmentData.Rarity (common, rare, epic, legendary).
@export var amount_per_rarity: Array[int] = [2, 4, 8, 15]
## Chance (%) that a legendary also gives a Skyshard.
@export_range(0.0, 100.0, 0.1, "suffix:%") var legendary_skyshard_chance: float = 5.0
@export var skyshards_per_drop: int = 1
## Lifetime milestones. Any order; sorted by threshold when used.
@export var milestones: Array[DisenchantMilestone] = []

## Rolls the yield of one item with the given bonuses. Each call rolls the Skyshard chance again.
func roll_yield(slot: EquipmentData.slots, rarity: int, bonuses: Array[DisenchantBonus]) -> Dictionary[CustomVariables.items, int]:
	var result: Dictionary[CustomVariables.items, int] = {}
	if slot_materials.has(slot) and not amount_per_rarity.is_empty():
		var amount: int = amount_per_rarity[clampi(rarity, 0, amount_per_rarity.size() - 1)]
		for bonus: DisenchantBonus in bonuses:
			amount = bonus.modify_yield_amount(amount, slot, rarity)
		if amount > 0:
			result[slot_materials[slot]] = amount
	if rarity >= EquipmentData.Rarity.LEGENDARY:
		var chance: float = legendary_skyshard_chance
		for bonus: DisenchantBonus in bonuses:
			chance = bonus.modify_skyshard_chance(chance)
		if randf_range(0.0, 100.0) < chance:
			var item: CustomVariables.items = CustomVariables.items.SKYSHARD
			result[item] = result.get(item, 0) + skyshards_per_drop
	return result

## Milestones that have a bonus, lowest threshold first.
func get_sorted_milestones() -> Array[DisenchantMilestone]:
	var sorted: Array[DisenchantMilestone] = milestones.filter(
		func(m: DisenchantMilestone) -> bool: return m != null)
	sorted.sort_custom(func(a: DisenchantMilestone, b: DisenchantMilestone) -> bool: return a.threshold < b.threshold)
	return sorted
