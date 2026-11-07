class_name DisenchantSkyshardChanceBonus extends DisenchantBonus
## Higher chance for disenchanted legendaries to also give a Skyshard.

@export_range(0.0, 100.0, 0.1, "suffix:%") var extra_chance: float = 5.0

func get_description() -> String:
	return "+%s%% Skyshard chance from legendaries" % format_number(extra_chance)

func modify_skyshard_chance(chance: float) -> float:
	return chance + extra_chance
