class_name EnemyData extends Resource

@export_category("Stats")
@export var hp: int
@export var move_speed: int
@export var knockback: int
@export var skin: Texture
@export var coins_dropped: int
@export var sharp_movement: bool
@export var touch_damage: int

@export_category("Abilities")
@export var death_ability: Array[EnemyAbility]
@export var initial_ability: Array[EnemyAbility]
@export var special_ability: Array[EnemyAbility]
@export var debuffs: Array[EnemyEffect]

@export var enemy_scene: PackedScene
@export var boss: bool = false
@export var shooter: bool = false
@export var shooter_chance: int = 0
@export var bullet: PackedScene
@export var shoot_speed: float
