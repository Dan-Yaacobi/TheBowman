class_name JourneyOption extends SpiritOption
## The spirit's call on the first hub visit: lights the "!" and sends the player to the rift.
## Only counts as heard once read to the end; walking away keeps it waiting.

@export var label: String = "Listen"
## In order. Each entry is one chat box line.
@export_multiline var lines: Array[String] = []

func _ready() -> void:
	MetaProgress.boon_state_changed.connect(_on_meta_progress_boon_state_changed)

func get_entries() -> Array[SpiritMenuEntry]:
	var entries: Array[SpiritMenuEntry] = []
	if not MetaProgress.journey_heard:
		entries.append(SpiritMenuEntry.new(label, priority, true))
	return entries

func run(_entry: SpiritMenuEntry, spirit: WorldSpirit) -> void:
	if await spirit.say(lines):
		MetaProgress.mark_journey_heard()

func _on_meta_progress_boon_state_changed() -> void:
	entries_changed.emit()
