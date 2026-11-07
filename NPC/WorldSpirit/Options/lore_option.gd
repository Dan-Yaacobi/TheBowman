class_name LoreOption extends SpiritOption
## "Ask about <item>": one entry per carried lore item, newest first.
## Plays the item's spirit lines one per Interact, then marks it explained.
## While the item's requirement isn't met the spirit only says its locked line, and the
## entry isn't a turn-in (no "!"), so a locked item can't keep the spirit lit forever.

@export var label_format: String = "Ask about %s"
## Sort priority for items the spirit can't explain yet (Talk is 0).
@export var locked_priority: int = 1

func _ready() -> void:
	Lore.lore_changed.connect(_on_lore_lore_changed)

func get_entries() -> Array[SpiritMenuEntry]:
	var entries: Array[SpiritMenuEntry] = []
	for item: LoreItemData in Lore.get_carried():
		var unlocked: bool = item.is_unlocked()
		var entry_priority: int = priority if unlocked else locked_priority
		entries.append(SpiritMenuEntry.new(label_format % item.display_name, entry_priority, unlocked, item))
	return entries

func run(entry: SpiritMenuEntry, spirit: WorldSpirit) -> void:
	var item: LoreItemData = entry.payload as LoreItemData
	if item == null:
		await spirit.say([])
		return
	if not item.is_unlocked():
		var locked: Array[String] = [item.requires.locked_line]
		await spirit.say(locked)
		return
	# Only marked once the last line was read; walking away keeps it to ask again.
	var completed: bool = await spirit.say(item.spirit_lines)
	if completed:
		Lore.mark_explained(item)

func _on_lore_lore_changed() -> void:
	entries_changed.emit()
