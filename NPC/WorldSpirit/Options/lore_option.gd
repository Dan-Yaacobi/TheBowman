class_name LoreOption extends SpiritOption
## "Ask about <item>": one entry per carried lore item, newest first.
## Plays the item's spirit lines one per Interact, then marks it explained.
## "Ask again about <item>": once an explained item's after lines unlock (a story flag),
## plays them once on a revisit.
## Items are gated when obtained (LoreItemData.requires), so anything carried can be explained.

@export var label_format: String = "Ask about %s"
@export var after_label_format: String = "Ask again about %s"

func _ready() -> void:
	Lore.lore_changed.connect(_on_lore_lore_changed)

func get_entries() -> Array[SpiritMenuEntry]:
	var entries: Array[SpiritMenuEntry] = []
	for item: LoreItemData in Lore.get_carried():
		entries.append(SpiritMenuEntry.new(label_format % item.display_name, priority, true, item))
	for item: LoreItemData in Lore.get_after_pending():
		entries.append(SpiritMenuEntry.new(after_label_format % item.display_name, priority, true, item))
	return entries

func run(entry: SpiritMenuEntry, spirit: WorldSpirit) -> void:
	var item: LoreItemData = entry.payload as LoreItemData
	if item == null:
		await spirit.say([])
		return
	# Only marked once the last line was read; walking away keeps it to ask again.
	if Lore.is_explained(item.id):
		var heard: bool = await spirit.say(item.after_lines)
		if heard:
			Lore.mark_after_heard(item)
		return
	var completed: bool = await spirit.say(item.spirit_lines)
	if completed:
		Lore.mark_explained(item)

func _on_lore_lore_changed() -> void:
	entries_changed.emit()
