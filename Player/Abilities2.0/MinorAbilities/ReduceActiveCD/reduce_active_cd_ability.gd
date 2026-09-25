class_name ReduceActiveCDAbility extends MinorAbility

@export var reduction_amount: float = 0.5

func activate_ability(_target: Node2D = null , _activator: Node2D = null, _result: DamageResult = null) -> void:
	if _target and _target is Enemy and _result and _result.killed:
		EventBus.reduce_active_ability_cooldown.emit(reduction_amount)
				
func get_tooltip() -> String:
	return "Reduce Active ability cooldown by ${reduction_amount} seconds on kill"
	
func get_type() -> TriggerType:
	return TriggerType.AFTER_HIT
