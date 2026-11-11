extends Node
## Autoload as "MetaProgress" (as a scene, so `tracks` can be filled in the inspector).
## Owns permanent upgrade levels, milestone picks and built constructs,
## and applies the bonuses to PlayerStats and the player.

signal levels_changed
signal construct_built(id: StringName)
signal milestone_offers_ready(track: UpgradeTrack)
## The spirit's boon offer or tips changed (offer appeared/picked/used, death counted, tip heard).
signal boon_state_changed

const SAVE_SECTION: StringName = &"meta"
## Marks a milestone that granted the track's fallback step (pool was empty).
const FALLBACK_ID: StringName = &"__fallback"

# load(), not preload(): the tracks pull in milestone ability scripts that depend on Player,
# which would make this autoload part of a compile-order cycle.
var tracks: Array[UpgradeTrack] = [
	load("res://Objects/Constructs/UpgradeAltar/Resources/power_track.tres"),
	load("res://Objects/Constructs/UpgradeAltar/Resources/sword_track.tres"),
	load("res://Objects/Constructs/UpgradeAltar/Resources/hp_track.tres"),
	load("res://Objects/Constructs/UpgradeAltar/Resources/mobility_track.tres"),
]

var levels: Dictionary[StringName, int] = {}
var built: Array[StringName] = []
## Per track: reward ids picked, in order.
var picks: Dictionary[StringName, Array] = {}
## Per track: reward ids waiting for the player to choose one.
var pending: Dictionary[StringName, Array] = {}
## Ability instances MetaProgress registered on the player, so they can be removed cleanly.
var _meta_abilities: Array[PlayerAbility] = []

# --- Spirit boons ---
const BOONS_OFFERED: int = 3
## load(), not preload(): see `tracks`.
var boon_pool: Array[SpiritBoon] = [
	load("res://NPC/WorldSpirit/Boons/Resource/steadfast_heart.tres"),
	load("res://NPC/WorldSpirit/Boons/Resource/keen_wind.tres"),
	load("res://NPC/WorldSpirit/Boons/Resource/quick_breath.tres"),
	load("res://NPC/WorldSpirit/Boons/Resource/stone_edge.tres"),
	load("res://NPC/WorldSpirit/Boons/Resource/lost_bow.tres"),
	load("res://NPC/WorldSpirit/Boons/Resource/lost_quiver.tres"),
	load("res://NPC/WorldSpirit/Boons/Resource/lost_ring.tres"),
]
## True from the end of a run (death or back to the hub) until the player picks a boon.
var boon_offer_pending: bool = false
## True between entering a rift and the run ending. Not saved: a quit mid-run offers nothing.
var _run_in_progress: bool = false
## The rolled offer, saved so reloading can't reroll it. Empty until first shown.
var boon_offers: Array[StringName] = []
## Picked boon waiting for the next run's first rift.
var chosen_boon: StringName = &""
## Runs that ended in death (practice deaths excluded). Drives the spirit's tips.
var run_deaths: int = 0
## How many of the spirit's tips the player has heard, in order.
var tips_heard: int = 0
## The boon applied to the run in progress (not saved).
var _applied_boon: SpiritBoon = null
var _boon_buff_id: int = "meta/boon".hash()

func _ready() -> void:
	SaveService.register(SAVE_SECTION, _save, _load)
	EventBus.player_died.connect(_on_event_bus_player_died)
	EventBus.entered_rift.connect(_on_event_bus_entered_rift)
	EventBus.in_main_menu.connect(_on_event_bus_in_main_menu)

# --- Levels ---------------------------------------------------------------

func get_level(track: UpgradeTrack) -> int:
	return levels.get(track.id, 0)

func get_cost(track: UpgradeTrack) -> Dictionary[CustomVariables.items, int]:
	return track.get_cost(get_level(track))

func can_afford(track: UpgradeTrack, stats: PlayerStats) -> bool:
	if has_pending(track):
		return false
	if track.is_maxed(get_level(track)):
		return false
	return can_pay(get_cost(track), stats)

## Buys one level. Returns false if it can't be afforded, the track is maxed,
## or a milestone choice is still waiting.
func purchase(track: UpgradeTrack, player: Player) -> bool:
	if not can_afford(track, player.stats):
		return false
	var cost: Dictionary[CustomVariables.items, int] = get_cost(track)
	for item: CustomVariables.items in cost:
		player.buy(cost[item], item)
	levels[track.id] = get_level(track) + 1
	_resolve_milestones(track)
	_apply_all(player)
	SaveService.save_game()
	levels_changed.emit()
	return true

