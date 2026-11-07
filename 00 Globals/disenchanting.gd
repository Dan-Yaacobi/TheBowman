extends Node
## Autoload as "Disenchanting". Owns the run tally: every bow, quiver and ring the player
## inspects (opens the comparison window) inside a run, kept through death until disenchanted
## at the hub table. Only active once the disenchanting table is built.
## Also owns the lifetime count of disenchanted items and the milestone bonuses it unlocks.

const SAVE_SECTION: StringName = &"disenchanting"
## Construct id of the hub table. Saved in the save file. Never rename.
const TABLE_ID: StringName = &"disenchanting_table"
const CONFIG_PATH: String = "res://Objects/Constructs/DisenchantTable/Resources/disenchant_config.tres"

## One found item: all the table needs to work out its yield.
class FoundItem:
	var slot: EquipmentData.slots
	var rarity: int

	func _init(_slot: EquipmentData.slots, _rarity: int) -> void:
		slot = _slot
		rarity = _rarity

var tally: Array[FoundItem] = []
## Yield table (slot → material, amount per rarity, Skyshard chance) and milestones. Edit the .tres in the inspector.
var config: DisenchantConfig
## Every item ever disenchanted. Drives the milestones.
var lifetime_disenchanted: int = 0

func _ready() -> void:
	config = load(CONFIG_PATH) as DisenchantConfig
	if config == null:
		push_error("Disenchanting: missing config at %s" % CONFIG_PATH)
	SaveService.register(SAVE_SECTION, _save, _load)
	EventBus.equipment_inspected.connect(_on_event_bus_equipment_inspected)
	MetaProgress.construct_built.connect(_on_meta_progress_construct_built)
	EventBus.world_ready.connect(_on_event_bus_world_ready)

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

# --- Disenchanting --------------------------------------------------------

## Rolls what one tallied item gives. Doesn't change the tally; claim_next() pays it out.
func roll_yield(item: FoundItem) -> Dictionary[CustomVariables.items, int]:
	if config == null:
		return {}
	return config.roll_yield(item.slot, item.rarity)

## Removes the first tallied item and pays its rolled yield to the player, in one step,
## so an item is never removed without being paid. The table breaks items in tally order.
func claim_next(rewards: Dictionary[CustomVariables.items, int]) -> void:
	if tally.is_empty():
		return
	tally.pop_front()
	var player: Player = PlayerManager.player
	for item: CustomVariables.items in rewards:
		player.collect_item(item, rewards[item])
	lifetime_disenchanted += 1
	EventBus.found_items_changed.emit(get_count())
	for milestone: DisenchantMilestone in get_milestones():
		if milestone.get_stacks(lifetime_disenchanted) > milestone.get_stacks(lifetime_disenchanted - 1):
			_apply_to_player()
			EventBus.disenchant_milestone_reached.emit(get_milestone_level(), milestone)

## Called by the table once a sequence ends (finished or skipped). Saves once for the whole batch.
func finish_disenchanting() -> void:
	SaveService.save_game()

# --- Milestones -----------------------------------------------------------

func get_milestones() -> Array[DisenchantMilestone]:
	if config == null:
		return []
	return config.get_sorted_milestones()

## Times milestones were reached in total (a repeating milestone counts every time).
## Drives the table's visual growth (runes lit).
func get_milestone_level(lifetime: int = -1) -> int:
	if lifetime < 0:
		lifetime = lifetime_disenchanted
	var level: int = 0
	for milestone: DisenchantMilestone in get_milestones():
		level += milestone.get_stacks(lifetime)
	return level

## The milestone reached next, or null once none is left.
func get_next_milestone() -> DisenchantMilestone:
	var best: DisenchantMilestone = null
	var best_at: int = -1
	for milestone: DisenchantMilestone in get_milestones():
		var at: int = milestone.get_next_threshold(lifetime_disenchanted)
		if at >= 0 and (best == null or at < best_at):
			best = milestone
			best_at = at
	return best

## Lifetime count of the next milestone, or -1 once none is left.
func get_next_threshold() -> int:
	var next: DisenchantMilestone = get_next_milestone()
	return next.get_next_threshold(lifetime_disenchanted) if next else -1

## Safe to call any number of times: clears every milestone stat bonus, then re-adds the current stacks.
func apply_to(stats: PlayerStats) -> void:
	if stats == null:
		return
	for milestone: DisenchantMilestone in get_milestones():
		if milestone.bonus == null:
			continue
		var buff_id: int = _buff_id(milestone)
		milestone.bonus.clear_from_stats(stats, buff_id)
		for i: int in milestone.get_stacks(lifetime_disenchanted):
			milestone.bonus.apply_to_stats(stats, buff_id)

func _buff_id(milestone: DisenchantMilestone) -> int:
	return ("disenchant/%s" % milestone.resource_path).hash()

func _apply_to_player() -> void:
	var player: Player = PlayerManager.player
	if player:
		apply_to(player.stats)

## Re-applies stat bonuses after every world change, in case a death reset the player's stats.
func _on_event_bus_world_ready() -> void:
	_apply_to_player()

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
	return {"tally": items, "lifetime": lifetime_disenchanted}

## Entries with an unknown slot are skipped, so a removed slot never breaks a save.
func _load(data: Dictionary) -> void:
	lifetime_disenchanted = int(data.get("lifetime", 0))
	tally.clear()
	for raw: Variant in data.get("tally", []):
		if not raw is Dictionary:
			continue
		var slot: int = int(raw.get("slot", -1))
		if slot < 0 or slot >= EquipmentData.slots.size():
			push_warning("Disenchanting: unknown slot %d in saved tally" % slot)
			continue
		tally.append(FoundItem.new(slot as EquipmentData.slots, int(raw.get("rarity", 0))))
	_apply_to_player()
	EventBus.found_items_changed.emit(get_count())
