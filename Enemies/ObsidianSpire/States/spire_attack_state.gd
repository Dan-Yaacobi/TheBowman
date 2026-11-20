class_name SpireAttackState extends EnemyState
## Awake: charges (glowing brighter) for charge_time, bursts, waits burst_cooldown, repeats.
## Falls back asleep once the player has stayed out of sleep_range for sleep_delay.

@export var sleep_state: EnemyState

var spire: ObsidianSpire
var _charging: bool = false
var _time_left: float = 0.0


func init() -> void:
	spire = enemy as ObsidianSpire


func Enter() -> void:
	if spire.animation_player:
		spire.animation_player.play(&"Idle")
	# Waking starts with a charge, so the glow is also the wake-up telegraph
	_start_charge()


func Exit() -> void:
	spire.set_glow(0.0)


func Physics(delta: float) -> EnemyState:
	var data: ObsidianSpireData = spire.spire_data
	if spire.should_sleep(delta):
		return sleep_state
	_time_left -= delta
	if _charging:
		spire.set_glow(1.0 - _time_left / maxf(data.charge_time, 0.01))
		if _time_left <= 0.0:
			spire.burst()
			spire.set_glow(0.0)
			_charging = false
			_time_left = data.burst_cooldown
	elif _time_left <= 0.0:
		_start_charge()
	return null


func _start_charge() -> void:
	_charging = true
	_time_left = spire.spire_data.charge_time
