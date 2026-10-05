class_name UpgradeTrack extends Resource
## One upgradable track in the altar menu (Power, Mobility, Blade, Max HP...).
## Regular levels walk through `cycle` in order and repeat it forever.
## Every `milestone_every`-th level is a milestone instead (Skyshard cost, ability pick).

@export var id: StringName
@export var display_name: String
@export var icon: Texture2D

## The repeating pattern of stat bumps, e.g. [+1 dmg, +5% crit, +1 dmg, +25% crit dmg].
@export var cycle: Array[UpgradeStep] = []
## Used in place of any cycle step that has hit its max_applications.
@export var fallback_step: UpgradeStep
## 0 = endless.
@export var max_level: int = 0

@export_group("Cost")
## Cost of the first level. Every level after multiplies it by cost_growth.
@export var base_cost: Dictionary[CustomVariables.items, int] = {}
@export var cost_growth: float = 1.15

@export_group("Milestones")
## 0 = no milestones (e.g. Max HP).
@export var milestone_every: int = 5
## Cost of the first milestone. Every milestone after multiplies it by milestone_cost_growth.
@export var milestone_cost: Dictionary[CustomVariables.items, int] = {}
@export var milestone_cost_growth: float = 1.5

func is_maxed(level: int) -> bool:
	return max_level > 0 and level >= max_level

func is_milestone(level: int) -> bool:
	return milestone_every > 0 and level > 0 and level % milestone_every == 0

## Cost to go from current_level to current_level + 1.
func get_cost(current_level: int) -> Dictionary[CustomVariables.items, int]:
	var next_level: int = current_level + 1
	var result: Dictionary[CustomVariables.items, int] = {}
	if is_milestone(next_level):
		var milestone_index: int = next_level / milestone_every - 1
		var mult: float = pow(milestone_cost_growth, milestone_index)
		for item: CustomVariables.items in milestone_cost:
			result[item] = maxi(1, roundi(milestone_cost[item] * mult))
	else:
		var regular_index: int = current_level - _milestones_up_to(current_level)
		var mult: float = pow(cost_growth, regular_index)
		for item: CustomVariables.items in base_cost:
			result[item] = maxi(1, roundi(base_cost[item] * mult))
	return result

## Every stat step applied from level 1 up to `level`, in order (milestones skipped, caps respected).
func steps_up_to(level: int) -> Array[UpgradeStep]:
	var applied: Array[UpgradeStep] = []
	if cycle.is_empty():
		return applied
	var counts: Dictionary[UpgradeStep, int] = {}
	var regular_index: int = 0
	for lvl: int in range(1, level + 1):
		if is_milestone(lvl):
			continue
		var step: UpgradeStep = _resolve_step(cycle[regular_index % cycle.size()], counts)
		regular_index += 1
		if step == null:
			continue
		counts[step] = counts.get(step, 0) + 1
		applied.append(step)
	return applied

## The step the next purchase will give, or null if the next level is a milestone or maxed.
func get_next_step(current_level: int) -> UpgradeStep:
	var next_level: int = current_level + 1
	if is_maxed(current_level) or is_milestone(next_level) or cycle.is_empty():
		return null
	var counts: Dictionary[UpgradeStep, int] = {}
	for step: UpgradeStep in steps_up_to(current_level):
		counts[step] = counts.get(step, 0) + 1
	var regular_index: int = current_level - _milestones_up_to(current_level)
	return _resolve_step(cycle[regular_index % cycle.size()], counts)

## Every step this track can ever apply (used to clear its buffs).
func all_steps() -> Array[UpgradeStep]:
	var result: Array[UpgradeStep] = cycle.duplicate()
	if fallback_step and not result.has(fallback_step):
		result.append(fallback_step)
	return result

func _resolve_step(step: UpgradeStep, counts: Dictionary[UpgradeStep, int]) -> UpgradeStep:
	if step.max_applications > 0 and counts.get(step, 0) >= step.max_applications:
		return fallback_step
	return step

func _milestones_up_to(level: int) -> int:
	if milestone_every <= 0:
		return 0
	return level / milestone_every
