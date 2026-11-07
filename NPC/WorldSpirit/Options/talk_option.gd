class_name TalkOption extends SpiritOption
## "Talk": one random line from the spirit's NPCData dialogue lines. Always available.

@export var label: String = "Talk"

func get_entries() -> Array[SpiritMenuEntry]:
	var entries: Array[SpiritMenuEntry] = []
	entries.append(SpiritMenuEntry.new(label, priority, false))
	return entries

func run(_entry: SpiritMenuEntry, spirit: WorldSpirit) -> void:
	var lines: Array[String] = []
	if not spirit.data.dialogue_lines.is_empty():
		lines.append(spirit.data.dialogue_lines.pick_random())
	await spirit.say(lines)
