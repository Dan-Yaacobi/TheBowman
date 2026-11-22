class_name EncounterSet extends Resource
## A hand-picked group of enemies for a combat rift (e.g. "red apples only", "green + pink
## apples"). They're placed on the layout's spawn markers and wait there for the player.

enum Stage { ANY, EARLY, LATE }

@export var display_name: String = ""
## Biomes this set shows up in. None ticked = every biome.
@export_flags("Dirt", "Snow", "Hell") var biomes: int = 0
## EARLY: first half of an act. LATE: second half.
@export var stage: Stage = Stage.ANY
@export var weight: float = 10.0
## Enemy entry -> how many.
@export var enemies: Dictionary[EnemyEntry, int] = {}


func fits(biome: int, late: bool) -> bool:
	if biomes != 0 and (biomes & (1 << biome)) == 0:
		return false
	if stage == Stage.EARLY and late:
		return false
	return not (stage == Stage.LATE and not late)


func get_spawn_list() -> Array[EnemyEntry]:
	var list: Array[EnemyEntry] = []
	for entry: EnemyEntry in enemies:
		if entry == null:
			continue
		for i: int in enemies[entry]:
			list.append(entry)
	return list
