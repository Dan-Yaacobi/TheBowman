class_name AirKillLiftMinor extends MinorAbility
## A kill while airborne gives you a small upward boost. value = lift speed.

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var player: Player = PlayerManager.player
	if _result == null or not _result.killed or player.is_on_floor():
		return
	player.velocity.y = minf(player.velocity.y, 0.0) - value

func get_tooltip() -> String:
	return "Kills in mid-air lift you up"

func get_type() -> TriggerType:
	return TriggerType.AFTER_HIT

func get_tooltip_color() -> Color:
	return Color.LIGHT_CYAN
