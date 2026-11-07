class_name SpiritOption extends Node
## Base for everything the spirit's menu can offer. Add one as a child of WorldSpirit/Options
## to add a menu option; the menu itself never changes.

## Emit whenever get_entries() would return something different (refreshes the "!").
signal entries_changed

## Higher sorts first in the menu.
@export var priority: int = 0

## Entries this option offers right now. Empty hides it.
func get_entries() -> Array[SpiritMenuEntry]:
	return []

## Plays the option. Awaited by the menu, which reopens when this returns.
## Default: nothing to say.
func run(_entry: SpiritMenuEntry, spirit: WorldSpirit) -> void:
	await spirit.say([])
