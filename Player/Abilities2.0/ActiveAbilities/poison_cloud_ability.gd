class_name PoisonCloudAbility extends ActiveAbility

const POISON_CLOUD = preload("uid://b15cqm8hlwgog")

func activate(_player: Player) -> void:
	var cloud: PoisonCloud = POISON_CLOUD.instantiate()
	cloud.global_position = _player.global_position
	cloud.emitting = true
	EventBus.summon_effect.emit(cloud)