# --- Applying -------------------------------------------------------------

## Safe to call any number of times: clears every meta buff, then re-adds the current totals.
## Covers cycle steps plus milestone stat steps. Player._ready() calls it.
func apply_to(stats: PlayerStats) -> void:
	for track: UpgradeTrack in tracks:
		for step: UpgradeStep in _clearable_steps(track):
			if step.stat_name == UpgradeStep.HEARTS:
				continue
			var stat: Stat = stats.get(step.stat_name) as Stat
			if stat:
				stat.remove_buff_completly(_buff_id(track, step), step.type)

		# Sum per stat + buff type, so different steps hitting the same stat combine into one buff.
		var totals: Dictionary[String, float] = {}
		var first_step: Dictionary[String, UpgradeStep] = {}
		for step: UpgradeStep in _active_steps(track):
			if step.stat_name == UpgradeStep.HEARTS:
				continue
			var key: String = "%s/%d" % [step.stat_name, step.type]
			totals[key] = totals.get(key, 0.0) + step.amount
			if not first_step.has(key):
				first_step[key] = step

		for key: String in totals:
			var step: UpgradeStep = first_step[key]
			var stat: Stat = stats.get(step.stat_name) as Stat
			if stat == null:
				push_warning("MetaProgress: '%s' is not a Stat on PlayerStats" % step.stat_name)
				continue
			stat.add_buff(_buff_id(track, step), totals[key], step.type)

## Safe to call any number of times: removes the abilities it added before, then registers
## fresh copies of every picked ability. Call after Player.activate_passive_abilities().
func apply_abilities(player: Player) -> void:
	for ability: PlayerAbility in _meta_abilities:
		# Only unregister if it's still on this player (a new player may not have it).
		if player.get_abilities(ability.get_type()).has(ability):
			player.unregister_ability(ability)
	_meta_abilities.clear()

	for track: UpgradeTrack in tracks:
		for id: StringName in get_owned_ids(track):
			var reward: MilestoneReward = find_reward(track, id)
			if reward == null or reward.ability == null:
				continue
			var ability: PlayerAbility = reward.ability.duplicate() as PlayerAbility
			player.register_ability(ability)
			_meta_abilities.append(ability)

## Total heart containers granted by upgrades and milestones.
func get_bonus_hearts() -> int:
	var hearts: int = 0
	for track: UpgradeTrack in tracks:
		for step: UpgradeStep in _active_steps(track):
			if step.stat_name == UpgradeStep.HEARTS:
				hearts += int(step.amount)
	return hearts

func _apply_all(player: Player) -> void:
	apply_to(player.stats)
	apply_abilities(player)
	player.refresh_max_hp()

## Every stat step currently earned on a track: cycle steps plus milestone stat steps.
func _active_steps(track: UpgradeTrack) -> Array[UpgradeStep]:
	var result: Array[UpgradeStep] = track.steps_up_to(get_level(track))
	result.append_array(_milestone_steps(track))
	return result

func _milestone_steps(track: UpgradeTrack) -> Array[UpgradeStep]:
	var result: Array[UpgradeStep] = []
	for id: StringName in get_picks(track):
		if id == FALLBACK_ID:
			if track.milestone_fallback_step:
				result.append(track.milestone_fallback_step)
			continue
		var reward: MilestoneReward = find_reward(track, id)
		if reward and reward.stat_step:
			result.append(reward.stat_step)
	return result

## Every step a track could ever apply, so all its buffs can be cleared.
func _clearable_steps(track: UpgradeTrack) -> Array[UpgradeStep]:
	var result: Array[UpgradeStep] = track.all_steps()
	if track.milestone_fallback_step and not result.has(track.milestone_fallback_step):
		result.append(track.milestone_fallback_step)
	for reward: MilestoneReward in track.milestone_pool:
		if reward.stat_step and not result.has(reward.stat_step):
			result.append(reward.stat_step)
	return result

func _buff_id(track: UpgradeTrack, step: UpgradeStep) -> int:
	return ("meta/%s/%s/%d" % [track.id, step.stat_name, step.type]).hash()

# --- Milestones -----------------------------------------------------------

func get_picks(track: UpgradeTrack) -> Array:
	return picks.get(track.id, [])

