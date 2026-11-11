class_name BoonOption extends SpiritOption
## "Accept a blessing": after every death the spirit offers 3 boons for the next run (pick 1).
## A turn-in, so it lights the "!" until a boon is picked. The picker lives in the HUD and is
## asked for through the EventBus.

@export var label: String = "Accept a blessing"
@export_multiline var offer_line: String = "The void sent you back to me. Take a piece of this world with you."

func _ready() -> void:
	MetaProgress.boon_state_changed.connect(_on_meta_progress_boon_state_changed)

func get_entries() -> Array[SpiritMenuEntry]:
	var entries: Array[SpiritMenuEntry] = []
	if MetaProgress.boon_offer_pending:
		entries.append(SpiritMenuEntry.new(label, priority, true))
	return entries

func run(_entry: SpiritMenuEntry, spirit: WorldSpirit) -> void:
	if not await spirit.say([offer_line]):
		return
	# The chat box draws above the HUD, so it's hidden while the picker is open.
	var chat_box: ChatBox = spirit.chat_box
	if chat_box:
		chat_box.visible = false
	EventBus.boon_picker_requested.emit(MetaProgress.get_boon_offers())
	await EventBus.boon_picker_closed
	if is_instance_valid(chat_box):
		chat_box.visible = true

func _on_meta_progress_boon_state_changed() -> void:
	entries_changed.emit()
