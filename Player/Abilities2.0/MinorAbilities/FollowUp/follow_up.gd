class_name FollowUpMinor extends MinorAbility
## Enemies take +value% damage while still flying back from a knockback.

## Knockback speed that counts as "still flying back" (never below the enemy's own knockback threshold).
@export var min_flying_speed: float = 30.0

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var enemy: Enemy = _target as Enemy
	var hurt_box: HurtBox = _activator as HurtBox
	if enemy == null or hurt_box == null:
		return
	if enemy.knockback_velocity.length() > maxf(min_flying_speed, enemy.stats.knockback_threshold):
		MinorHitHelpers.add_damage_for_hit(hurt_box, value / 100.0 * power())

func get_tooltip() -> String:
	return "Enemies take +%d%% damage while knocked back" % roundi(value * power())

func get_type() -> TriggerType:
	return TriggerType.BEFORE_HIT

func get_tooltip_color() -> Color:
	return Color.LIGHT_SALMON
