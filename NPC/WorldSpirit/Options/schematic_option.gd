class_name SchematicOption extends SpiritOption
## "Hand in schematics (N)": reveals every waiting schematic into a known recipe.

@export var label_format: String = "Hand in schematics (%d)"
@export var name_highlight: Color = Color(0.55, 0.8, 1.0)

func _ready() -> void:
	Crafting.schematics_changed.connect(_on_crafting_schematics_changed)

func get_entries() -> Array[SpiritMenuEntry]:
	var entries: Array[SpiritMenuEntry] = []
	if Crafting.has_unidentified():
		entries.append(SpiritMenuEntry.new(label_format % Crafting.unidentified, priority, true))
	return entries

func run(_entry: SpiritMenuEntry, spirit: WorldSpirit) -> void:
	# Saved inside identify_all(), so leaving mid-line can't lose the recipes.
	var learned: Array[EquipmentData] = Crafting.identify_all()
	var lines: Array[String] = []
	if not learned.is_empty():
		lines.append(_reveal_line(learned))
	await spirit.say(lines)

func _reveal_line(learned: Array[EquipmentData]) -> String:
	var names: Array[String] = []
	for template: EquipmentData in learned:
		names.append("[color=#%s]%s[/color]" % [name_highlight.to_html(false), template.display_name])
	if names.size() == 1:
		return "These lines remember a lost artifact: %s. A smith could make it whole again." % names[0]
	return "These lines remember lost artifacts: %s. A smith could make them whole again." % ", ".join(names)

func _on_crafting_schematics_changed() -> void:
	entries_changed.emit()
