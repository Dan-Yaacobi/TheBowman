class_name LoreItemData extends Resource
## A rare collectible found in rifts. Picked up once; the spirit explains it back in the hub.

## Saved in the save file. Never change it once an item ships.
@export var id: StringName = &""
@export var display_name: String = ""
@export var icon: Texture2D
## One short sentence shown when the item is picked up.
@export_multiline var pickup_line: String = ""
## What the spirit says when asked, one line per Interact.
@export var spirit_lines: Array[String] = []
## Optional. Until it's met, the spirit can't remember anything about the item. Empty = always met.
@export var requires: LoreRequirement

func is_unlocked() -> bool:
	return requires == null or requires.is_met()
