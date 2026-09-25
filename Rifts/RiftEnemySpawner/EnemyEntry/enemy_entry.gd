class_name EnemyEntry extends Resource

@export var scene: PackedScene
@export var data: EnemyData
## Pressure units. For elites, the target pressure must reach this before it can spawn
@export var cost: int = 1
## Elites only spawn on an empty field and block all other spawns while alive
@export var is_elite: bool = false
@export var min_level: int = 1
## -1 = no upper cap
@export var max_level: int = -1
## Enemy only spawns when the current intensity is at or above this
@export_range(0.0, 1.0) var min_intensity: float = 0.0
@export var base_weight: float = 10.0
@export var spawn_zone: SpawnHandler.Zone = SpawnHandler.Zone.ANY


func is_eligible(level: int, intensity: float) -> bool:
	if level < min_level:
		return false
	if max_level >= 0 and level > max_level:
		return false
	return intensity >= min_intensity


func get_factory() -> Callable:
	return func() -> Enemy:
		var node: Enemy = scene.instantiate()
		node.set_data(data)
		return node
