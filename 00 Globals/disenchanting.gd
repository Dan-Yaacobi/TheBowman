extends Node
## Autoload as "Disenchanting". Owns the run tally: every bow, quiver and ring the player
## inspects (opens the comparison window) inside a run, kept through death until disenchanted
## at the hub table. Only active once the disenchanting table is built.

const SAVE_SECTION: StringName = &"disenchanting"
## Construct id of the hub table. Saved in the save file. Never rename.
const TABLE_ID: StringName = &"disenchanting_table"

## One found item: all the table needs to work out its yield.
class FoundItem:
	var slot: EquipmentData.slots
	var rarity: int

	func _init(_slot: EquipmentData.slots, _rarity: int) -> void:
		slot = _slot
		rarity = _rarity

var tally: Array[FoundItem] = []

func _ready() -> void:
	SaveService.register(SAVE_SECTION, _save, _load)
	EventBus.equipment_inspected.connect(_on_event_bus_equipment_inspected)
	MetaProgress.construct_built.connect(_on_meta_progress_construct_built)

func is_active() -> bool:
	return MetaProgress.is_built(TABLE_ID)

func get_count() -> int:
	return tally.size()

## Counts each item instance once (swapping it in and out doesn't recount),
## and only inside a run: items inspected in the hub (e.g. a crafted item) never count.
func _on_event_bus_equipment_inspected(data: EquipmentData) -> void:
	if data == null or data.tallied:
		return
	# Flagged even when not counted, so a hub item carried into a rift never counts later.
	data.tallied = true
	if not is_active() or not _is_in_run():
		return
	tally.append(FoundItem.new(data.slot, roundi(data.rarity)))
	SaveService.save_game()
	EventBus.found_items_changed.emit(get_count())

## The hub resets rift_level to 0; rifts, events and boss arenas are all above it.
func _is_in_run() -> bool:
	var player: Player = PlayerManager.player
	return player != null and player.stats.rift_level > 0

func _on_meta_progress_construct_built(id: StringName) -> void:
	if id == TABLE_ID:
		EventBus.found_items_changed.emit(get_count())

# --- Save / load ----------------------------------------------------------

func _save() -> Dictionary:
	var items: Array = []
	for item: FoundItem in tally:
		items.append({"slot": int(item.slot), "rarity": item.rarity})
	return {"tally": items}

## Entries with an unknown slot are skipped, so a removed slot never breaks a save.
func _load(data: Dictionary) -> void:
	tally.clear()
	for raw: Variant in data.get("tally", []):
		if not raw is Dictionary:
			continue
		var slot: int = int(raw.get("slot", -1))
		if slot < 0 or slot >= EquipmentData.slots.size():
			push_warning("Disenchanting: unknown slot %d in saved tally" % slot)
			continue
		tally.append(FoundItem.new(slot as EquipmentData.slots, int(raw.get("rarity", 0))))
	EventBus.found_items_changed.emit(get_count())
