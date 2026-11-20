class_name BoonOption extends SpiritOption
## "Accept a blessing": after every run the spirit offers 3 boons for the next one (pick 1).
## Choosing it opens the picker straight away. Once picked, the blessing flows into the archer
## and the spirit says the boon's blessing_line.
## A turn-in, so it lights the "!" until a boon is picked. The picker lives in the HUD and is
## asked for through the EventBus.

@export var label: String = "Accept a blessing"
## Said after picking a boon that has no blessing_line of its own.
@export_multiline var fallback_line: String = ""
## Played over the archer, tinted with the boon's title color.
@export var blessing_effect: StringName = &"color_level_up"

func _ready() -> void:
	MetaProgress.boon_state_changed.connect(_on_meta_progress_boon_state_changed)

func get_entries() -> Array[SpiritMenuEntry]:
	var entries: Array[SpiritMenuEntry] = []
	if MetaProgress.boon_offer_pending:
		entries.append(SpiritMenuEntry.new(label, priority, true))
	return entries

func run(_entry: SpiritMenuEntry, spirit: WorldSpirit) -> void:
	# The chat box draws above the HUD, so it's hidden while the picker is open.
	var chat_box: ChatBox = spirit.chat_box
	if chat_box:
		chat_box.visible = false
	EventBus.boon_picker_requested.emit(MetaProgress.get_boon_offers())
	await EventBus.boon_picker_closed
	if not is_instance_valid(spirit) or not spirit.is_inside_tree():
		return
	if is_instance_valid(chat_box):
		chat_box.visible = true
	var boon: SpiritBoon = MetaProgress.find_boon(MetaProgress.chosen_boon)
	if boon == null:
		return
	spirit.flare(boon.title_color)
	EffectSprite.attach_over_player(blessing_effect, boon.title_color)
	var lines: Array[String] = []
	var line: String = boon.blessing_line if not boon.blessing_line.is_empty() else fallback_line
	if not line.is_empty():
		lines.append(line)
	await spirit.say(lines)

func _on_meta_progress_boon_state_changed() -> void:
	entries_changed.emit()
