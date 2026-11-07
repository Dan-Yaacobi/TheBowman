class_name DisenchantFirstDropRarityBonus extends DisenchantBonus
## The first equipment drop of each run rolls at least this rarity.

@export var min_rarity: EquipmentData.Rarity = EquipmentData.Rarity.UNCOMMON

func get_description() -> String:
	return "First item each run is at least %s" % CustomVariables.rarity_name(min_rarity)

func modify_first_drop_min_rarity(current_min: int) -> int:
	return maxi(current_min, min_rarity)
