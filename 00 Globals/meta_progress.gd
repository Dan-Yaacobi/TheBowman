extends Node
## Autoload as "MetaProgress" (as a scene, so `tracks` can be filled in the inspector).
## Owns permanent upgrade levels, buys levels, and applies the bonuses to PlayerStats.

signal levels_changed

signal construct_built(id: StringName)


const SAVE_SECTION: StringName = &"meta"

var tracks: Array[UpgradeTrack] = [
	preload("res://Objects/Constructs/UpgradeAltar/Resources/power_track.tres"),
	preload("res://Objects/Constructs/UpgradeAltar/Resources/sword_track.tres"),
	preload("res://Objects/Constructs/UpgradeAltar/Resources/hp_track.tres")

]
var levels: Dictionary[StringName, int] = {}

var built: Array[StringName] = []

func _ready() -> void:
	SaveService.register(SAVE_SECTION, _save, _load)

func get_level(track: UpgradeTrack) -> int:
	return levels.get(track.id, 0)

func get_cost(track: UpgradeTrack) -> Dictionary[CustomVariables.items, int]:
	return track.get_cost(get_level(track))

func can_afford(track: UpgradeTrack, stats: PlayerStats) -> bool:
	if track.is_maxed(get_level(track)):
		return false
	var cost: Dictionary[CustomVariables.items, int] = get_cost(track)
	for item: CustomVariables.items in cost:
		if stats.items.get(item, 0) < cost[item]:
			return false
	return true

## Buys one level. Returns false if it can't be afforded or the track is maxed.
func purchase(track: UpgradeTrack, player: Player) -> bool:
	if not can_afford(track, player.stats):
		return false
	var cost: Dictionary[CustomVariables.items, int] = get_cost(track)
	for item: CustomVariables.items in cost:
		player.buy(cost[item], item)
	levels[track.id] = get_level(track) + 1
	apply_to(player.stats)
	player.refresh_max_hp()
	SaveService.save_game()
	levels_changed.emit()
	return true

## Safe to call any number of times: clears every meta buff, then re-adds the current totals.
## Call from Player._ready() and after purchases (purchase() already does).
func apply_to(stats: PlayerStats) -> void:
	for track: UpgradeTrack in tracks:
		for step: UpgradeStep in track.all_steps():
			if step.stat_name == UpgradeStep.HEARTS:
				continue
			var stat: Stat = stats.get(step.stat_name) as Stat
			if stat:
				stat.remove_buff_completly(_buff_id(track, step), step.type)

		# Sum per stat + buff type, so different steps hitting the same stat combine into one buff.
		var totals: Dictionary[String, float] = {}
		var first_step: Dictionary[String, UpgradeStep] = {}
		for step: UpgradeStep in track.steps_up_to(get_level(track)):
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

## Total heart containers granted by upgrades.
func get_bonus_hearts() -> int:
	var hearts: int = 0
	for track: UpgradeTrack in tracks:
		for step: UpgradeStep in track.steps_up_to(get_level(track)):
			if step.stat_name == UpgradeStep.HEARTS:
				hearts += int(step.amount)
	return hearts

func _buff_id(track: UpgradeTrack, step: UpgradeStep) -> int:
	return ("meta/%s/%s/%d" % [track.id, step.stat_name, step.type]).hash()
	
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
	
func _save() -> Dictionary:
	var out: Dictionary = {}
	for id: StringName in levels:
		out[String(id)] = levels[id]
	var built_out: Array[String] = []
	for id: StringName in built:
		built_out.append(String(id))
	return {"levels": out, "built": built_out}

func _load(data: Dictionary) -> void:
	levels.clear()
	var saved: Dictionary = data.get("levels", {})
	for key: String in saved:
		levels[StringName(key)] = int(saved[key])
	built.clear()
	for id: Variant in data.get("built", []):
		built.append(StringName(str(id)))
	levels_changed.emit()
