class_name PlayerStats extends Resource

var player: Player

@export_subgroup("Basic Stats")
@export var hp: int
@export var max_hp: int
@export var extra_hp: int = 0
@export var knockback_resistance: Stat
@export var max_minions: int 
@export var invinc_duration: Stat
@export var extra_gold: Stat
@export var extra_drop_chance: Stat
@export var can_knockback: int = 0 #if number is higher than 0 you cannot knockback

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
@export var dash_cooldown: Stat
## Dashes available before the cooldown has to run out (Second Dash adds one).
@export var max_dashes: int = 1
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
@export var only_perfect: bool = false
@export var always_max_velocity: bool = false

@export_subgroup("Special")
@export var stun_duration: Stat
@export var bleed_damage: Stat
@export var bleed_duration: Stat
@export var bleed_ticks: Stat
@export var burn_damage: Stat
@export var burn_duration: Stat
@export var burn_ticks: Stat
@export var poison_damage: Stat
@export var poison_duration: Stat
@export var poison_ticks: Stat
@export var frostbite_duration: Stat
@export var freeze_duration: Stat
@export var arrow_texture_override: Texture2D
@export var arrow_visual_effects: Array[ArrowEffect]
@export var hurricane_duration: Stat

@export_subgroup("Player Items")
@export var items: Dictionary[CustomVariables.items,int]
@export var weapon_scene: PackedScene
@export var arrow: EquipmentData
@export var arrow_scene: PackedScene
@export var ring: EquipmentData
@export var bow: EquipmentData

@export_subgroup("Abilities")
@export var jump_abilities: Array[PlayerAbility]
@export var dash_abilities: Array[PlayerAbility]
@export var shooting_abilities: Array[PlayerShootAbility]
@export var sword_abilities: Array[PlayerAbility]
@export var passive_abilities: Array[PlayerPassiveAbility]
@export var release_abilities: Array[PlayerAbility]
@export var draw_abilities: Array[PlayerAbility]
@export var active_ability: ActiveAbility
@export var before_hit_abilities: Array[PlayerAbility]
@export var after_hit_abilities: Array[PlayerAbility]

@export_subgroup("Sword")
@export var sword_size: Stat
@export var base_sword_cooldown: Stat
@export var sword_damage: Stat
@export var extra_sword_knockback: Stat

@export_subgroup("Rift")
@export var rift_level: int = 1


## Stats shown in the equipment menu: everything items (rolls or abilities) can change.
## [group, display name, property]. Groups listed in HIDE_WHEN_ZERO_GROUPS only show non-zero rows.
static var DISPLAY_STATS: Array = [
	["Offense", "Arrow Damage", "arrow_damage"],
	["Offense", "Arrow Count", "arrow_count"],
	["Offense", "Arrow Pierce", "arrow_pierce"],
	["Offense", "Arrow Speed", "arrow_speed"],
	["Offense", "Arrow Size", "arrow_size"],
	["Offense", "Arrow Weight", "arrow_weight"],
	["Offense", "Pushback", "pushback_power"],
	["Offense", "Crit Chance", "crit_chance"],
	["Offense", "Crit Damage", "crit_modifier"],
	["Draw", "Pull Speed", "pull_speed"],
	["Draw", "Perfect Window", "perfect_shot_window"],
	["Draw", "Perfect Bonus", "perfect_shot_bonus"],
	["Defense", "Max HP", "max_hp"],
	["Defense", "Knockback Resist", "knockback_resistance"],
	["Movement", "Move Speed", "move_speed"],
	["Movement", "Max Jumps", "max_jumps"],
	["Movement", "Dash Power", "dash_power"],
	["Movement", "Dash Cooldown", "dash_cooldown"],
	["Effects", "Burn Damage", "burn_damage"],
	["Effects", "Burn Duration", "burn_duration"],
	["Effects", "Bleed Damage", "bleed_damage"],
	["Effects", "Bleed Duration", "bleed_duration"],
	["Effects", "Poison Damage", "poison_damage"],
	["Effects", "Poison Duration", "poison_duration"],
	["Effects", "Stun Duration", "stun_duration"],
	["Effects", "Frostbite Duration", "frostbite_duration"],
	["Effects", "Hurricane Duration", "hurricane_duration"],
	["Sword", "Sword Damage", "sword_damage"],
	["Sword", "Sword Size", "sword_size"],
	["Sword", "Sword Cooldown", "base_sword_cooldown"],
	["Loot", "Drop Chance", "extra_drop_chance"],
]

static var HIDE_WHEN_ZERO_GROUPS: Array[String] = ["Effects"]

static var ABILITY_GROUPS: Array = [
	["Jump", "jump_abilities"],
	["Dash", "dash_abilities"],
	["Shoot", "shooting_abilities"],
	["Release", "release_abilities"],
	["Sword", "sword_abilities"],
	["Passive", "passive_abilities"],
]
