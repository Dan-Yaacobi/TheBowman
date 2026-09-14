class_name PoisonCloudDeath extends AfterHitAbility

const SMALL_POISON_CLOUD = preload("uid://b0rkuhj5ip8qu")

func activate_ability(_target: Node2D = null , _arrow: Arrow = null, _result: DamageResult = null) -> void:
	if _target:
		if _target is Enemy:
			if _result:
				if _result.killed:
					var poison_cloud = SMALL_POISON_CLOUD.instantiate()
					poison_cloud.global_position = _target.global_position
					EventBus.summon_effect.emit(poison_cloud)
				
func get_tooltip() -> String:
	return "Summons a poison cloud when killing an enemy"
