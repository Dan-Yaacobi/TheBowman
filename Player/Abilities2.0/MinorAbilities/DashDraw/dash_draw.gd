class_name DashDrawMinor extends MinorAbility
## Your first draw after a dash is value% faster (the same PullSpeedBuff kill boosts use: spent by the next draw).

const PULL_SPEED_BUFF_PATH: String = "res://Player/Buffs/PullSpeedBuff/PullSpeedBuff.tscn"

func on_equipped() -> void:
	if not EventBus.dash_preformed.is_connected(_on_dash):
		EventBus.dash_preformed.connect(_on_dash)

func on_unequipped() -> void:
	if EventBus.dash_preformed.is_connected(_on_dash):
		EventBus.dash_preformed.disconnect(_on_dash)

func _on_dash() -> void:
	var buff: PullSpeedBuff = load(PULL_SPEED_BUFF_PATH).instantiate()
	buff.amount = value / 100.0 * power()
	EventBus.add_player_buff.emit(buff)

func get_tooltip() -> String:
	return "Your first draw after a dash is %d%% faster" % value

func get_type() -> TriggerType:
	return TriggerType.PASSIVE

func get_tooltip_color() -> Color:
	return Color.MEDIUM_SPRING_GREEN
