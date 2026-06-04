class_name PlayerStats extends Resource

var player: Player

@export_subgroup("Basic Stats")
@export var hp: int
@export var max_hp: int
@export var knockback_resistance: Stat
@export var reset_upgrades: bool = false
@export var max_minions: int 
@export var invinc_duration: Stat
@export var extra_gold: int = 0

@export_subgroup("Enviorments")
@export var down_gravity: int
@export var up_gravity: int
@export var max_down_gravity: int
@export var ground_dec: int
@export var ground_acc: int
@export var air_dec: int
@export var air_acc: int

@export_subgroup("Movement")
@export var dash_power: Stat
@export var move_speed: Stat
@export var max_jumps: int
@export var jump_height: Stat

@export_subgroup("Shooting")
@export var basic_shot_power: float
@export var max_pull_strength: float
@export var perfect_shot_window: Stat
@export var perfect_shot_bonus: Stat
@export var arrow_damage: Stat
@export var arrow_speed: Stat
@export var arrow_count: Stat
@export var arrow_pierce: Stat
@export var pull_speed: Stat
@export var pushback_power: Stat
@export var arrow_weight: Stat

@export_subgroup("Player Items")
@export var money: int
@export var weapon_scene: PackedScene
@export var arrow: EquipmentData
@export var arrow_scene: PackedScene
@export var ring: EquipmentData
@export var bow: EquipmentData

@export_subgroup("Abilities")
@export var jump_abilities: Array[PlayerJumpAbility]
@export var dash_abilities: Array[PlayerDashAbility]
@export var shooting_abilities: Array[PlayerShootAbility]
@export var sword_abilities: Array[PlayerSwordAbility]
@export var passive_abilities: Array[PlayerPassiveAbility]

@export_subgroup("Sword")
@export var sword_size: Stat
@export var base_sword_cooldown: Stat
@export var sword_damage: Stat

@export_subgroup("Rift")
@export var rift_level: int = 1
