class_name JournalOption extends SpiritOption
## "Artifacts": opens the artifact journal once anything has been found.
## Not a turn-in, so it never lights the "!".

@export var label: String = "Artifacts"

func _ready() -> void:
	Lore.lore_changed.connect(_on_lore_lore_changed)

func get_entries() -> Array[SpiritMenuEntry]:
	var entries: Array[SpiritMenuEntry] = []
	if not Lore.carried.is_empty() or not Lore.explained.is_empty():
		entries.append(SpiritMenuEntry.new(label, priority, false))
	return entries

## The journal lives in the HUD's pause menu; asked for through the EventBus.
func run(_entry: SpiritMenuEntry, _spirit: WorldSpirit) -> void:
	EventBus.artifact_journal_requested.emit()
	await EventBus.artifact_journal_closed

func _on_lore_lore_changed() -> void:
	entries_changed.emit()
