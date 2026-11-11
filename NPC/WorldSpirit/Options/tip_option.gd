class_name TipOption extends SpiritOption
## "Listen": the spirit shares a gameplay tip. The first unlocks after the first death in a run,
## then one more every deaths_per_new_tip deaths. Tips play in order, one per visit; a waiting
## tip lights the "!".

@export var label: String = "Listen"
@export var first_tip_after_deaths: int = 1
@export var deaths_per_new_tip: int = 2
## In order. Each entry is one chat box line.
@export_multiline var tips: Array[String] = []

func _ready() -> void:
	MetaProgress.boon_state_changed.connect(_on_meta_progress_boon_state_changed)

func get_entries() -> Array[SpiritMenuEntry]:
	var entries: Array[SpiritMenuEntry] = []
	if MetaProgress.tips_heard < unlocked_tips():
		entries.append(SpiritMenuEntry.new(label, priority, true))
	return entries

func unlocked_tips() -> int:
	var deaths: int = MetaProgress.run_deaths
	if deaths < first_tip_after_deaths:
		return 0
	@warning_ignore("integer_division")
	var unlocked: int = 1 + (deaths - first_tip_after_deaths) / maxi(deaths_per_new_tip, 1)
	return mini(unlocked, tips.size())

func run(_entry: SpiritMenuEntry, spirit: WorldSpirit) -> void:
	var index: int = MetaProgress.tips_heard
	if index >= tips.size():
		return
	# Only counts as heard once read to the end; walking away keeps it waiting.
	if await spirit.say([tips[index]]):
		MetaProgress.mark_tip_heard()

func _on_meta_progress_boon_state_changed() -> void:
	entries_changed.emit()
