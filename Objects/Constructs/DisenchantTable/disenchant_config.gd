class_name DisenchantConfig extends Resource
## What disenchanting a found item gives back. One instance lives in Resources/disenchant_config.tres
## and is loaded by the Disenchanting autoload.

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

## Rolls the yield of one item. Each call rolls the Skyshard chance again.
func roll_yield(slot: EquipmentData.slots, rarity: int) -> Dictionary[CustomVariables.items, int]:
	var result: Dictionary[CustomVariables.items, int] = {}
	if slot_materials.has(slot) and not amount_per_rarity.is_empty():
		var amount: int = amount_per_rarity[clampi(rarity, 0, amount_per_rarity.size() - 1)]
		if amount > 0:
			result[slot_materials[slot]] = amount
	if rarity >= EquipmentData.Rarity.LEGENDARY and randf_range(0.0, 100.0) < legendary_skyshard_chance:
		var item: CustomVariables.items = CustomVariables.items.SKYSHARD
		result[item] = result.get(item, 0) + skyshards_per_drop
	return result
