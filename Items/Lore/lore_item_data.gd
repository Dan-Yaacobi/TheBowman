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
## Optional. The item can't be obtained until this is met. Empty = always obtainable.
@export var requires: LoreRequirement

@export_group("After")
## Optional. What the spirit says on a revisit once its meaning has changed. Empty = no revisit.
@export var after_lines: Array[String] = []
## When the after lines become available (e.g. the spirit's discovery). Empty = never.
@export var after_requires: LoreRequirement
@export_group("")

func is_unlocked() -> bool:
	return requires == null or requires.is_met()

## True when this item has after lines and their story moment has happened.
func is_after_unlocked() -> bool:
	return not after_lines.is_empty() and after_requires != null and after_requires.is_met()
