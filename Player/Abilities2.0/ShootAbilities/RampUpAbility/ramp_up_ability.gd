class_name RampUpAbility extends PlayerShootAbility

@export var id: int = 991
const RAMP_SCALE: float = 0.15

func activate_ability(_target: Node2D = null , _arrow: Arrow = null) -> void:
	if _target and _arrow:
		if _target is Enemy:
			var perfect_shots: int = PlayerManager.player.get_perfect_shot_streak()
			var increase: float = sqrt(float(perfect_shots)) * RAMP_SCALE
			PlayerManager.player.stats.pull_speed.remove_buff_completly(id,Stat.buff_type.ADDITIVE)
			PlayerManager.player.stats.pull_speed.add_buff(id,increase,Stat.buff_type.ADDITIVE)
			
func get_tooltip() -> String:
	return "Each consecutive Perfect Shot increases pull speed. Miss a shot to reset."
