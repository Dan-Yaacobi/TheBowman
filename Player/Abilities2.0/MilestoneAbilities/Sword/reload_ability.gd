class_name ReloadAbility extends PlayerPassiveAbility
## Sword milestone. Hitting an enemy with your sword gives a short pull speed boost.

const BUFF_KEY: String = "milestone/reload"

## 0.5 = +50% pull speed.
@export var pull_speed_bonus: float = 0.5
@export var duration: float = 1.5

var _active: bool = false
var _token: int = 0

func on_equipped() -> void:
	if not EventBus.sword_hit.is_connected(_on_sword_hit):
		EventBus.sword_hit.connect(_on_sword_hit)

func on_unequipped() -> void:
	if EventBus.sword_hit.is_connected(_on_sword_hit):
		EventBus.sword_hit.disconnect(_on_sword_hit)
	_end_boost(_token)

func _on_sword_hit(target: Node2D) -> void:
	if not target is Enemy:
		return
	var pull_speed: Stat = PlayerManager.player.stats.pull_speed
	if not _active:
		_active = true
		pull_speed.add_buff(BUFF_KEY.hash(), pull_speed_bonus, Stat.buff_type.MULTIPLICATIVE)
	# A newer hit restarts the window; the timer only ends the boost.
	_token += 1
	PlayerManager.player.get_tree().create_timer(duration, false).timeout.connect(_end_boost.bind(_token))

func _end_boost(token: int) -> void:
	if token != _token or not _active:
		return
	_active = false
	PlayerManager.player.stats.pull_speed.remove_buff_completly(BUFF_KEY.hash(), Stat.buff_type.MULTIPLICATIVE)

func get_tooltip() -> String:
	return "Sword hits give +%d%% pull speed for %.1fs" % [roundi(pull_speed_bonus * 100.0), duration]
