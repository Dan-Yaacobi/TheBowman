class_name OpportunistAbility extends PlayerAbility
## Power milestone. Your hits deal bonus damage to enemies that have any debuff.

## 0.25 = +25% damage.
@export var bonus_damage: float = 0.25

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var enemy: Enemy = _target as Enemy
	var hurt_box: HurtBox = _activator as HurtBox
	if enemy == null or hurt_box == null or enemy.debuff_handler.debuffs.is_empty():
		return
	MinorHitHelpers.add_damage_for_hit(hurt_box, bonus_damage)

func get_tooltip() -> String:
	return "+%d%% damage against debuffed enemies" % roundi(bonus_damage * 100.0)

func get_type() -> TriggerType:
	return TriggerType.BEFORE_HIT
