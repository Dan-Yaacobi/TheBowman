class_name VenomBiteState extends EnemyState
## Wind-up, a short window where the bite can hit (strong knockback toward the edge), recovery.
## Hits don't interrupt it.

enum Phase { WINDUP, ACTIVE, RECOVERY }

@export var attack_state: EnemyState
## Seconds into the Bite animation where the jaws snap shut
@export var bite_snap_time: float = 0.3

var bloom: VenomBloom
var _phase: Phase = Phase.WINDUP
var _time_left: float = 0.0


func init() -> void:
	bloom = enemy as VenomBloom


func Enter() -> void:
	bloom.face_the_player()
	_phase = Phase.WINDUP
	_time_left = bloom.bloom_data.bite_windup
	bloom.animation_player.play(&"Bite", -1, bite_snap_time / maxf(bloom.bloom_data.bite_windup, 0.01))


func Exit() -> void:
	bloom.set_bite_active(false)
	bloom.bite_cooldown_left = bloom.bloom_data.bite_cooldown


func blocks_flinch() -> bool:
	return true


func Physics(delta: float) -> EnemyState:
	_time_left -= delta
	if _time_left > 0.0:
		return null
	match _phase:
		Phase.WINDUP:
			_phase = Phase.ACTIVE
			_time_left = bloom.bloom_data.bite_active
			bloom.set_bite_active(true)
		Phase.ACTIVE:
			_phase = Phase.RECOVERY
			_time_left = bloom.bloom_data.bite_recovery
			bloom.set_bite_active(false)
		Phase.RECOVERY:
			return attack_state
	return null