## Picked reward ids, without fallback markers.
func get_owned_ids(track: UpgradeTrack) -> Array[StringName]:
	var owned: Array[StringName] = []
	for id: StringName in get_picks(track):
		if id != FALLBACK_ID:
			owned.append(id)
	return owned

func has_pending(track: UpgradeTrack) -> bool:
	return not pending.get(track.id, []).is_empty()

func get_pending_offers(track: UpgradeTrack) -> Array[MilestoneReward]:
	var result: Array[MilestoneReward] = []
	for id: StringName in pending.get(track.id, []):
		var reward: MilestoneReward = find_reward(track, id)
		if reward:
			result.append(reward)
	return result

func find_reward(track: UpgradeTrack, id: StringName) -> MilestoneReward:
	for reward: MilestoneReward in track.milestone_pool:
		if reward.id == id:
			return reward
	return null

## Called by the pick window. Returns false if that reward isn't on offer.
func choose(track: UpgradeTrack, reward_id: StringName, player: Player) -> bool:
	if not pending.get(track.id, []).has(reward_id):
		return false
	pending.erase(track.id)
	_add_pick(track, reward_id)
	_resolve_milestones(track)
	_apply_all(player)
	SaveService.save_game()
	levels_changed.emit()
	return true

## Gives every reached milestone a pick. Stops when a choice is waiting on the player.
## 1 offer = granted directly (linear path), more = saved as pending for the pick window.
func _resolve_milestones(track: UpgradeTrack) -> void:
	if track.milestone_every <= 0:
		return
	@warning_ignore("integer_division")
	var reached: int = get_level(track) / track.milestone_every
	while get_picks(track).size() < reached and not has_pending(track):
		var offers: Array[MilestoneReward] = track.roll_offers(get_owned_ids(track))
		if offers.is_empty():
			_add_pick(track, FALLBACK_ID)
		elif offers.size() == 1:
			_add_pick(track, offers[0].id)
		else:
			var ids: Array = []
			for reward: MilestoneReward in offers:
				ids.append(reward.id)
			pending[track.id] = ids
			milestone_offers_ready.emit(track)

func _add_pick(track: UpgradeTrack, id: StringName) -> void:
	if not picks.has(track.id):
		picks[track.id] = []
	picks[track.id].append(id)

func _find_track(id: StringName) -> UpgradeTrack:
	for track: UpgradeTrack in tracks:
		if track.id == id:
			return track
	return null

# --- Constructs -----------------------------------------------------------

func is_built(id: StringName) -> bool:
	return built.has(id)

func can_pay(cost: Dictionary[CustomVariables.items, int], stats: PlayerStats) -> bool:
	for item: CustomVariables.items in cost:
		if stats.items.get(item, 0) < cost[item]:
			return false
	return true

## Pays and marks the construct as built. Returns false if already built or unaffordable.
func build(id: StringName, cost: Dictionary[CustomVariables.items, int], player: Player) -> bool:
	if is_built(id) or not can_pay(cost, player.stats):
		return false
	for item: CustomVariables.items in cost:
		player.buy(cost[item], item)
	built.append(id)
	SaveService.save_game()
	construct_built.emit(id)
	return true

# --- Spirit boons -----------------------------------------------------------

## The 3 boons on offer, rolled without repeats the first time they're asked for.
func get_boon_offers() -> Array[SpiritBoon]:
	if boon_offers.is_empty():
		var pool: Array[SpiritBoon] = boon_pool.duplicate()
		pool.shuffle()
		for boon: SpiritBoon in pool.slice(0, BOONS_OFFERED):
			boon_offers.append(boon.id)
		SaveService.save_game()
	var offers: Array[SpiritBoon] = []
	for id: StringName in boon_offers:
		var boon: SpiritBoon = find_boon(id)
		if boon:
			offers.append(boon)
	return offers

func find_boon(id: StringName) -> SpiritBoon:
	for boon: SpiritBoon in boon_pool:
		if boon.id == id:
			return boon
	return null

## Picks one of the offered boons for the next run.
func choose_boon(id: StringName) -> bool:
	if not boon_offer_pending or not boon_offers.has(id):
		return false
	chosen_boon = id
	boon_offer_pending = false
	boon_offers.clear()
	SaveService.save_game()
	boon_state_changed.emit()
	return true

## The spirit told the player its next tip.
func mark_tip_heard() -> void:
	tips_heard += 1
	SaveService.save_game()
	boon_state_changed.emit()

