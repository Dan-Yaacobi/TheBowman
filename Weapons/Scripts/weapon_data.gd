class_name WeaponData extends Resource

@export var sprite_frame: int
@export var special_ability: SpecialAbility
@export var mana_rate: float
@export var shoot_cost: int
@export var arrow: PackedScene
@export var special_ability_cooldown: float
@export var spcl_ablty_cost_mltplr: int
@export var combo_buff_activated: bool = false
@export var shots: int = 1
@export var damage: int = 0


@export_category("Special Abilities")
@export var can_pierce: bool = false
@export var arrows_explode: bool = false

@export var crit_arrows: bool = false
@export var crit_chance: int = 10

@export var can_stun: bool = false
@export var stun_chance: int = 10

@export var can_leech: bool = false
@export var leech_chance: int = 10
