class_name LoreFlagRequirement extends LoreRequirement
## Met once a story flag is set (Lore.set_flag), e.g. &"spirit_discovery" or &"met_defector".

@export var flag: StringName = &""

func is_met() -> bool:
	return flag != &"" and Lore.has_flag(flag)
