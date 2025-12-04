class_name EnemyData extends Resource

@export_subgroup("Stats")
@export var hp: int
@export var move_speed: int
@export var knockback: int
@export var skin: Texture
@export var coins_dropped: int
@export var touch_damage: int
@export var knockback_resistance: float = 0.0

@export_subgroup("Abilities")
@export var death_ability: Array[EnemyAbility]
@export var initial_ability: Array[EnemyAbility]
@export var special_ability: Array[EnemyAbility]

@export_subgroup("Shooting Stats")
@export var shooter: bool = false
@export_custom(PROPERTY_HINT_NONE,"suffix:%") var shooter_chance: int = 0
@export var bullet: PackedScene
