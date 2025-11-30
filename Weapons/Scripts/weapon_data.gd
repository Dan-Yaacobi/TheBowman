class_name WeaponData extends Resource

@export_subgroup("Display")
@export var bow_name: String
@export var text_color: Color
@export var string_color: Color
@export var string_thickness: float
@export var sprite: Texture
@export var arrow: PackedScene
@export var bow_position: Vector2

@export_subgroup("Stats")
@export var special_ability: SpecialAbility
@export var special_ability_cooldown: float
@export var spcl_ablty_cost_mltplr: int
@export var combo_buff_activated: bool = false
@export var shots: int = 1

@export_subgroup("Special Abilities")
@export var can_pierce: bool = false
@export var arrows_explode: bool = false

@export var crit_arrows: bool = false
@export var crit_chance: int = 10

@export var can_stun: bool = false
@export var stun_chance: int = 10

@export var can_leech: bool = false
@export var leech_chance: int = 10
