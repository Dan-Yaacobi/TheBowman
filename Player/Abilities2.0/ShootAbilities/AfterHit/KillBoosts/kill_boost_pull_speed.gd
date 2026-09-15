class_name KillBoostPullSpeed extends AfterHitAbility

const PULL_SPEED_BUFF = preload("uid://baq16kh45t3dw")

@export var pull_speed_increase: float = 0.5

func activate_ability(_target: Node2D = null , _activator: Node2D = null, _result: DamageResult = null) -> void:
	if _target and _target is Enemy and _result and _result.killed:
		var buff: PullSpeedBuff = PULL_SPEED_BUFF.instantiate()
		buff.amount = pull_speed_increase
		EventBus.add_player_buff.emit(buff)
				
func get_tooltip() -> String:
	return "Boosts your pull speedby ${pull_speed_increase} after killing an enemy with your main arrow"
