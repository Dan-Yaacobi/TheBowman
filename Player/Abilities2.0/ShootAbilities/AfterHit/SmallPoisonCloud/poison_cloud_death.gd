class_name PoisonCloudDeath extends AfterHitAbility

const SMALL_POISON_CLOUD = preload("uid://b0rkuhj5ip8qu")

func activate_ability(_target: Node2D = null , _activator: Node2D = null, _result: DamageResult = null) -> void:
	if _target and _target is Enemy and _result and _result.killed:
		var poison_cloud = SMALL_POISON_CLOUD.instantiate()
		poison_cloud.global_position = _target.global_position
		EventBus.summon_effect.emit(poison_cloud)
				
func get_tooltip() -> String:
	return "Summons a poison cloud when killing an enemy"
