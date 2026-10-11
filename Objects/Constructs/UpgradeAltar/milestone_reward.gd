class_name MilestoneReward extends Resource
## One entry in a track's milestone pool. Grants either an ability or a stat step.

## Fixed id used for saving. Never change it once players have saves.
@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var icon: Texture2D

@export_group("Grants")
## Set one of these. If both are set, both are granted.
@export var ability: PlayerAbility
@export var stat_step: UpgradeStep

@export_group("Requirements")
## Only offered once the reward with this id is owned (e.g. "shockwave" for "shockwave_doubled").
@export var requires: StringName = &""

func is_available(owned_ids: Array[StringName]) -> bool:
	if owned_ids.has(id):
		return false
	if requires != &"" and not owned_ids.has(requires):
		return false
	return true