func _on_event_bus_player_died(death_screen: bool) -> void:
	_remove_applied_boon()
	# No death screen = practice death (tutorial), which doesn't count as a run.
	if not death_screen:
		return
	run_deaths += 1
	_offer_boon()

func _offer_boon() -> void:
	_run_in_progress = false
	boon_offer_pending = true
	boon_offers.clear()
	boon_state_changed.emit()

## The first rift of a run uses up the chosen boon.
func _on_event_bus_entered_rift() -> void:
	_run_in_progress = true
	if _applied_boon != null or chosen_boon == &"":
		return
	var boon: SpiritBoon = find_boon(chosen_boon)
	chosen_boon = &""
	boon_state_changed.emit()
	var player: Player = PlayerManager.player
	if boon == null or player == null:
		return
	boon.apply(player, _boon_buff_id)
	_applied_boon = boon

## Back in the hub after a run that didn't end in death (won, or left through a portal).
func _on_event_bus_in_main_menu() -> void:
	_remove_applied_boon()
	if _run_in_progress:
		_offer_boon()

func _remove_applied_boon() -> void:
	if _applied_boon == null:
		return
	if PlayerManager.player:
		_applied_boon.remove(PlayerManager.player, _boon_buff_id)
	_applied_boon = null

# --- Save / load ----------------------------------------------------------

func _save() -> Dictionary:
	var levels_out: Dictionary = {}
	for id: StringName in levels:
		levels_out[String(id)] = levels[id]
	var built_out: Array[String] = []
	for id: StringName in built:
		built_out.append(String(id))
	return {
		"levels": levels_out,
		"built": built_out,
		"picks": _ids_to_save(picks),
		"pending": _ids_to_save(pending),
		"boon_offer_pending": boon_offer_pending,
		"boon_offers": boon_offers.map(func(id: StringName) -> String: return String(id)),
		"chosen_boon": String(chosen_boon),
		"run_deaths": run_deaths,
		"tips_heard": tips_heard,
	}

func _load(data: Dictionary) -> void:
	levels.clear()
	var saved_levels: Dictionary = data.get("levels", {})
	for key: String in saved_levels:
		levels[StringName(key)] = int(saved_levels[key])
	built.clear()
	for id: Variant in data.get("built", []):
		built.append(StringName(str(id)))
	picks = _ids_from_save(data.get("picks", {}), true)
	pending = _ids_from_save(data.get("pending", {}), false)
	boon_offer_pending = bool(data.get("boon_offer_pending", false))
	boon_offers.clear()
	for id: Variant in data.get("boon_offers", []):
		if find_boon(StringName(str(id))):
			boon_offers.append(StringName(str(id)))
	chosen_boon = StringName(str(data.get("chosen_boon", "")))
	run_deaths = int(data.get("run_deaths", 0))
	tips_heard = int(data.get("tips_heard", 0))
	boon_state_changed.emit()
	# Backfills milestones reached before rewards existed, or whose reward was deleted.
	for track: UpgradeTrack in tracks:
		_resolve_milestones(track)
	levels_changed.emit()

func _ids_to_save(source: Dictionary[StringName, Array]) -> Dictionary:
	var out: Dictionary = {}
	for track_id: StringName in source:
		var ids: Array[String] = []
		for id: StringName in source[track_id]:
			ids.append(String(id))
		out[String(track_id)] = ids
	return out

## Unknown tracks and reward ids are skipped, so deleting a reward never breaks a save.
func _ids_from_save(saved: Dictionary, allow_fallback: bool) -> Dictionary[StringName, Array]:
	var result: Dictionary[StringName, Array] = {}
	for key: String in saved:
		var track: UpgradeTrack = _find_track(StringName(key))
		if track == null:
			continue
		var ids: Array = []
		for raw: Variant in saved[key]:
			var id: StringName = StringName(str(raw))
			if (allow_fallback and id == FALLBACK_ID) or find_reward(track, id) != null:
				ids.append(id)
			else:
				push_warning("MetaProgress: unknown milestone reward '%s' on track '%s'" % [id, key])
		if not ids.is_empty():
			result[track.id] = ids
	return result
## The reward the next milestone will grant, if it's known in advance (linear path).
## Null in choose mode (offers are random) or when the pool is used up.
func get_next_milestone_reward(track: UpgradeTrack) -> MilestoneReward:
	if track.offers_per_milestone > 1:
		return null
	var offers: Array[MilestoneReward] = track.roll_offers(get_owned_ids(track))
	if offers.is_empty():
		return null
	return offers[0]
