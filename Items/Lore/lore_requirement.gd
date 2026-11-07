class_name LoreRequirement extends Resource
## Gate on a lore item's explanation. This base always passes (campaign quests don't exist yet);
## subclass and override is_met() for real conditions.

## What the spirit says while the requirement isn't met.
@export var locked_line: String = "I can't remember... not yet."

func is_met() -> bool:
	return true
