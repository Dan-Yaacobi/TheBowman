class_name DebuffKnockbackMinor extends MinorAbility
## Enemies with a debuff take +value% knockback.

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var enemy: Enemy = _target as Enemy
	var hurt_box: HurtBox = _activator as HurtBox
	if enemy == null or hurt_box == null or enemy.debuff_handler.debuffs.is_empty():
		return
	MinorHitHelpers.scale_knockback_for_hit(hurt_box, 1.0 + value / 100.0 * power())

func get_tooltip() -> String:
	return "Debuffed enemies take +%d%% knockback" % roundi(value * power())

func get_type() -> TriggerType:
	return TriggerType.BEFORE_HIT

func get_tooltip_color() -> Color:
	return Color.PLUM
