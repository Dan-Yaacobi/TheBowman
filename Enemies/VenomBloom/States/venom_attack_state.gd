class_name VenomAttackState extends EnemyState
## Awake: sways, spits a fan of stings every spit_cooldown, bites when the player is right next to
## it, and falls back asleep once the player has stayed out of sleep_range for sleep_delay.
## Hits flinch it (Hurt) between spits, never during a spit wind-up.

@export var bite_state: EnemyState
@export var sleep_state: EnemyState
## Seconds into the Spit animation where the stings leave the mouth
@export var spit_release_time: float = 0.3

var bloom: VenomBloom
var _spit_cooldown_left: float = 0.0
var _windup_left: float = -1.0


func init() -> void:
	bloom = enemy as VenomBloom


func Enter() -> void:
	_windup_left = -1.0
	# Waking up: the first spit comes quickly; after a bite or a flinch the cooldown carries on
	if state_machine.prev_state is RootedWakeState:
		_spit_cooldown_left = bloom.bloom_data.first_spit_delay
	bloom.animation_player.play(&"Idle")


func blocks_flinch() -> bool:
	return _windup_left >= 0.0


func Physics(delta: float) -> EnemyState:
	var data: VenomBloomData = bloom.bloom_data
	if bloom.should_sleep(delta):
		return sleep_state
	if bloom.bite_cooldown_left <= 0.0 and bloom.is_player_in_bite_range():
		return bite_state
	if _windup_left >= 0.0:
		_windup_left -= delta
		if _windup_left < 0.0:
			bloom.spit()
			_spit_cooldown_left = data.spit_cooldown
		return null
	# The rest of the Spit animation plays out, then back to the idle sway
	if not bloom.animation_player.is_playing():
		bloom.animation_player.play(&"Idle")
	bloom.face_the_player()
	_spit_cooldown_left -= delta
	if _spit_cooldown_left <= 0.0 and bloom.calculate_distance_to_player() <= data.sleep_range:
		_windup_left = data.spit_windup
		bloom.animation_player.play(&"Spit", -1, spit_release_time / maxf(data.spit_windup, 0.01))
	return null
