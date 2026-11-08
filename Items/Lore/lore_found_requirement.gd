class_name LoreFoundRequirement extends LoreRequirement
## Met once every listed lore item has been found (carried or explained).
## Gates hand-placed lore that must wait for earlier items, e.g. the tower artifacts.

@export var ids: Array[StringName] = []

func is_met() -> bool:
	for id: StringName in ids:
		if not Lore.has_found(id):
			return false
	return true
