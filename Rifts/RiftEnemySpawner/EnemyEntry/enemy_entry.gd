class_name EnemyEntry extends Resource
@export var scene: PackedScene
@export var data: EnemyData
@export var cost: int = 1
@export var min_level: int = 1
@export var base_weight: float = 10.0
@export var weight_curve: float = 0.0
@export var spawn_zone: SpawnHandler.Zone = SpawnHandler.Zone.ANY

func get_factory() -> Callable:
	return func() -> Enemy:
		var node: Enemy = scene.instantiate()
		node.set_data(data)
		return node
