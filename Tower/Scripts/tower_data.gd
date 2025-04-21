class_name TowerData extends Resource

@export var sprite: Texture
@export var level: int
@export var damage: int
@export_custom(PROPERTY_HINT_NONE,"suffix:seconds") var damage_timer: float = 1.0
@export var range: float = 1
@export var cost_to_upgrade: int
@export var position: Vector2
@export var arrow: PackedScene
