class_name EncounterSet extends Resource
## A hand-picked group of enemies for a combat rift, spawned wave by wave
## (e.g. "red apples only", "green + pink apples").

enum Stage { ANY, EARLY, LATE }

@export var display_name: String = ""
## Biomes this set shows up in. None ticked = every biome.
@export_flags("Dirt", "Snow", "Hell") var biomes: int = 0
## EARLY: first half of an act. LATE: second half.
@export var stage: Stage = Stage.ANY
@export var weight: float = 10.0
## Spawned in order; the next wave starts once the current one is nearly cleared.
@export var waves: Array[ChallengeWave] = []


func fits(biome: int, late: bool) -> bool:
	if biomes != 0 and (biomes & (1 << biome)) == 0:
		return false
	if stage == Stage.EARLY and late:
		return false
	return not (stage == Stage.LATE and not late)
