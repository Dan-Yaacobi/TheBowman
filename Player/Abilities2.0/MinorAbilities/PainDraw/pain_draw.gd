class_name PainDrawMinor extends MinorAbility
## Taking damage gives +value% pull speed for a few seconds (refreshes on each hit).

@export var duration: float = 3.0

var _buff_id: int = -1
var _expires_at: float = 0.0

func on_equipped() -> void:
	var player: Player = PlayerManager.player
	if _buff_id < 0:
		_buff_id = CustomVariables.get_buff_id()
	if not player.took_hit.is_connected(_on_took_hit):
		player.took_hit.connect(_on_took_hit)

func on_unequipped() -> void:
	var player: Player = PlayerManager.player
	if player.took_hit.is_connected(_on_took_hit):
		player.took_hit.disconnect(_on_took_hit)
	_remove_buff()

func _on_took_hit() -> void:
	var player: Player = PlayerManager.player
	_remove_buff()
	player.stats.pull_speed.add_buff(_buff_id, value / 100.0 * power(), Stat.buff_type.MULTIPLICATIVE)
	_expires_at = Time.get_ticks_msec() / 1000.0 + duration
	player.get_tree().create_timer(duration).timeout.connect(_on_timer_done)

## Timers only guard the exit: the buff ends when its time is really up (a newer hit pushes it back).
func _on_timer_done() -> void:
	if Time.get_ticks_msec() / 1000.0 >= _expires_at - 0.01:
		_remove_buff()

func _remove_buff() -> void:
	PlayerManager.player.stats.pull_speed.remove_buff_completly(_buff_id, Stat.buff_type.MULTIPLICATIVE)

func get_tooltip() -> String:
	return "Taking damage gives +%d%% pull speed for %.0fs" % [value, duration]

func get_type() -> TriggerType:
	return TriggerType.PASSIVE

func get_tooltip_color() -> Color:
	return Color.INDIAN_RED
