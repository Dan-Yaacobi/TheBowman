class_name PlayerStats extends Resource

var player: Player

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
@export var reset_upgrades: bool = false
@export var max_minions: int 



@export_category("Player Items")
@export var money: int
@export var upgrd_points: int
@export var weapon_name: String
@export var weapon_scene: PackedScene



@export_category("Abilities")
@export var jump_abilities: Array[JumpAbility]
@export var shoot_abilities: Array[ShootAbility]
@export var arrow_abilities: Array[ArrowAbility]
@export var slam_abilities: Array[SlamAbility]



@export_category("Upgrade values")
@export var can_mega_shot: bool = false
@export var crit_chance: int = 10
@export var stun_chance: int = 10
@export var leech_chance: int = 10


func add_jump_ability(ability: JumpAbility) -> void:
	if ability != null:
		jump_abilities.append(ability)

func add_arrow_ability(ability: ArrowAbility) -> void:
	if ability != null:
		arrow_abilities.append(ability)
	
func add_shoot_ability(ability: ShootAbility) -> void:
	if ability != null:
		shoot_abilities.append(ability)
