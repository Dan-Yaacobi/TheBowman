class_name AdrenalineAbility extends PlayerPassiveAbility
## Health milestone. You draw faster while you're down to your last heart.

const BUFF_KEY: String = "milestone/adrenaline"

## 0.3 = +30% pull speed.
@export var pull_speed_bonus: float = 0.3

var _watcher: ConditionalStatBuff

func on_equipped() -> void:
	var player: Player = PlayerManager.player
	if is_instance_valid(_watcher):
		return
	_watcher = ConditionalStatBuff.new()
	_watcher.name = "AdrenalineWatcher"
	_watcher.stat = player.stats.pull_speed
	_watcher.buff_id = BUFF_KEY.hash()
	_watcher.amount = pull_speed_bonus
	_watcher.condition = _on_last_heart
	player.add_child(_watcher)

func on_unequipped() -> void:
	if is_instance_valid(_watcher):
		_watcher.queue_free()
	_watcher = null

func _on_last_heart() -> bool:
	var hp: int = PlayerManager.player.stats.hp
	return hp > 0 and hp <= CustomVariables.HP_PER_HEART

func get_tooltip() -> String:
	return "+%d%% pull speed while on your last heart" % roundi(pull_speed_bonus * 100.0)
