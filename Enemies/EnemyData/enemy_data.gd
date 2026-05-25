class_name EnemyData extends Resource

@export_subgroup("Stats")
@export var max_hp: int
@export var move_speed: Stat = Stat.new()
@export var knockback: int
@export var skin: Texture
@export var avg_coins_dropped: int
@export var touch_damage: int
@export var knockback_resistance: float = 0.0
@export var boss: bool = false

@export_subgroup("Abilities")
@export var death_ability: Array[EnemyAbility]
@export var initial_ability: Array[EnemyAbility]
@export var special_ability: Array[EnemyAbility]

@export_subgroup("Shooting Stats")
@export var shooter: bool = false
@export_custom(PROPERTY_HINT_NONE,"suffix:%") var shooter_chance: int = 0
@export var bullet: PackedScene
#func initialize(_hp: int, _speed: int, _knockback: int, _skin: Texture, _avg_coins_dropped: int,
#_touch_dmg: int, _knockback_resistance: float, _boss: bool, _shooter_chance: int,
#_bullet: PackedScene) -> void:
	#hp = _hp
	#move_speed = _speed
	#knockback = _knockback
	#skin = _skin
	#avg_coins_dropped = _avg_coins_dropped
	#touch_damage = _touch_dmg
	#boss = _boss
	#shooter = _shooter_chance
	#knockback_resistance = _knockback_resistance
	#bullet = _bullet
