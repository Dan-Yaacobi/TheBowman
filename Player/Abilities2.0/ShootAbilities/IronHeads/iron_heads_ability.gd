class_name IronHeadsAbility extends PlayerAbility
## Iron Heads: heavy arrowheads. Your arrows fly slower but hit harder and push harder.
## The damage and knockback bonus scale with the quiver's color level; the slowdown doesn't.

## Arrow speed multiplier (0.6 = 40% slower).
@export var speed_mult: float = 0.6
## Extra damage and knockback (0.35 = +35%).
@export var impact_bonus: float = 0.35

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var arrow: Arrow = _activator as Arrow
	if arrow == null:
		return
	var bonus: float = 1.0 + impact_bonus * power()
	arrow.velocity *= speed_mult
	arrow.damage = maxi(1, roundi(arrow.damage * bonus))
	arrow.knockback *= bonus

func get_tooltip() -> String:
	return "Arrows fly %d%% slower but deal +%d%% damage and knockback" % [roundi((1.0 - speed_mult) * 100.0), roundi(impact_bonus * power() * 100.0)]

func get_tooltip_color() -> Color:
	return Color.LIGHT_STEEL_BLUE

func get_type() -> TriggerType:
	return TriggerType.RELEASE
