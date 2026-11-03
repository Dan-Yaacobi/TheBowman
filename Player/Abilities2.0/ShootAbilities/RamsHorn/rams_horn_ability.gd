class_name RamsHornAbility extends PlayerAbility
## An enemy you knock back becomes a projectile: enemies it flies into take damage and get knocked back too.

## Damage of the flying enemy's impact, as a multiplier of the hit that launched it.
@export var impact_damage_mult: float = 1.0
## Knockback of the impact, as a multiplier of the launching hit's knockback.
@export var impact_knockback_mult: float = 0.9
## How many more enemies a struck enemy can knock on (billiard chain length).
@export var max_chain: int = 2
## Each link in the chain keeps this much damage and knockback.
@export var chain_falloff: float = 0.7

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var enemy: Enemy = _target as Enemy
	var hurt_box: HurtBox = _activator as HurtBox
	if enemy == null or hurt_box == null or hurt_box is RamImpact:
		return
	var already_hit: Array[Enemy] = []
	RamImpact.attach(enemy, roundi(hurt_box.damage * impact_damage_mult * power()), hurt_box.knockback_power * impact_knockback_mult, max_chain, chain_falloff, already_hit)

func get_tooltip() -> String:
	return "Knocked-back enemies smash into other enemies"

func get_tooltip_color() -> Color:
	return Color.BURLYWOOD

func get_type() -> TriggerType:
	return TriggerType.AFTER_HIT
