class_name AirShotsMinor extends MinorAbility
## Shots fired in mid-air deal +value% damage.

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var arrow: Arrow = _activator as Arrow
	if arrow == null or PlayerManager.player.is_on_floor():
		return
	arrow.damage = roundi(arrow.damage * (1.0 + value / 100.0 * power()))

func get_tooltip() -> String:
	return "Shots fired in mid-air deal +%d%% damage" % value

func get_type() -> TriggerType:
	return TriggerType.RELEASE

func get_tooltip_color() -> Color:
	return Color.SKY_BLUE
