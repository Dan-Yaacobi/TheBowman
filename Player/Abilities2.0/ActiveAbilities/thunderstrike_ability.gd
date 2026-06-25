class_name ThunderStrikeAbility extends ActiveAbility

const THUNDER_STRIKE = preload("uid://22oc6i4nljji")

func activate(_player: Player) -> void:
	var strike: ThunderStrike = THUNDER_STRIKE.instantiate()
	EventBus.summon_effect.emit(strike)
	strike.emitting = true
	strike.global_position = _player.global_position
