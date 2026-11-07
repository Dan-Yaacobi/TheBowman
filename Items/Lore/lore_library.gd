class_name LoreLibrary extends Resource
## Every lore item in the game. Saves store ids; this turns them back into items.
## Add each new LoreItemData here.

@export var items: Array[LoreItemData] = []

func find(id: StringName) -> LoreItemData:
	for item: LoreItemData in items:
		if item and item.id == id:
			return item
	return null
