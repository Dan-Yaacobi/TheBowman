class_name DisenchantEquipmentDropBonus extends DisenchantBonus
## Higher chance for chance-based equipment drops in rifts.

@export_range(0.0, 100.0, 0.1, "suffix:%") var extra_chance: float = 5.0

func get_description() -> String:
	return "+%s%% equipment drop chance in rifts" % format_number(extra_chance)

func modify_equipment_drop_chance(chance: float) -> float:
	return chance + extra_chance
