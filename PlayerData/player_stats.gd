class_name PlayerStats extends Resource

var player: Player

@export_subgroup("Player Stats")
@export var hp: int
@export var move_speed: int
@export var max_jumps: int
@export var jump_height: int
@export var knockback_resistance: int
@export var strength: int
@export var agility: int
@export var stamina: int
@export var menu_speed: int
@export var in_menu: bool
@export var boost_mana_rate: float
@export var reset_upgrades: bool = false
@export var max_minions: int 
@export var dash_distance: int
@export var invinc_duration: int
@export var stat_points: int = 0

@export_subgroup("Combo")
@export var max_combo: int
@export var combo_to_activate: int
@export var combo_duration: float

@export_subgroup("Shooting")
@export var basic_shot_power: float
@export var shoot_cost: int
@export var max_pull_strength: float
@export var shooting_abilities: Array[PlayerShootAbility]
@export var pull_speed: float = 1:
	get:
		return pull_speed
	set(value):
		pull_speed = clamp(value,1,4)

@export_subgroup("Player Items")
@export var money: int
@export var upgrd_points: int
@export var weapon_name: String
@export var weapon_scene: PackedScene
@export var towers: Array[TowerData]


@export_subgroup("Abilities")
@export var jump_abilities: Array[JumpAbility]
@export var shoot_abilities: Array[ShootAbility]
@export var arrow_abilities: Array[ArrowAbility]
@export var slam_abilities: Array[SlamAbility]

@export_subgroup("Sword")
@export var sword_size: float = 1.0
@export var sword_size_mod: float = 0.0
@export var base_sword_cooldown: float = 1.5
@export var sword_cooldown_mod: float = 0.0
@export var sword_abilities: Array[PlayerSwordAbility]

func add_jump_ability(ability: JumpAbility) -> void:
	if ability != null:
		jump_abilities.append(ability)

func add_arrow_ability(ability: ArrowAbility) -> void:
	if ability != null:
		arrow_abilities.append(ability)
	
func add_shoot_ability(ability: ShootAbility) -> void:
	if ability != null:
		shoot_abilities.append(ability)

func add_tower() -> void:
	var new_tower: TowerData = TowerData.new()
	towers.append(new_tower)
