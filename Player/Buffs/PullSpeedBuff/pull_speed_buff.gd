class_name PullSpeedBuff extends Buff

var end: bool = false
@export var amount: float = 0.25

func start_buff_effect() -> void:
	apply_buff_effect()
	EventBus.in_main_menu.connect(end_buff)
	PlayerManager.player.main_hand.release.connect(end_buff)
	
func apply_buff_effect() -> void:
	PlayerManager.player.stats.pull_speed.add_buff(CustomVariables.PULL_SPEED_BUFF_ID,
	amount,Stat.buff_type.MULTIPLICATIVE)

func check_end_conditions() -> bool:
	return end

func end_buff() -> void:
	end = true

func extra_end_buff_methods() -> void:
	PlayerManager.player.stats.pull_speed.remove_buff_completly(CustomVariables.PULL_SPEED_BUFF_ID,
	Stat.buff_type.MULTIPLICATIVE)
