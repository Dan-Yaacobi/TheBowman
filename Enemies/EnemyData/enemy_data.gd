class_name EnemyData extends Resource

@export_subgroup("Stats")
@export var max_hp: int
@export var move_speed: Stat = Stat.new()
@export var knockback: int
@export var skin: Texture
@export var avg_coins_dropped: int
@export var touch_damage: int
@export var knockback_resistance: float = 0.0
@export var can_be_knockedback: bool = true
@export_range(0, 100, 0.1, "suffix:%") var drop_chance: float = 20.0

@export_subgroup("Abilities")
@export var death_ability: Array[EnemyAbility]
@export var initial_ability: Array[EnemyAbility]
@export var special_ability: Array[EnemyAbility]

@export_subgroup("Shooting Stats")
@export var bullet: PackedScene
@export var shot_cooldown: float = 1.0
