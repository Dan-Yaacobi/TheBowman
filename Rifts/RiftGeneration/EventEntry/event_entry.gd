class_name EventEntry extends Resource
## One event the rift generator can put behind an event portal.
## Picked by weight; every time it's picked in a run, its weight is multiplied by repeat_penalty.

## The event scene. Leave empty when artifact_catalog is set.
@export var scene: PackedScene
## Artifact event slot: rolls a still-missing artifact event from the current batch.
## Only eligible while that batch has one left to find.
@export var artifact_catalog: ArtifactCatalog
@export var min_level: int = 1
## -1 = no upper cap
@export var max_level: int = -1
@export var base_weight: float = 10.0
## Weight multiplier per previous pick this run (0.5 = half as likely each time).
@export_range(0.0, 1.0) var repeat_penalty: float = 0.5


func is_eligible(level: int) -> bool:
	if level < min_level:
		return false
	if max_level >= 0 and level > max_level:
		return false
	if artifact_catalog != null:
		return artifact_catalog.has_rift_event()
	return scene != null


func get_weight(times_picked: int) -> float:
	return base_weight * pow(repeat_penalty, times_picked)


func get_scene(rng: RandomNumberGenerator) -> PackedScene:
	if artifact_catalog != null:
		return artifact_catalog.roll_event(rng)
	return scene
