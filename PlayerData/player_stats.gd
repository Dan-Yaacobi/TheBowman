class_name PlayerStats extends Resource

@export_category("Player Stats")
@export var hp: int
@export var max_hp: int
@export var move_speed: int
@export var max_jumps: int
@export var jump_height: int
@export var knockback_resistance: int
@export var menu_speed: int
@export var in_menu: bool
@export var mana_rate: float
@export var shoot_cost: int

@export_category("Player Items")
@export var money: int
@export var weapon_name: String
@export var weapon_scene: PackedScene

@export_category("Abilities")
@export var jump_abilities: Array[JumpAbility]
@export var shoot_abilities: Array[ShootAbility]
@export var special_ability: SpecialAbility
