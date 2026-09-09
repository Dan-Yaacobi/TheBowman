class_name EnemyData extends Resource

@export_subgroup("Stats")
@export var max_hp: int
@export var move_speed: Stat = Stat.new()
@export var acceleration: float = 0.0 # set 0 for instant max speed
@export var knockback: int
@export var skin: Texture
@export var texture_scale: Vector2 = Vector2(1,1)
@export var move_animation: String
@export var effects: Array[PackedScene]
@export var avg_coins_dropped: int
@export var touch_damage: int
@export var knockback_threshold: float = 0.2
@export var knockback_decay: float = 0.05
@export var can_be_knockedback: bool = true
@export_range(0, 100, 0.1, "suffix:%") var drop_chance: float = 20.0
@export var stun_immune: bool = false
@export var has_health_bar: bool = true
@export var has_wings: bool = false
@export var facing_player: bool = true
@export var damage_taken_multiplier: Stat
@export var damage_dealt_multiplier: Stat

@export_subgroup("Abilities")
@export var death_ability: Array[EnemyAbility]
@export var initial_ability: Array[EnemyAbility]
@export var special_ability: Array[EnemyAbility]

@export_subgroup("Hit Effects")
@export var hit_effects: Array[EnemyHitEffect] = []

@export_subgroup("Shooting Stats")
@export var shooter: bool
@export var bullet: PackedScene
@export var shot_cooldown: float = 1.0
@export var bullet_speed: float = 0.0
@export var bullet_sprite: Texture2D

@export_subgroup("Seek/Strike Behavior")
@export var hits_required: int = 1
@export var pure_ranged_mode: bool = false
@export var ranged_trigger_distance: float = 150.0

@export_subgroup("Loot")
@export var equip_amount: int = 1
@export var rarity_skew: float = 0.0
