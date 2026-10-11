extends Node
## Autoload as "MetaProgress" (as a scene, so `tracks` can be filled in the inspector).
## Owns permanent upgrade levels, milestone picks and built constructs,
## and applies the bonuses to PlayerStats and the player.

signal levels_changed
signal construct_built(id: StringName)
signal milestone_offers_ready(track: UpgradeTrack)

const SAVE_SECTION: StringName = &"meta"
## Marks a milestone that granted the track's fallback step (pool was empty).
const FALLBACK_ID: StringName = &"__fallback"

var tracks: Array[UpgradeTrack] = [
	preload("res://Objects/Constructs/UpgradeAltar/Resources/power_track.tres"),
	preload("res://Objects/Constructs/UpgradeAltar/Resources/sword_track.tres"),
	preload("res://Objects/Constructs/UpgradeAltar/Resources/hp_track.tres"),
]

var levels: Dictionary[StringName, int] = {}
var built: Array[StringName] = []
## Per track: reward ids picked, in order.
var picks: Dictionary[StringName, Array] = {}
## Per track: reward ids waiting for the player to choose one.
var pending: Dictionary[StringName, Array] = {}
## Ability instances MetaProgress registered on the player, so they can be removed cleanly.
var _meta_abilities: Array[PlayerAbility] = []

func _ready() -> void:
	SaveService.register(SAVE_SECTION, _save, _load)

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
