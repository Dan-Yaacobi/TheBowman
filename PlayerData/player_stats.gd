class_name PlayerStats extends Resource

var player: Player

@export_subgroup("Basic Stats")
@export var hp: int
@export var max_hp: int
@export var knockback_resistance: Stat
@export var reset_upgrades: bool = false
@export var max_minions: int 
@export var invinc_duration: Stat
@export var extra_gold: Stat
@export var extra_drop_chance: Stat

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
@export var shot_streak: int = 0
@export var perfect_shot_streak: int = 0
@export var can_pass_walls: bool = false
@export var crit_chance: Stat
@export var crit_modifier: Stat
@export var arrow_size: Stat

@export_subgroup("Special")
@export var stun_duration: float = 2.0
@export var bleed_damage: int = 1
@export var bleed_duration: float = 2.0
@export var burn_damage: int = 1
@export var burn_duration: float = 2.0
@export var poison_damage: int = 1
@export var poison_duration: float = 2.0

@export_subgroup("Player Items")
@export var money: int
@export var weapon_scene: PackedScene
@export var arrow: EquipmentData
@export var arrow_scene: PackedScene
@export var ring: EquipmentData
@export var bow: EquipmentData

@export_subgroup("Abilities")
@export var jump_abilities: Array[PlayerAbility]
@export var dash_abilities: Array[PlayerAbility]
@export var shooting_abilities: Array[PlayerAbility]
@export var sword_abilities: Array[PlayerAbility]
@export var passive_abilities: Array[PlayerAbility]
@export var release_abilities: Array[PlayerAbility]
@export var active_ability: ActiveAbility


@export_subgroup("Sword")
@export var sword_size: Stat
@export var base_sword_cooldown: Stat
@export var sword_damage: Stat

@export_subgroup("Rift")
@export var rift_level: int = 1


static var DISPLAY_STATS: Array = [
	["Movement", "Move Speed", "move_speed"],
	["Movement", "Max Jumps", "max_jumps"],
	["Movement", "Dash Power", "dash_power"],
	["Shooting", "Arrow Damage", "arrow_damage"],
	["Shooting", "Arrow Speed", "arrow_speed"],
	["Shooting", "Pull Speed", "pull_speed"],
	["Shooting", "Arrow Count", "arrow_count"],
	["Shooting", "Arrow Pierce", "arrow_pierce"],
	["Shooting", "Perfect Window", "perfect_shot_window"],
	["Shooting", "Perfect Bonus", "perfect_shot_bonus"],
	["Shooting", "Crit Chance", "crit_chance"],
	["Defense", "Max HP", "max_hp"],
	["Defense", "Knockback Resist", "knockback_resistance"],
	["Sword", "Sword Damage", "sword_damage"],
	["Sword", "Sword Cooldown", "base_sword_cooldown"],
]

static var ABILITY_GROUPS: Array = [
	["Jump", "jump_abilities"],
	["Dash", "dash_abilities"],
	["Shoot", "shooting_abilities"],
	["Release", "release_abilities"],
	["Sword", "sword_abilities"],
	["Passive", "passive_abilities"],
]
