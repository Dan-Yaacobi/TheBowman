class_name EnemyEntry extends Resource

@export var scene: PackedScene
@export var data: EnemyData
@export var cost: int = 1
## Biomes this enemy appears in. None ticked = every biome.
@export_flags("Dirt", "Snow", "Hell") var biomes: int = 0
## First rift of each of those biomes it can appear in (1 = from the biome's first rift).
## Positions follow RIFTS_PER_TYPE, so changing rifts per biome needs no re-tuning.
@export var from_biome_rift: int = 1
## Last rift of the biome it can appear in. -1 = to the end of the biome.
@export var until_biome_rift: int = -1
## Enemy only spawns when the current intensity is at or above this
@export_range(0.0, 1.0) var min_intensity: float = 0.0
@export var base_weight: float = 10.0
@export var spawn_zone: SpawnHandler.Zone = SpawnHandler.Zone.ANY


func is_eligible(level: int, intensity: float) -> bool:
	return appears_at(level) and intensity >= min_intensity

## True if this enemy belongs to the biome and biome position of this rift level.
func appears_at(level: int) -> bool:
	var biome: int = CustomVariables.biome_index(level)
	if biomes != 0 and (biomes & (1 << biome)) == 0:
		return false
	var position: int = CustomVariables.rift_in_biome(level)
	if position < from_biome_rift:
		return false
	return until_biome_rift < 0 or position <= until_biome_rift

## The first rift level of a run this enemy can appear at (challenge shrine roster unlocks).
func first_rift_level() -> int:
	var start: int = clampi(from_biome_rift, 1, CustomVariables.RIFTS_PER_TYPE)
	for biome: int in CustomVariables.BIOME_COUNT:
		if biomes == 0 or (biomes & (1 << biome)) != 0:
			return biome * CustomVariables.RIFTS_PER_TYPE + start
	return start


func get_factory() -> Callable:
	return func() -> Enemy:
		var node: Enemy = scene.instantiate()
		node.set_data(data)
		return node
