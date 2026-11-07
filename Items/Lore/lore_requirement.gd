class_name LoreRequirement extends Resource
## Gate on obtaining a lore item, e.g. campaign progress. Pickups of a gated item don't
## appear until it's met, so the spirit can always explain anything the player carries.
## This base always passes (campaign quests don't exist yet); subclass and override is_met().

func is_met() -> bool:
	return true
