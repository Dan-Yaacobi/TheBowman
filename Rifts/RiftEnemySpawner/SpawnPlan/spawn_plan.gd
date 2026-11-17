class_name SpawnPlan extends Resource
## A hand-made pacing curve for one rift: how many spawned enemies should be alive after the
## player enters a new chunk. X = rift progress (0 = first new chunk, 1 = the main path's length
## in new chunks, held at 1 after that). Y = target enemies alive.

@export var display_name: String = ""
@export var curve: Curve


## Target enemies alive at this progress (0-1), rounded to a whole enemy.
func target_at(progress: float) -> int:
	if curve == null:
		return 0
	return maxi(roundi(curve.sample_baked(clampf(progress, 0.0, 1.0))), 0)
