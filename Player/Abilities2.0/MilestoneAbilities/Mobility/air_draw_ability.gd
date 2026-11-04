class_name AirDrawAbility extends PlayerPassiveAbility
## Mobility milestone. You draw faster while airborne.

const BUFF_KEY: String = "milestone/air_draw"

## 0.3 = +30% pull speed.
@export var pull_speed_bonus: float = 0.3

var _watcher: ConditionalStatBuff

func on_equipped() -> void:
	var player: Player = PlayerManager.player
	if is_instance_valid(_watcher):
		return
	_watcher = ConditionalStatBuff.new()
	_watcher.name = "AirDrawWatcher"
	_watcher.stat = player.stats.pull_speed
	_watcher.buff_id = BUFF_KEY.hash()
	_watcher.amount = pull_speed_bonus
	_watcher.condition = _is_airborne
	player.add_child(_watcher)

func on_unequipped() -> void:
	if is_instance_valid(_watcher):
		_watcher.queue_free()
	_watcher = null

func _is_airborne() -> bool:
	return not PlayerManager.player.is_on_floor()

func get_tooltip() -> String:
	return "You draw %d%% faster while airborne" % roundi(pull_speed_bonus * 100.0)
